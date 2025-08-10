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
# install_nodejs() {
#     print_status "Installing Node.js 20 LTS..."
    
#     # Remove old Node.js if exists
#     apt remove -y nodejs npm || true
    
#     # Install Node.js 20 LTS
#     curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
#     apt-get install -y nodejs
    
#     # Verify installation
#     node_version=$(node --version)
#     npm_version=$(npm --version)
#     print_status "Node.js $node_version and npm $npm_version installed"
    
#     # Set npm to use global directory for current user
#     mkdir -p ~/.npm-global
#     npm config set prefix '~/.npm-global'
    
#     print_status "Node.js configuration completed"
# }

# Install PM2
# install_pm2() {
#     print_status "Installing PM2..."
#     npm install -g pm2
    
#     # Setup PM2 logrotate
#     pm2 install pm2-logrotate
    
#     print_status "PM2 installed successfully"
# }

# Install and configure nginx
# install_nginx() {
#     print_status "Installing nginx..."
#     apt install nginx -y
    
#     # Start and enable nginx
#     systemctl start nginx
#     systemctl enable nginx
    
#     # Create log directories
#     mkdir -p /var/log/nginx
    
#     print_status "Nginx installed and started"
# }

# # Install certbot
# install_certbot() {
#     print_status "Installing certbot..."
#     apt install certbot python3-certbot-nginx -y
    
#     print_status "Certbot installed"
# }

# Install PostgreSQL
# install_postgresql() {
#     print_status "Installing PostgreSQL 15..."
    
#     # Install PostgreSQL 15
#     apt install postgresql-15 postgresql-contrib-15 -y
    
#     # Start and enable PostgreSQL
#     systemctl start postgresql
#     systemctl enable postgresql
    
#     # Configure PostgreSQL
#     sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
    
#     # Create application database and user
#     sudo -u postgres createdb custmp_db
#     sudo -u postgres psql -c "CREATE USER custmp_user WITH PASSWORD 'custmp_password';"
#     sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE custmp_db TO custmp_user;"
    
#     print_status "PostgreSQL installed and configured"
#     print_warning "Database: custmp_db"
#     print_warning "User: custmp_user"
#     print_warning "Password: custmp_password"
#     print_warning "Please change the password in production!"
# }

# Setup firewall
# setup_firewall() {
#     print_status "Setting up UFW firewall..."
    
#     # Install UFW if not installed
#     apt install ufw -y
    
#     # Reset UFW to defaults
#     ufw --force reset
    
#     # Set default policies
#     ufw default deny incoming
#     ufw default allow outgoing
    
#     # Allow SSH
#     ufw allow ssh
    
#     # Allow HTTP and HTTPS
#     ufw allow 'Nginx Full'
    
#     # Allow PostgreSQL (from localhost only)
#     ufw allow from 127.0.0.1 to any port 5432
    
#     # Enable firewall
#     ufw --force enable
    
#     print_status "Firewall configured"
# }

# Setup directories
setup_directories() {
    print_status "Setting up directories..."
    
    # Create web directories
    mkdir -p /var/www/customer.merahputih-id.com
    mkdir -p /var/www/bc.merahputih-id.com
    
    # Create customerdb project directory
    mkdir -p /var/www/customerdb
    
    # Create backup directories
    # mkdir -p /var/backups/frontend
    # mkdir -p /var/backups/backend
    mkdir -p /var/backups/customerdb
    
    # Create PM2 log directory
    mkdir -p /var/log/pm2
    
    # Create uploads directory for backend
    mkdir -p /var/www/bc.merahputih-id.com/uploads
    mkdir -p /var/www/bc.merahputih-id.com/uploads/documents
    
    # Set permissions
    chown -R www-data:www-data /var/www
    chmod -R 755 /var/www
    
    # Create symlinks for easy access
    ln -sf /var/www/customerdb /home/customerdb 2>/dev/null || true
    
    print_status "Directories created"
    print_status "Project directory: /var/www/customerdb"
    print_status "Symlink created: /home/customerdb -> /var/www/customerdb"
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

# Setup environment
# setup_environment() {
#     print_status "Setting up environment..."
    
#     # Create environment file for production
#     cat > /etc/environment << EOF
# # Production environment for customerdb
# NODE_ENV=production
# PORT=5000
# DATABASE_HOST=localhost
# DATABASE_PORT=5432
# DATABASE_NAME=custmp_db
# DATABASE_USERNAME=custmp_user
# DATABASE_PASSWORD=custmp_password
# EOF
    
#     # Setup PATH for Node.js
#     echo 'export PATH=/usr/bin:$PATH' >> /etc/profile
    
#     # Create PM2 ecosystem file
#     cat > /var/www/customerdb/ecosystem.config.js << 'EOF'
# module.exports = {
#   apps: [{
#     name: 'customerdb-backend',
#     script: './backend/dist/main.js',
#     instances: 1,
#     exec_mode: 'cluster',
#     env: {
#       NODE_ENV: 'production',
#       PORT: 5000
#     }
#   }]
# }
# EOF
    
#     print_status "Environment configured"
# }

# Setup SSL auto-renewal
setup_ssl_renewal() {
    print_status "Setting up SSL auto-renewal..."
    
    # Add cron job for renewal
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    print_status "SSL auto-renewal configured"
}
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
        vim \
        fail2ban \
        ufw \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    
    # Configure fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    # Configure git (optional)
    git config --global init.defaultBranch main
    
    print_status "Additional tools installed"
}

# Main setup function
main() {
    print_status "Starting server setup..."
    
    update_system
    #install_nodejs
    #install_pm2
    #install_nginx
    #install_certbot
    #install_postgresql
    #setup_firewall
    setup_directories
    setup_environment
    setup_swap
    setup_ssl_renewal
    install_tools
    
    print_status "🎉 Server setup completed!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Setup DNS records for your domains"
    print_status "2. Upload customerdb project to /var/www/"
    print_status "3. Deploy your applications using deployment scripts"
    print_status "4. Setup SSL certificates"
    print_status ""
    print_status "Commands to run next:"
    print_status "sudo certbot --nginx -d customer.merahputih-id.com"
    print_status "sudo certbot --nginx -d bc.merahputih-id.com"
    print_status ""
    # print_status "Database Configuration:"
    # print_status "Database: custmp_db"
    # print_status "User: custmp_user"
    # print_status "Password: custmp_password"
    # print_status "Host: localhost"
    # print_status "Port: 5432"
    
    # Show service status
    echo ""
    print_status "Service Status:"
    systemctl status nginx --no-pager -l | head -10
    systemctl status postgresql --no-pager -l | head -10
    systemctl status fail2ban --no-pager -l | head -5
    
    # Show firewall status
    echo ""
    print_status "Firewall Status:"
    ufw status
    
    # Show system info
    echo ""
    print_status "System Information:"
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo "PM2: $(pm2 --version)"
    echo "nginx: $(nginx -v 2>&1)"
    echo "PostgreSQL: $(sudo -u postgres psql -c 'SELECT version();' | head -3 | tail -1)"
    
    # Show next steps
    echo ""
    print_status "🎉 Server setup completed successfully!"
    print_status "Your server is now ready for customerdb deployment!"
}

# Run main function
main "$@"
