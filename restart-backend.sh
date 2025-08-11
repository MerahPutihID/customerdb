#!/bin/bash

# Quick script to restart backend service
# Usage: ./restart-backend.sh

set -e

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

# Setup Node.js 20 environment for backend
setup_node_env() {
    print_status "Setting up Node.js 20 environment for backend..."
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Use Node.js 20 for backend
    nvm use 20
    
    # Verify version
    node_version=$(node --version)
    npm_version=$(npm --version)
    print_status "Using Node.js $node_version and npm $npm_version for backend"
}

# Restart backend service
restart_backend() {
    print_status "Restarting backend service..."
    
    # Setup Node.js environment
    setup_node_env
    
    # Stop existing PM2 process
    pm2 stop merahputih-backend || true
    pm2 delete merahputih-backend || true
    
    # Navigate to backend directory
    cd backend
    
    # Check if main.js exists
    if [ ! -f "/var/www/bc.merahputih-id.com/main.js" ]; then
        print_error "Backend build not found at /var/www/bc.merahputih-id.com/main.js"
        print_status "Running build process..."
        
        # Clean and build
        rm -rf dist
        
        # Try building
        if npm run build:prod; then
            print_status "Build successful"
        else
            print_error "Build failed"
            exit 1
        fi
    fi
    
    # Start PM2 process
    cd ..
    pm2 start pm2.config.json
    
    # Save PM2 configuration
    pm2 save
    
    print_status "Backend service restarted"
}

# Check service status
check_status() {
    print_status "Checking service status..."
    
    # Check PM2 status
    pm2 status
    
    # Test backend connection
    sleep 5
    print_status "Testing backend connection..."
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        print_status "✅ Backend is responding"
    else
        print_warning "⚠️ Backend health check failed"
        print_status "Checking if service is running on port 5000..."
        netstat -tlnp | grep :5000 || print_warning "No service listening on port 5000"
    fi
}

# Main function
main() {
    print_status "🔄 Restarting Backend Service..."
    
    restart_backend
    check_status
    
    print_status "✅ Backend restart completed"
}

# Run main function
main "$@"
