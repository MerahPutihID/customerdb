#!/bin/bash

# Quick Server Setup Script
# Usage: ./setup-server.sh

set -e

echo "🚀 Setting up production server..."

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
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Update system
update_system() {
    print_status "Updating system..."
    apt update && apt upgrade -y
}

# Install Node.js
install_nodejs() {
    print_status "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    # Verify installation
    node_version=$(node --version)
    npm_version=$(npm --version)
    print_status "Node.js $node_version and npm $npm_version installed"
}

# Install PM2
install_pm2() {
    print_status "Installing PM2..."
    npm install -g pm2
    
    # Setup PM2 logrotate
    pm2 install pm2-logrotate
    
    print_status "PM2 installed successfully"
}

# Install and configure nginx
install_nginx() {
    print_status "Installing nginx..."
    apt install nginx -y
    
    # Start and enable nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Create log directories
    mkdir -p /var/log/nginx
    
    print_status "Nginx installed and started"
}

# Install certbot
install_certbot() {
    print_status "Installing certbot..."
    apt install certbot python3-certbot-nginx -y
    
    print_status "Certbot installed"
}

# Install PostgreSQL
install_postgresql() {
    print_status "Installing PostgreSQL..."
    apt install postgresql postgresql-contrib -y
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    print_status "PostgreSQL installed and started"
    print_warning "Don't forget to setup database user and database"
    print_warning "Run: sudo -u postgres createuser --interactive"
    print_warning "Run: sudo -u postgres createdb merahputih_db"
}

# Setup firewall
setup_firewall() {
    print_status "Setting up UFW firewall..."
    
    # Install UFW if not installed
    apt install ufw -y
    
    # Reset UFW to defaults
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 'Nginx Full'
    
    # Allow PostgreSQL (from localhost only)
    ufw allow from 127.0.0.1 to any port 5432
    
    # Enable firewall
    ufw --force enable
    
    print_status "Firewall configured"
}

# Setup directories
setup_directories() {
    print_status "Setting up directories..."
    
    # Create web directories
    mkdir -p /var/www/customer.merahputih-id.com
    mkdir -p /var/www/bc.merahputih-id.com
    
    # Create backup directories
    mkdir -p /var/backups/frontend
    mkdir -p /var/backups/backend
    
    # Create PM2 log directory
    mkdir -p /var/log/pm2
    
    # Set permissions
    chown -R www-data:www-data /var/www
    chmod -R 755 /var/www
    
    print_status "Directories created"
}

# Setup swap file (if not exists)
setup_swap() {
    if [ ! -f /swapfile ]; then
        print_status "Setting up swap file..."
        
        # Create 2GB swap file
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        
        # Make permanent
        echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
        
        print_status "Swap file created (2GB)"
    else
        print_status "Swap file already exists"
    fi
}

# Setup SSL auto-renewal
setup_ssl_renewal() {
    print_status "Setting up SSL auto-renewal..."
    
    # Add cron job for renewal
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    print_status "SSL auto-renewal configured"
}

# Install additional tools
install_tools() {
    print_status "Installing additional tools..."
    
    # Install common tools
    apt install -y \
        htop \
        curl \
        wget \
        git \
        unzip \
        tree \
        nano \
        fail2ban
    
    # Configure fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    print_status "Additional tools installed"
}

# Main setup function
main() {
    print_status "Starting server setup..."
    
    update_system
    install_nodejs
    install_pm2
    install_nginx
    install_certbot
    install_postgresql
    setup_firewall
    setup_directories
    setup_swap
    setup_ssl_renewal
    install_tools
    
    print_status "🎉 Server setup completed!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Setup DNS records for your domains"
    print_status "2. Configure PostgreSQL database"
    print_status "3. Deploy your applications"
    print_status "4. Setup SSL certificates"
    print_status ""
    print_status "Commands to run:"
    print_status "sudo -u postgres createuser --interactive"
    print_status "sudo -u postgres createdb merahputih_db"
    print_status "sudo certbot --nginx -d customer.merahputih-id.com"
    print_status "sudo certbot --nginx -d bc.merahputih-id.com"
    
    # Show service status
    echo ""
    print_status "Service Status:"
    systemctl status nginx --no-pager -l
    systemctl status postgresql --no-pager -l
    
    # Show firewall status
    echo ""
    print_status "Firewall Status:"
    ufw status
}

# Run main function
main "$@"
