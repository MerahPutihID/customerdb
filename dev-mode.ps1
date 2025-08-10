# Development Mode Switcher for Git Submodule Architecture
# Usage: .\dev-mode.ps1 [local|server|prod|deploy|update|help]

param(
    [Parameter(Position=0)]
    [ValidateSet('local','server','prod','deploy','update','help')]
    [string]$Mode = 'help'
)

function Show-Help {
    Write-Host "`n=== Customer Database Project Manager ===" -ForegroundColor Green
    Write-Host "`nProject Structure:" -ForegroundColor Yellow
    Write-Host "  customerdb/              # Main project"
    Write-Host "  ├── frontend/            # Git submodule (djination/frontend-mp)"
    Write-Host "  ├── backend/             # Git submodule (bagasargita/be-nest-mp)"
    Write-Host "  ├── nginx-*.conf         # Nginx configurations"
    Write-Host "  ├── pm2.config.json      # PM2 configuration"
    Write-Host "  └── deploy-*.sh          # Deployment scripts"
    Write-Host "`nCommands:" -ForegroundColor Yellow
    Write-Host "  .\dev-mode.ps1 local     # Local development"
    Write-Host "  .\dev-mode.ps1 server    # Server development" 
    Write-Host "  .\dev-mode.ps1 prod      # Production build"
    Write-Host "  .\dev-mode.ps1 deploy    # Deploy to production"
    Write-Host "  .\dev-mode.ps1 update    # Update git submodules"
    Write-Host ""
}

function Set-LocalMode {
    Write-Host "🏠 Starting LOCAL development mode..." -ForegroundColor Green
    
    # Check if submodules exist
    if (-not (Test-Path "frontend") -or -not (Test-Path "backend")) {
        Write-Host "⚠️  Git submodules not found. Initializing..." -ForegroundColor Yellow
        git submodule update --init --recursive
    }
    
    Write-Host "📦 Installing frontend dependencies..." -ForegroundColor Yellow
    cd frontend
    npm install
    Write-Host "🚀 Starting frontend development server..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev:local"
    cd ..
    
    Write-Host "📦 Installing backend dependencies..." -ForegroundColor Yellow
    cd backend
    npm install
    Write-Host "🚀 Starting backend development server..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run start:dev"
    cd ..
    
    Write-Host "✅ Local development started!" -ForegroundColor Green
    Write-Host "🌐 Frontend: http://localhost:5173" -ForegroundColor Cyan
    Write-Host "🔗 Backend: http://localhost:5000" -ForegroundColor Cyan
}

function Set-ServerMode {
    Write-Host "🌐 Starting SERVER development mode..." -ForegroundColor Green
    
    cd frontend
    Write-Host "🚀 Starting frontend with custom domain..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev:server"
    cd ..
    
    cd backend
    Write-Host "🚀 Starting backend development server..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run start:dev"
    cd ..
    
    Write-Host "✅ Server development started!" -ForegroundColor Green
    Write-Host "🌐 Frontend: http://customer.merahputih-id.com:5173" -ForegroundColor Cyan
    Write-Host "🔗 Backend: http://localhost:5000" -ForegroundColor Cyan
}

function Set-ProdMode {
    Write-Host "🚀 Building for PRODUCTION..." -ForegroundColor Green
    
    Write-Host "📦 Building frontend..." -ForegroundColor Yellow
    cd frontend
    npm ci
    npm run build:prod
    cd ..
    
    Write-Host "📦 Building backend..." -ForegroundColor Yellow
    cd backend
    npm ci --only=production
    npm run build
    cd ..
    
    Write-Host "✅ Production build completed!" -ForegroundColor Green
    Write-Host "📦 Frontend dist: frontend/dist/" -ForegroundColor Cyan
    Write-Host "� Backend dist: backend/dist/" -ForegroundColor Cyan
    Write-Host "� Ready for deployment!" -ForegroundColor Green
}

function Start-Deployment {
    Write-Host "🚀 Starting production deployment..." -ForegroundColor Green
    
    Write-Host "`n📋 Deployment checklist:" -ForegroundColor Yellow
    Write-Host "  ✅ Git submodule architecture"
    Write-Host "  ✅ nginx + certbot (HTTPS)"
    Write-Host "  ✅ PM2 service management"
    Write-Host "  ✅ PostgreSQL database"
    Write-Host "  ✅ Automated deployment scripts"
    
    Set-ProdMode
    
    Write-Host "`n� Deployment ready!" -ForegroundColor Cyan
    Write-Host "`nNext steps on server:" -ForegroundColor Yellow
    Write-Host "  1. Upload customerdb/ folder to server"
    Write-Host "  2. Run: chmod +x *.sh"
    Write-Host "  3. Run: ./setup-server.sh (one-time setup)"
    Write-Host "  4. Run: ./deploy-frontend.sh"
    Write-Host "  5. Run: ./deploy-backend.sh"
    Write-Host "  6. Setup SSL: sudo certbot --nginx -d customer.merahputih-id.com"
    Write-Host "  7. Setup SSL: sudo certbot --nginx -d bc.merahputih-id.com"
}

function Update-Submodules {
    Write-Host "🔄 Updating git submodules..." -ForegroundColor Green
    
    Write-Host "📥 Fetching latest changes..." -ForegroundColor Yellow
    git submodule update --remote
    
    Write-Host "📋 Submodule status:" -ForegroundColor Yellow
    git submodule status
    
    Write-Host "✅ Submodules updated!" -ForegroundColor Green
    Write-Host "`n💡 Don't forget to commit the changes:" -ForegroundColor Magenta
    Write-Host "  git add ."
    Write-Host "  git commit -m 'Update submodules to latest version'"
}

# Main logic
switch ($Mode) {
    'local'  { Set-LocalMode }
    'server' { Set-ServerMode }
    'prod'   { Set-ProdMode }
    'deploy' { Start-Deployment }
    'update' { Update-Submodules }
    'help'   { Show-Help }
    default  { Show-Help }
}

if ($Mode -ne 'help' -and $Mode -ne 'deploy' -and $Mode -ne 'update') {
    Write-Host "`n🏗️ Git Submodule Architecture:" -ForegroundColor Magenta
    Write-Host "  Frontend: djination/frontend-mp (account-commision-rate)"
    Write-Host "  Backend:  bagasargita/be-nest-mp (account-commision-rate)"
    Write-Host ""
    Write-Host "� Useful commands:" -ForegroundColor Magenta
    Write-Host "  git submodule update --remote  # Update submodules"
    Write-Host "  git submodule status           # Check submodule status"
    Write-Host "  .\dev-mode.ps1 update          # Update & show status"
    Write-Host ""
}
