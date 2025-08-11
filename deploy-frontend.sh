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
    
    # Use Node.js 18 for frontend
    nvm use 18
    
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
    
    # Clear npm cache to avoid issues
    npm cache clean --force
    
    # Remove package-lock.json to avoid conflicts
    rm -f package-lock.json
    
    # Install all dependencies (skip the vite-specific install since npx works)
    print_status "Installing dependencies..."
    npm install --force
    
    # Check if vite is installed
    print_status "Checking Vite installation..."
    if [ -f "node_modules/.bin/vite" ]; then
        print_status "Vite CLI found in node_modules"
        ls -la node_modules/.bin/vite
    else
        print_warning "Vite CLI not found, installing compatible version for Node.js 18..."
        # Install Vite 5.x which supports Node.js 18
        npm install vite@^5.4.10 @vitejs/plugin-react@^4.4.1 --save-dev
    fi
    
    # Also check if current vite version is compatible
    vite_version=$(npm list vite --depth=0 2>/dev/null | grep vite | head -1 | cut -d@ -f2 || echo "")
    if [[ "$vite_version" =~ ^7\. ]] || [[ "$vite_version" =~ ^6\. ]]; then
        print_warning "Vite version $vite_version requires Node.js 20+, downgrading to compatible version..."
        npm install vite@^5.4.10 @vitejs/plugin-react@^4.4.1 --save-dev
    fi
    
    # Verify package.json and node_modules
    print_status "Verifying installation..."
    npm list vite || true
    
    # Try multiple build methods
    build_success=false
    
    # Method 1: Use npx with compatible Vite version (most reliable)
    print_status "Method 1: Using npx vite@5.4.10 (Node.js 18 compatible)"
    if npx --yes vite@5.4.10 build --mode production; then
        build_success=true
        print_status "✅ Build successful with npx!"
    else
        print_warning "Method 1 failed, trying method 2..."
    fi
    
    # Method 2: Use local Vite CLI if available
    if [ "$build_success" = false ] && [ -f "node_modules/.bin/vite" ]; then
        print_status "Method 2: Using local Vite CLI"
        if ./node_modules/.bin/vite build --mode production; then
            build_success=true
        else
            print_warning "Method 2 failed, trying method 3..."
        fi
    fi
    
    # Method 3: Use npm script
    if [ "$build_success" = false ]; then
        print_status "Method 3: Using npm run build:prod"
        if npm run build:prod; then
            build_success=true
        else
            print_warning "Method 3 failed, trying method 4..."
        fi
    fi
    
    # Method 4: Force reinstall with compatible Vite version
    if [ "$build_success" = false ]; then
        print_status "Method 4: Using minimal vite config"
        
        # Try with minimal config that doesn't require local vite imports
        if npx --yes vite@5.4.10 build --config vite.config.minimal.js --mode production; then
            build_success=true
        else
            print_warning "Method 4 failed, trying method 5..."
        fi
    fi
    
    # Method 5: Build without any config file
    if [ "$build_success" = false ]; then
        print_status "Method 5: Build without config file"
        
        # Temporarily rename the problematic config
        if [ -f "vite.config.js" ]; then
            mv vite.config.js vite.config.js.backup
        fi
        
        # Ensure index.html exists in frontend directory
        if [ ! -f "index.html" ]; then
            print_status "Creating index.html..."
            cat > index.html << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Merah Putih Frontend</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF
        fi
        
        if npx --yes vite@5.4.10 build --mode production; then
            build_success=true
        fi
        
        # Restore the config file
        if [ -f "vite.config.js.backup" ]; then
            mv vite.config.js.backup vite.config.js
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
