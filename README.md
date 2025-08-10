# Customer Database Project

## 📁 Project Structure

```
customerdb/
├── frontend/           # Git submodule: djination/frontend-mp (account-commision-rate)
├── backend/            # Git submodule: bagasargita/be-nest-mp (account-commision-rate)
├── nginx-frontend.conf # Nginx configuration for frontend
├── nginx-backend.conf  # Nginx configuration for backend
├── pm2.config.json     # PM2 process management
├── deploy-frontend.sh  # Frontend deployment script
├── deploy-backend.sh   # Backend deployment script
├── setup-server.sh     # Server setup script
├── dev-mode.ps1        # Windows development helper
└── docs/               # Documentation
```

## 🚀 Quick Start

### 1. Clone with Submodules

```bash
git clone --recurse-submodules <your-customerdb-repo>
cd customerdb

# Or if already cloned:
git submodule update --init --recursive
```

### 2. Development Setup

#### Frontend Development:
```bash
cd frontend
npm install
npm run dev:local       # http://localhost:5173
```

#### Backend Development:
```bash
cd backend
npm install
npm run start:dev       # http://localhost:5000
```

### 3. Production Deployment

#### One-time Server Setup:
```bash
# Upload to server and run:
chmod +x setup-server.sh
sudo ./setup-server.sh
```

#### Deploy Applications:
```bash
# Deploy frontend
chmod +x deploy-frontend.sh
./deploy-frontend.sh

# Deploy backend
chmod +x deploy-backend.sh
./deploy-backend.sh
```

## 🔧 Git Submodule Management

### Update Submodules:
```bash
# Update to latest commits
git submodule update --remote

# Update specific submodule
git submodule update --remote frontend
git submodule update --remote backend
```

### Commit Submodule Changes:
```bash
# After updating submodules
git add .
git commit -m "Update submodules to latest version"
```

### Working with Submodule Branches:
```bash
# Switch to different branch in submodule
cd frontend
git checkout different-branch
cd ..
git add frontend
git commit -m "Switch frontend to different-branch"
```

## 🏗️ Production Architecture

```
Internet (HTTPS)
    ↓
nginx (Port 443) + certbot SSL
    ↓
┌─────────────────────┬─────────────────────┐
│     Frontend        │      Backend        │
│ customer.merahputih │ bc.merahputih       │
│ -id.com             │ -id.com             │
│                     │                     │
│ Static Files        │ PM2 → NestJS:5000   │
│ (nginx serve)       │ (cluster mode)      │
└─────────────────────┴─────────────────────┘
                           ↓
                      PostgreSQL:5432
```

## 📋 Environment Configuration

### Frontend Environments:
- **Local**: http://localhost:5173 → http://localhost:5000
- **Server**: http://customer.merahputih-id.com:5173 → http://localhost:5000
- **Production**: https://customer.merahputih-id.com → https://bc.merahputih-id.com

### Backend Environments:
- **Development**: http://localhost:5000
- **Production**: https://bc.merahputih-id.com (via nginx + PM2)

## 🔗 Repository Links

- **Frontend**: https://github.com/djination/frontend-mp.git (branch: account-commision-rate)
- **Backend**: https://github.com/bagasargita/be-nest-mp.git (branch: account-commision-rate)

## 📚 Documentation

- `PRODUCTION_DEPLOYMENT.md` - Complete deployment guide
- `PRODUCTION_READY.md` - Production setup summary
- `frontend/DEV_GUIDE.md` - Frontend development guide
- `backend/README.md` - Backend setup guide

## 🛠️ Development Tools

### Windows Development:
```powershell
# Quick development mode switcher
.\dev-mode.ps1 local    # Local development
.\dev-mode.ps1 server   # Server development
.\dev-mode.ps1 prod     # Production build
.\dev-mode.ps1 deploy   # Deploy to production
```

### Common Commands:
```bash
# Update both frontend and backend
git submodule foreach git pull origin account-commision-rate

# Check submodule status
git submodule status

# Reset submodules to committed versions
git submodule update --init --recursive
```

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `nginx-frontend.conf` | Frontend nginx configuration (static files + SSL) |
| `nginx-backend.conf` | Backend nginx configuration (reverse proxy + SSL) |
| `pm2.config.json` | PM2 process management for backend |
| `deploy-frontend.sh` | Automated frontend deployment |
| `deploy-backend.sh` | Automated backend deployment |
| `setup-server.sh` | Initial server setup (nginx + PM2 + SSL) |
| `dev-mode.ps1` | Windows development helper |

## 🚀 Production Ready Features

- ✅ Git submodule architecture
- ✅ HTTPS with certbot auto-renewal
- ✅ nginx reverse proxy & static serving
- ✅ PM2 cluster mode & monitoring
- ✅ Automated deployment scripts
- ✅ Security headers & compression
- ✅ Log rotation & health checks
- ✅ Cross-platform development tools

## 📞 Support

For deployment issues:
1. Check service logs: `pm2 logs`, `sudo journalctl -u nginx`
2. Verify submodules: `git submodule status`
3. Test configurations: `sudo nginx -t`
4. Check SSL: `sudo certbot certificates`

## 🔄 Update Workflow

1. Update submodules: `git submodule update --remote`
2. Test locally: `cd frontend && npm run dev:local`
3. Build production: `./deploy-frontend.sh && ./deploy-backend.sh`
4. Commit changes: `git add . && git commit -m "Update deployment"`
