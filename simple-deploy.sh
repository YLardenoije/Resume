#!/bin/bash

# Simple Portfolio Deployment for Reverse Proxy Setup
# This script assumes you have an external Nginx reverse proxy handling SSL

echo "🚀 Portfolio Deployment (Reverse Proxy Mode)"
echo "============================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please don't run this script as root. Use a regular user with sudo privileges."
    exit 1
fi

echo "📋 This script will:"
echo "   ✅ Install PostgreSQL database"
echo "   ✅ Install Python dependencies"
echo "   ✅ Set up Django application on port 8000"
echo "   ✅ Configure firewall for reverse proxy"
echo "   ❌ Skip local Nginx (you have reverse proxy)"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# System updates
echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

# Install required packages (no nginx, no certbot)
echo "📦 Installing packages..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    postgresql \
    postgresql-contrib \
    git \
    ufw

# Create project directory
PROJECT_DIR="/opt/portfolio"
echo "📁 Creating project directory: $PROJECT_DIR"
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR

# Project setup
echo "📂 Upload your portfolio files to: $PROJECT_DIR"
echo "   You can use: scp, git clone, or rsync"
echo ""
read -p "Press Enter when your files are ready in $PROJECT_DIR..."

# Verify files exist
if [ ! -f "$PROJECT_DIR/manage.py" ]; then
    echo "❌ Django files not found in $PROJECT_DIR"
    echo "   Please upload your portfolio files and try again"
    exit 1
fi

# Create virtual environment
echo "🐍 Setting up Python environment..."
cd $PROJECT_DIR
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements-prod.txt

# PostgreSQL setup
echo "🗄️ Setting up PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Generate secure credentials
DB_PASSWORD=$(openssl rand -base64 32)
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

# Create database
sudo -u postgres psql << EOF
CREATE DATABASE portfolio_db;
CREATE USER portfolio_user WITH PASSWORD '$DB_PASSWORD';
ALTER ROLE portfolio_user SET client_encoding TO 'utf8';
ALTER ROLE portfolio_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE portfolio_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE portfolio_db TO portfolio_user;
\q
EOF

# Create environment file
echo "⚙️ Creating environment configuration..."
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

echo "🔐 Credentials saved to .env"
echo "   Database: portfolio_db"
echo "   User: portfolio_user"

# Django setup
echo "🔧 Setting up Django..."
source venv/bin/activate

# Securely load environment variables from .env
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    if [[ -n "$key" && "$key" != \#* ]]; then
        export "$key=$value"
    fi
done < .env

python manage.py migrate
python manage.py collectstatic --noinput

# Create admin user
echo "👤 Create Django admin user:"
python manage.py createsuperuser

# Setup service
echo "⚙️ Setting up application service..."
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

# Start services
sudo systemctl daemon-reload
sudo systemctl enable portfolio
sudo systemctl start portfolio

# Configure firewall
echo "🔒 Configuring firewall..."
sudo ufw --force enable
sudo ufw allow OpenSSH
sudo ufw allow 8000
echo "✅ Port 8000 opened for reverse proxy"

# Get server IP
SERVER_IP=$(curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_SERVER_IP")

# Final status
echo ""
echo "✅ Deployment Complete!"
echo ""
echo "🔍 Service Status:"
sudo systemctl status portfolio --no-pager -l
echo ""
echo "🌐 Application Details:"
echo "   Port: 8000"
echo "   Direct access: http://$SERVER_IP:8000"
echo "   Status: $(sudo systemctl is-active portfolio)"
echo ""
echo "🔧 Reverse Proxy Configuration:"
echo "   Point your reverse proxy to: http://$SERVER_IP:8000"
echo ""
echo "📝 Next Steps:"
echo "   1. Add your domain to ALLOWED_HOSTS in .env:"
echo "      nano $PROJECT_DIR/.env"
echo "      ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,$SERVER_IP"
echo ""
echo "   2. Configure your reverse proxy to point to:"
echo "      http://$SERVER_IP:8000"
echo ""
echo "   3. Restart after updating ALLOWED_HOSTS:"
echo "      sudo systemctl restart portfolio"
echo ""
echo "🔧 Useful Commands:"
echo "   View logs: sudo journalctl -u portfolio -f"
echo "   Restart: sudo systemctl restart portfolio"
echo "   Status: sudo systemctl status portfolio"
