#!/bin/bash

# Production Deployment Script for Backend
# Usage: ./deploy-backend.sh

set -e

echo "🚀 Starting Backend Deployment..."

# Variables
PROJECT_NAME="merahputih-backend"
DOMAIN="bc.merahputih-id.com"
DEPLOY_PATH="/var/www/$DOMAIN"
NGINX_AVAILABLE="/etc/nginx/sites-available/$DOMAIN"
NGINX_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"
BACKUP_PATH="/var/backups/backend"
PM2_CONFIG="pm2.config.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Create backup
create_backup() {
    print_status "Creating backup..."
    if [ -d "$DEPLOY_PATH" ]; then
        sudo mkdir -p "$BACKUP_PATH"
        sudo cp -r "$DEPLOY_PATH" "$BACKUP_PATH/$(date +%Y%m%d_%H%M%S)"
        print_status "Backup created in $BACKUP_PATH"
    fi
}

# Build production
build_production() {
    print_status "Building backend..."
    
    # Navigate to backend submodule
    cd backend
    
    # Install dependencies
    npm ci --only=production
    
    # Build
    npm run build
    
    if [ ! -d "dist" ]; then
        print_error "Build failed - dist directory not found"
        exit 1
    fi
    
    print_status "Backend build completed"
}

# Deploy files
deploy_files() {
    print_status "Deploying backend files..."
    
    # Create deploy directory
    sudo mkdir -p "$DEPLOY_PATH"
    
    # Copy built files
    sudo cp -r dist "$DEPLOY_PATH/"
    sudo cp -r node_modules "$DEPLOY_PATH/"
    sudo cp package*.json "$DEPLOY_PATH/"
    
    # Copy uploads directory if exists
    if [ -d "uploads" ]; then
        sudo cp -r uploads "$DEPLOY_PATH/"
    fi
    
    # Set permissions
    sudo chown -R $USER:$USER "$DEPLOY_PATH"
    sudo chmod -R 755 "$DEPLOY_PATH"
    
    print_status "Backend files deployed to $DEPLOY_PATH"
}

# Setup PM2
setup_pm2() {
    print_status "Setting up PM2..."
    
    # Copy PM2 configuration from root
    if [ -f "../pm2.config.json" ]; then
        cp "../pm2.config.json" "$DEPLOY_PATH/"
        
        # Stop existing PM2 processes
        pm2 stop $PROJECT_NAME || true
        pm2 delete $PROJECT_NAME || true
        
        # Start with new configuration
        cd "$DEPLOY_PATH"
        pm2 start pm2.config.json
        
        # Save PM2 configuration
        pm2 save
        
        # Setup PM2 startup
        pm2 startup || true
        
        print_status "PM2 setup completed"
    else
        print_error "PM2 configuration file not found"
        exit 1
    fi
}

# Setup nginx
setup_nginx() {
    print_status "Setting up Nginx for backend..."
    
    # Copy nginx configuration from root
    if [ -f "../nginx-backend.conf" ]; then
        sudo cp "../nginx-backend.conf" "$NGINX_AVAILABLE"
        
        # Enable site
        if [ ! -L "$NGINX_ENABLED" ]; then
            sudo ln -s "$NGINX_AVAILABLE" "$NGINX_ENABLED"
        fi
        
        # Test nginx configuration
        sudo nginx -t
        
        if [ $? -eq 0 ]; then
            print_status "Nginx configuration is valid"
        else
            print_error "Nginx configuration test failed"
            exit 1
        fi
    else
        print_warning "nginx-backend.conf not found, skipping nginx setup"
    fi
}

# Setup database
setup_database() {
    print_status "Running database migrations..."
    
    cd "$DEPLOY_PATH"
    
    # Run migrations if exists
    if [ -f "package.json" ] && grep -q "typeorm:migration:run" package.json; then
        npm run typeorm:migration:run || print_warning "Migration failed or no migrations to run"
    fi
}

# Restart services
restart_services() {
    print_status "Restarting services..."
    
    # Restart PM2 processes
    pm2 restart $PROJECT_NAME
    print_status "PM2 processes restarted"
    
    # Reload nginx
    sudo systemctl reload nginx
    print_status "Nginx reloaded"
}

# Setup SSL if not exists
setup_ssl() {
    print_status "Checking SSL certificate..."
    
    if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        print_warning "SSL certificate not found"
        print_status "Run: sudo certbot --nginx -d $DOMAIN"
    else
        print_status "SSL certificate exists"
    fi
}

# Main deployment process
main() {
    print_status "Starting backend deployment for $DOMAIN"
    
    create_backup
    build_production
    deploy_files
    setup_pm2
    setup_nginx
    setup_database
    restart_services
    setup_ssl
    
    print_status "🎉 Backend deployment completed successfully!"
    print_status "Backend API available at: https://$DOMAIN"
    
    # Show status
    echo ""
    print_status "Service Status:"
    pm2 status
    sudo systemctl status nginx --no-pager -l
}

# Run main function
main "$@"
