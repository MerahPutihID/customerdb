# 🚀 Production Deployment Guide

## 📋 Overview

Production stack menggunakan:
- **Frontend**: nginx + certbot (HTTPS) + static files
- **Backend**: PM2 + nginx reverse proxy (HTTPS) + NestJS
- **Database**: PostgreSQL
- **SSL**: Let's Encrypt via certbot

## 🏗️ Architecture

```
Internet
    ↓
Nginx (Port 80/443)
    ↓
┌─────────────────┬─────────────────┐
│   Frontend      │    Backend      │
│ customer.       │ bc.             │
│ merahputih-     │ merahputih-     │
│ id.com          │ id.com          │
│                 │                 │
│ Static Files    │ PM2 → NestJS    │
│ (React/Vite)    │ (Port 5000)     │
└─────────────────┴─────────────────┘
                       ↓
                  PostgreSQL
                  (Port 5432)
```

## 🛠️ Server Setup

### 1. Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 globally
sudo npm install -g pm2

# Install nginx
sudo apt install nginx -y

# Install certbot
sudo apt install certbot python3-certbot-nginx -y

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib -y
```

### 2. Setup Domains

```bash
# Setup DNS Records (di domain provider)
# A record: customer.merahputih-id.com → Server IP
# A record: bc.merahputih-id.com → Server IP
```

### 3. Setup SSL Certificates

```bash
# Frontend SSL
sudo certbot --nginx -d customer.merahputih-id.com

# Backend SSL  
sudo certbot --nginx -d bc.merahputih-id.com

# Auto-renewal test
sudo certbot renew --dry-run
```

## 📦 Deployment Process

### Option 1: Automated Deployment

```bash
# Deploy frontend
npm run deploy:frontend

# Deploy backend
npm run deploy:backend
```

### Option 2: Manual Deployment

#### Frontend Deployment

```bash
# 1. Build production
npm run build:prod

# 2. Copy nginx config
sudo cp nginx-frontend.conf /etc/nginx/sites-available/customer.merahputih-id.com
sudo ln -s /etc/nginx/sites-available/customer.merahputih-id.com /etc/nginx/sites-enabled/

# 3. Deploy files
sudo mkdir -p /var/www/customer.merahputih-id.com
sudo cp -r dist/* /var/www/customer.merahputih-id.com/
sudo chown -R www-data:www-data /var/www/customer.merahputih-id.com

# 4. Test and reload nginx
sudo nginx -t
sudo systemctl reload nginx
```

#### Backend Deployment

```bash
# 1. Build backend
cd ../be-nest-mp
npm ci --only=production
npm run build

# 2. Deploy files
sudo mkdir -p /var/www/bc.merahputih-id.com
sudo cp -r dist node_modules package*.json /var/www/bc.merahputih-id.com/
sudo chown -R $USER:$USER /var/www/bc.merahputih-id.com

# 3. Setup PM2
cd /var/www/bc.merahputih-id.com
pm2 start pm2.config.json
pm2 save
pm2 startup

# 4. Setup nginx for backend
sudo cp nginx-backend.conf /etc/nginx/sites-available/bc.merahputih-id.com
sudo ln -s /etc/nginx/sites-available/bc.merahputih-id.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## ⚙️ Configuration Files

### Environment Variables (.env.production)

```env
VITE_ENV=production
NODE_ENV=production
VITE_BASE_URL=https://bc.merahputih-id.com
VITE_API_BASE_URL=https://bc.merahputih-id.com
VITE_DEBUG=false
VITE_DISABLE_HMR=true
GENERATE_SOURCEMAP=false
```

### PM2 Configuration (pm2.config.json)

```json
{
  "apps": [{
    "name": "merahputih-backend",
    "script": "dist/main.js",
    "instances": 1,
    "exec_mode": "cluster",
    "env": {
      "NODE_ENV": "production",
      "PORT": 5000
    }
  }]
}
```

## 🔧 Service Management

### PM2 Commands

```bash
# Check status
pm2 status

# View logs
pm2 logs merahputih-backend

# Restart
pm2 restart merahputih-backend

# Monitor
pm2 monit

# Stop
pm2 stop merahputih-backend

# Delete
pm2 delete merahputih-backend
```

### Nginx Commands

```bash
# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Restart nginx
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx

# View logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 📊 Monitoring & Logs

### Log Locations

```bash
# PM2 logs
/var/log/pm2/merahputih-backend-error.log
/var/log/pm2/merahputih-backend-out.log

# Nginx logs
/var/log/nginx/customer.merahputih-id.com.access.log
/var/log/nginx/customer.merahputih-id.com.error.log
/var/log/nginx/bc.merahputih-id.com.access.log
/var/log/nginx/bc.merahputih-id.com.error.log
```

### Health Checks

```bash
# Frontend health
curl -I https://customer.merahputih-id.com

# Backend health
curl -I https://bc.merahputih-id.com/health

# SSL certificate status
sudo certbot certificates
```

## 🔧 Troubleshooting

### Common Issues

1. **Port conflicts**: Pastikan port 5000 tidak digunakan aplikasi lain
2. **File permissions**: Pastikan ownership correct untuk nginx dan PM2
3. **SSL issues**: Check certificate expiry dan renewal
4. **Database connection**: Verify PostgreSQL running dan credentials correct

### Debug Commands

```bash
# Check ports
sudo netstat -tlnp | grep :5000
sudo netstat -tlnp | grep :443

# Check processes
ps aux | grep node
ps aux | grep nginx

# Check disk space
df -h

# Check memory usage
free -h
```

## 🚀 Performance Optimization

### Frontend Optimizations

- ✅ Code splitting dengan manual chunks
- ✅ Asset compression (gzip)
- ✅ Browser caching headers
- ✅ Minification & tree shaking
- ✅ Remove console.log dalam production

### Backend Optimizations

- ✅ PM2 cluster mode
- ✅ Nginx load balancing
- ✅ Database connection pooling
- ✅ Request/response compression
- ✅ Static file serving via nginx

## 📞 Support

Untuk issues deployment, check:
1. Service logs (`pm2 logs`, `nginx logs`)
2. System resources (`htop`, `df -h`)
3. Network connectivity (`curl`, `ping`)
4. Certificate status (`certbot certificates`)

## 🔄 Update Process

```bash
# 1. Pull latest code
git pull origin main

# 2. Deploy frontend
npm run deploy:frontend

# 3. Deploy backend  
npm run deploy:backend

# 4. Verify deployment
curl -I https://customer.merahputih-id.com
curl -I https://bc.merahputih-id.com/health
```
