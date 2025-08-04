#!/bin/bash

# Server Deployment Checklist for Portfolio
# Run this on your target server

echo "🚀 Portfolio Server Deployment Script"
echo "====================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Please don't run this script as root. Use a regular user with sudo privileges."
    exit 1
fi

echo "📋 Pre-deployment Checklist:"
echo "1. Server specifications:"
echo "   - Ubuntu 20.04+ or Debian 10+ (recommended)"
echo "   - At least 1GB RAM"
echo "   - 10GB+ storage space"
echo "   - Python 3.8+"
echo ""

echo "2. Required information:"
echo "   - Domain name (if you have one)"
echo "   - SSL certificate path (if you have one)"
echo ""

echo "3. This script will install:"
echo "   - PostgreSQL database"
echo "   - Nginx web server"
echo "   - Python dependencies"
echo "   - Configure firewall"
echo ""

read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# System updates
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "📦 Installing required packages..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    postgresql \
    postgresql-contrib \
    nginx \
    git \
    ufw \
    certbot \
    python3-certbot-nginx

# Create project directory
PROJECT_DIR="/opt/portfolio"
echo "📁 Creating project directory: $PROJECT_DIR"
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# Clone or setup project (you'll need to upload your files here)
echo "📂 Project setup:"
echo "   Please upload your portfolio files to: $PROJECT_DIR"
echo "   Or clone from git repository"
echo ""
read -p "Press Enter when your project files are in $PROJECT_DIR..."

# Create virtual environment
echo "🐍 Setting up Python virtual environment..."
cd $PROJECT_DIR
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements-prod.txt

# Configure PostgreSQL
echo "🗄️ Setting up PostgreSQL database..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Generate random password for database
DB_PASSWORD=$(openssl rand -base64 32)

sudo -u postgres psql << EOF
CREATE DATABASE portfolio_db;
CREATE USER portfolio_user WITH PASSWORD '$DB_PASSWORD';
ALTER ROLE portfolio_user SET client_encoding TO 'utf8';
ALTER ROLE portfolio_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE portfolio_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE portfolio_db TO portfolio_user;
\q
EOF

# Create .env file
echo "⚙️ Creating environment configuration..."
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

cat > .env << EOF
# Production Environment Variables
DEBUG=False
SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=localhost,127.0.0.1

# Database Configuration
DB_NAME=portfolio_db
DB_USER=portfolio_user
DB_PASSWORD=$DB_PASSWORD
DB_HOST=localhost
DB_PORT=5432
EOF

echo "🔐 Database credentials saved to .env file"
echo "   Database: portfolio_db"
echo "   User: portfolio_user"
echo "   Password: $DB_PASSWORD"

# Run Django setup
echo "🔧 Setting up Django application..."
source venv/bin/activate
export $(cat .env | grep -v '^#' | xargs)

python manage.py migrate
python manage.py collectstatic --noinput

# Create Django superuser
echo "👤 Creating Django admin user..."
echo "Please create an admin user for your portfolio:"
python manage.py createsuperuser

# Setup Gunicorn service
echo "⚙️ Setting up Gunicorn service..."
sudo tee /etc/systemd/system/portfolio.service > /dev/null << EOF
[Unit]
Description=Portfolio Django Application
After=network.target

[Service]
Type=notify
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_DIR
Environment=DJANGO_SETTINGS_MODULE=Portfolio.settings
EnvironmentFile=$PROJECT_DIR/.env
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --config gunicorn.conf.py Portfolio.wsgi:application
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable portfolio
sudo systemctl start portfolio

# Configure Nginx (reverse proxy compatible)
echo "🌐 Setting up Nginx for reverse proxy..."

# Check if this server should run Nginx or just the application
read -p "Do you want to install Nginx on this server? (y/N - choose N if using external reverse proxy): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Full Nginx setup for standalone deployment
    sudo tee /etc/nginx/sites-available/portfolio > /dev/null << EOF
server {
    listen 80;
    server_name _;

    # Real IP forwarding for reverse proxy
    set_real_ip_from 0.0.0.0/0;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    location /static/ {
        alias $PROJECT_DIR/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias $PROJECT_DIR/media/;
        expires 1y;
        add_header Cache-Control "public";
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        # Timeout settings
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    client_max_body_size 20M;
}
EOF

    sudo ln -sf /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo nginx -t
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    
    echo "✅ Nginx configured for local serving"
    NGINX_NOTE="Local Nginx is serving on port 80"
else
    # Just application server mode
    echo "⚠️  Skipping Nginx installation - using external reverse proxy"
    echo "📝 Your reverse proxy should point to: http://this-server-ip:8000"
    NGINX_NOTE="Application running on port 8000 (configure your reverse proxy to point here)"
fi

# Configure firewall
echo "🔒 Configuring firewall..."
sudo ufw --force enable
sudo ufw allow OpenSSH

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Allow HTTP/HTTPS if running local Nginx
    sudo ufw allow 'Nginx Full'
    echo "✅ Firewall configured for local Nginx (ports 80, 443)"
else
    # Allow application port for reverse proxy
    sudo ufw allow 8000
    echo "✅ Firewall configured for reverse proxy (port 8000)"
fi

# Final status check
echo "✅ Deployment completed!"
echo ""
echo "🔍 Service Status:"
sudo systemctl status portfolio --no-pager -l
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo systemctl status nginx --no-pager -l
    echo ""
fi

echo "🌐 Your portfolio application:"
echo "   $NGINX_NOTE"
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "   Direct access: http://$(curl -s ipinfo.io/ip 2>/dev/null || echo 'YOUR_SERVER_IP'):8000"
    echo "   ⚠️  Configure your reverse proxy to point to this server on port 8000"
else
    echo "   Local access: http://$(curl -s ipinfo.io/ip 2>/dev/null || echo 'YOUR_SERVER_IP')"
fi
echo ""

echo "📝 Next steps:"
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "1. Configure your reverse proxy to point to: http://this-server:8000"
    echo "2. Update ALLOWED_HOSTS in .env with your actual domain name"
    echo "3. Ensure your reverse proxy forwards the correct headers"
    echo "4. Test your deployment through the reverse proxy"
else
    echo "1. Update ALLOWED_HOSTS in .env with your domain name"
    echo "2. Set up SSL certificate with: sudo certbot --nginx"
    echo "3. Update DNS records to point to this server"
    echo "4. Test your deployment"
fi
echo ""

echo "📁 Important files:"
echo "   Project directory: $PROJECT_DIR"
echo "   Environment file: $PROJECT_DIR/.env"
echo "   Nginx config: /etc/nginx/sites-available/portfolio"
echo "   Service file: /etc/systemd/system/portfolio.service"
echo ""

echo "🔧 Useful commands:"
echo "   Restart app: sudo systemctl restart portfolio"
echo "   View logs: sudo journalctl -u portfolio -f"
echo "   Update code: cd $PROJECT_DIR && git pull && sudo systemctl restart portfolio"
