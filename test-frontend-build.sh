#!/bin/bash

# Quick frontend build test
# Usage: ./test-frontend-build.sh

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

main() {
    print_status "🧪 Testing Frontend Build..."
    
    # Setup environment
    setup_node_env
    
    # Navigate to frontend
    cd frontend
    
    print_status "Current directory: $(pwd)"
    print_status "Node version: $(node --version)"
    print_status "NPM version: $(npm --version)"
    
    # Clean and install
    print_status "Cleaning previous installation..."
    rm -rf node_modules package-lock.json dist
    
    print_status "Installing compatible Vite version..."
    npm install vite@^5.4.10 @vitejs/plugin-react@^4.4.1 --save-dev
    
    print_status "Installing other dependencies..."
    npm install
    
    print_status "Checking Vite version..."
    
    # Check multiple ways to verify Vite installation
    print_status "Method 1: npm list vite --depth=0"
    npm list vite --depth=0 || true
    
    print_status "Method 2: Check package.json"
    if grep -q '"vite"' package.json; then
        vite_in_package=$(grep '"vite"' package.json)
        print_status "Vite in package.json: $vite_in_package"
    else
        print_warning "Vite not found in package.json"
    fi
    
    print_status "Method 3: Check node_modules directory"
    if [ -d "node_modules/vite" ]; then
        print_status "✅ Vite directory exists in node_modules"
        vite_package_version=$(cat node_modules/vite/package.json | grep '"version"' | cut -d'"' -f4)
        print_status "Installed Vite version: $vite_package_version"
    else
        print_error "❌ Vite directory not found in node_modules"
    fi
    
    print_status "Checking if Vite CLI exists..."
    if [ -f "node_modules/.bin/vite" ]; then
        print_status "✅ Vite CLI found at: $(ls -la node_modules/.bin/vite)"
    else
        print_error "❌ Vite CLI not found in node_modules/.bin/"
        print_status "Listing node_modules/.bin/ contents:"
        ls -la node_modules/.bin/ | head -10
        
        print_status "Trying to reinstall Vite explicitly..."
        npm install --force vite@5.4.10 @vitejs/plugin-react@4.4.1
        
        print_status "Checking again..."
        if [ -f "node_modules/.bin/vite" ]; then
            print_status "✅ Vite CLI found after reinstall"
        else
            print_error "❌ Still no Vite CLI found"
            exit 1
        fi
    fi
    
    print_status "Attempting build..."
    
    # Since local Vite installation seems to have issues, use npx approach
    build_success=false
    
    # Method 1: Try npx with compatible version for Node.js 18
    print_status "Method 1: Using npx vite@5.4.10"
    if npx --yes vite@5.4.10 build --mode production; then
        build_success=true
        print_status "✅ Build successful with npx vite@5.4.10!"
    else
        print_warning "Method 1 failed, trying method 2..."
    fi
    
    # Method 2: Try npm script (if package.json has the right vite version)
    if [ "$build_success" = false ]; then
        print_status "Method 2: Using npm run build:prod"
        if npm run build:prod 2>/dev/null; then
            build_success=true
            print_status "✅ Build successful with npm run build:prod!"
        else
            print_warning "Method 2 failed, trying method 3..."
        fi
    fi
    
    # Method 3: Force install and try local CLI
    if [ "$build_success" = false ]; then
        print_status "Method 3: Force install specific Vite version"
        npm install --force --no-save vite@5.4.10 @vitejs/plugin-react@4.4.1
        
        if [ -f "node_modules/.bin/vite" ]; then
            if ./node_modules/.bin/vite build --mode production; then
                build_success=true
                print_status "✅ Build successful with local Vite CLI!"
            fi
        fi
    fi
    
    if [ "$build_success" = true ]; then
        if [ -d "dist" ]; then
            print_status "✅ Dist directory created"
            ls -la dist/
        else
            print_error "❌ Build reported success but dist directory not found"
            exit 1
        fi
    else
        print_error "❌ All build methods failed"
        exit 1
    fi
}

main "$@"
