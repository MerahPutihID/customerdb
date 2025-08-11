#!/bin/bash

# Simple build script that bypasses vite.config.js issues
# Usage: ./simple-build.sh

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

# Setup Node.js environment
setup_node_env() {
    print_status "Setting up Node.js 18 environment..."
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Use Node.js 18
    nvm use 18
    
    print_status "Using Node.js $(node --version) and npm $(npm --version)"
}

main() {
    print_status "🔧 Simple Frontend Build (bypassing config issues)..."
    
    setup_node_env
    cd frontend
    
    print_status "Current directory: $(pwd)"
    
    # Clean previous build
    rm -rf dist
    
    # Create a temporary simplified vite config
    print_status "Creating temporary simplified vite config..."
    cat > vite.config.temp.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    minify: 'esbuild',
  },
  define: {
    __DEV__: false,
    __PROD__: true,
    __LOCAL__: false,
  },
})
EOF
    
    # Try build with simplified config
    print_status "Attempting build with simplified config..."
    
    build_success=false
    
    # Method 1: Use npx with simplified config
    if npx --yes vite@5.4.10 build --config vite.config.temp.js --mode production; then
        build_success=true
        print_status "✅ Build successful with simplified config!"
    else
        print_warning "Simplified config failed, trying without config file..."
        
        # Method 2: Build without any config file
        print_status "Creating basic index.html for build..."
        if [ ! -f "index.html" ]; then
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
            print_status "✅ Build successful without config!"
        fi
    fi
    
    # Clean up temp config
    rm -f vite.config.temp.js
    
    if [ "$build_success" = true ]; then
        if [ -d "dist" ]; then
            print_status "✅ Build completed successfully!"
            print_status "📁 Dist directory contents:"
            ls -la dist/
            
            # Check for essential files
            if [ -f "dist/index.html" ]; then
                print_status "✅ index.html found"
            fi
            
            if [ -d "dist/assets" ]; then
                print_status "✅ Assets directory found"
                asset_count=$(ls dist/assets/ | wc -l)
                print_status "📦 Assets count: $asset_count files"
            fi
        else
            print_error "❌ Build succeeded but no dist directory found"
            exit 1
        fi
    else
        print_error "❌ All build methods failed"
        exit 1
    fi
    
    print_status "🎉 Simple build completed!"
}

main "$@"
