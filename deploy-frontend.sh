#!/bin/bash

# Production Deployment Script for Frontend
# Usage: ./deploy-frontend.sh

set -e

echo "🚀 Starting Frontend Deployment..."

# Variables
PROJECT_NAME="merahputih-frontend"
DOMAIN="customer.merahputih-id.com"
DEPLOY_PATH="/var/www/$DOMAIN"
NGINX_AVAILABLE="/etc/nginx/sites-available/$DOMAIN"
NGINX_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"
BACKUP_PATH="/var/backups/frontend"

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
    print_status "Building frontend..."
    
    # Navigate to frontend submodule
    cd frontend
    
    # Install dependencies
    npm ci
    
    # Build production
    npm run build:prod
    
    if [ ! -d "dist" ]; then
        print_error "Build failed - dist directory not found"
        exit 1
    fi
    
    print_status "Frontend build completed"
}

# Deploy files
deploy_files() {
    print_status "Deploying files..."
    
    # Create deploy directory
    sudo mkdir -p "$DEPLOY_PATH"
    
    # Copy built files from frontend submodule
    sudo cp -r frontend/dist/* "$DEPLOY_PATH/"
    
    # Set permissions
    sudo chown -R www-data:www-data "$DEPLOY_PATH"
    sudo chmod -R 755 "$DEPLOY_PATH"
    
    print_status "Files deployed to $DEPLOY_PATH"
}

# Setup nginx
setup_nginx() {
    print_status "Setting up Nginx..."
    
    # Copy nginx configuration
    if [ -f "nginx-frontend.conf" ]; then
        sudo cp nginx-frontend.conf "$NGINX_AVAILABLE"
        
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
        print_warning "nginx-frontend.conf not found, skipping nginx setup"
    fi
}

# Restart services
restart_services() {
    print_status "Restarting services..."
    
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
    print_status "Starting deployment for $DOMAIN"
    
    create_backup
    build_production
    deploy_files
    setup_nginx
    restart_services
    setup_ssl
    
    print_status "🎉 Frontend deployment completed successfully!"
    print_status "Frontend available at: https://$DOMAIN"
    
    # Show status
    echo ""
    print_status "Service Status:"
    sudo systemctl status nginx --no-pager -l
}

# Run main function
main "$@"
