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

# Fix permissions
fix_permissions() {
    print_status "Fixing permissions..."
    
    # Change ownership of the customerdb directory to current user
    sudo chown -R $USER:$USER /var/www/customerdb
    
    # Set appropriate permissions
    sudo chmod -R 755 /var/www/customerdb
    
    print_status "Permissions fixed"
}

# Setup Node.js environment for frontend
setup_node_env() {
    print_status "Setting up Node.js 18 environment for frontend..."
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Use Node.js 20 for frontend
    nvm use 20
    
    # Verify version
    node_version=$(node --version)
    npm_version=$(npm --version)
    print_status "Using Node.js $node_version and npm $npm_version for frontend"
}

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
    
    # Setup Node.js 18 environment
    setup_node_env
    
    # Navigate to frontend submodule
    cd frontend
    
    # Clean previous build
    rm -rf node_modules dist
    
    # Install dependencies with debugging
    print_status "Installing dependencies..."
    npm ci --verbose
    
    # Check if vite is installed
    print_status "Checking Vite installation..."
    if [ -f "node_modules/.bin/vite" ]; then
        print_status "Vite CLI found in node_modules"
        ls -la node_modules/.bin/vite
    else
        print_warning "Vite CLI not found, installing manually..."
        npm install vite@latest --save-dev
    fi
    
    # Verify package.json and node_modules
    print_status "Verifying installation..."
    npm list vite || true
    
    # Try multiple build methods
    build_success=false
    
    # Method 1: Use local Vite CLI
    if [ -f "node_modules/.bin/vite" ]; then
        print_status "Method 1: Using local Vite CLI"
        if ./node_modules/.bin/vite build --mode production; then
            build_success=true
        else
            print_warning "Method 1 failed, trying method 2..."
        fi
    fi
    
    # Method 2: Use npm script
    if [ "$build_success" = false ]; then
        print_status "Method 2: Using npm run build:prod"
        if npm run build:prod; then
            build_success=true
        else
            print_warning "Method 2 failed, trying method 3..."
        fi
    fi
    
    # Method 3: Use npx with explicit version
    if [ "$build_success" = false ]; then
        print_status "Method 3: Using npx with explicit Vite"
        if npx --yes vite@latest build --mode production; then
            build_success=true
        else
            print_warning "Method 3 failed, trying method 4..."
        fi
    fi
    
    # Method 4: Reinstall and try again
    if [ "$build_success" = false ]; then
        print_status "Method 4: Clean reinstall and build"
        rm -rf node_modules package-lock.json
        npm install
        if npm run build:prod; then
            build_success=true
        fi
    fi
    
    # Check if build succeeded
    if [ "$build_success" = false ] || [ ! -d "dist" ]; then
        print_error "All build methods failed - dist directory not found"
        print_status "Debugging information:"
        echo "Current directory: $(pwd)"
        echo "Node version: $(node --version)"
        echo "NPM version: $(npm --version)"
        echo "Package.json exists: $([ -f package.json ] && echo 'Yes' || echo 'No')"
        echo "Vite in devDependencies:"
        cat package.json | grep -A 5 -B 5 '"vite"'
        exit 1
    fi
    
    print_status "Frontend build completed successfully"
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
    
    fix_permissions
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
