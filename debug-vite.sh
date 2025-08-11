#!/bin/bash

# Simple debug script to understand npm/vite installation
# Usage: ./debug-vite.sh

cd frontend

echo "=== Environment ==="
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"
echo "Current directory: $(pwd)"

echo "=== Package.json check ==="
if [ -f "package.json" ]; then
    echo "✅ package.json exists"
    echo "Vite in dependencies:"
    grep -A 2 -B 2 '"vite"' package.json || echo "Not found in grep"
else
    echo "❌ package.json not found"
fi

echo "=== Clean installation ==="
rm -rf node_modules package-lock.json

echo "=== Install specific Vite version ==="
npm install vite@5.4.10

echo "=== Check installation result ==="
echo "Node modules exists: $([ -d node_modules ] && echo 'Yes' || echo 'No')"
echo "Vite directory exists: $([ -d node_modules/vite ] && echo 'Yes' || echo 'No')"

if [ -d "node_modules/vite" ]; then
    echo "Vite version from package.json:"
    cat node_modules/vite/package.json | grep '"version"' | head -1
fi

echo "Vite CLI exists: $([ -f node_modules/.bin/vite ] && echo 'Yes' || echo 'No')"

if [ -f "node_modules/.bin/vite" ]; then
    echo "Vite CLI details:"
    ls -la node_modules/.bin/vite
    echo "Vite CLI version:"
    ./node_modules/.bin/vite --version || echo "Failed to get version"
fi

echo "=== NPM list commands ==="
echo "npm list vite:"
npm list vite || echo "npm list failed"

echo "npm list vite --depth=0:"
npm list vite --depth=0 || echo "npm list --depth=0 failed"

echo "=== Direct test ==="
echo "Testing direct vite execution:"
npx vite --version || echo "npx vite failed"

echo "=== Summary ==="
echo "Can we build? Testing vite build:"
npx vite build --help || echo "Build help failed"
