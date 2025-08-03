# Production Deployment Guide

## Overview
This guide will help you deploy your Django portfolio to a production server with proper security and performance.

## Prerequisites
- Linux server (Ubuntu 20.04+ recommended)
- Python 3.8+
- Domain name (optional but recommended)
- SSH access to your server

## Manual Deployment Steps

### 1. Server Preparation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib git ufw
```

### 2. Upload Your Portfolio
```bash
# Option A: Upload via SCP
scp -r /path/to/your/portfolio/ user@your-server:/opt/portfolio/

# Option B: Clone from repository
git clone https://github.com/YLardenoije/Resume.git /opt/portfolio
cd /opt/portfolio
```

### 3. Python Environment Setup
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements-prod.txt
```

### 4. Database Setup
```bash
# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE portfolio_db;
CREATE USER portfolio_user WITH PASSWORD 'your_secure_password_here';
ALTER DATABASE portfolio_db OWNER TO portfolio_user;
ALTER ROLE portfolio_user SET client_encoding TO 'utf8';
ALTER ROLE portfolio_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE portfolio_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE portfolio_db TO portfolio_user;
\c portfolio_db
GRANT ALL ON SCHEMA public TO portfolio_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO portfolio_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO portfolio_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO portfolio_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO portfolio_user;
\q
EOF
```

### 5. Environment Configuration
```bash
# Generate a secret key
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# Create .env file
cat > .env << EOF
DEBUG=False
SECRET_KEY=your-generated-secret-key-here
ALLOWED_HOSTS=your-domain.com,www.your-domain.com,your-server-ip

DB_NAME=portfolio_db
DB_USER=portfolio_user
DB_PASSWORD=your_secure_password_here
DB_HOST=localhost
DB_PORT=5432
EOF
```

### 6. Django Setup
```bash
# Load environment and run setup
source venv/bin/activate
export $(cat .env | grep -v '^#' | xargs)

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create admin user
python manage.py createsuperuser
```

### 7. Gunicorn Service
```bash
# Create systemd service file
sudo tee /etc/systemd/system/portfolio.service > /dev/null << EOF
[Unit]
Description=Portfolio Django Application
After=network.target

[Service]
Type=notify
User=$USER
Group=$USER
WorkingDirectory=/opt/portfolio
Environment=DJANGO_SETTINGS_MODULE=Portfolio.settings
EnvironmentFile=/opt/portfolio/.env
ExecStart=/opt/portfolio/venv/bin/gunicorn --config gunicorn.conf.py Portfolio.wsgi:application
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable portfolio
sudo systemctl start portfolio
sudo systemctl status portfolio
```

### 8. Firewall Configuration
```bash
# Configure firewall
sudo ufw --force enable
sudo ufw allow OpenSSH
sudo ufw allow 8000  # For reverse proxy setup
```

### 9. Test Deployment
```bash
# Check service status
sudo systemctl status portfolio

# Test application directly
curl http://your-server-ip:8000

# View logs if needed
sudo journalctl -u portfolio -f
```

## Reverse Proxy Setup (Recommended)

Since you have existing Nginx with SSL certificates, add this configuration to your Nginx:

```nginx
# Add this upstream block (outside of server blocks)
upstream portfolio {
    server 192.168.1.199:8000;
}

# Add this server block or modify your existing one
server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    # Your existing SSL configuration
    # ssl_certificate /path/to/your/certificate.crt;
    # ssl_certificate_key /path/to/your/private.key;
    
    # Portfolio application
    location / {
        proxy_pass http://portfolio;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        proxy_redirect off;
        
        # Additional headers for better compatibility
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    # Serve static files directly through Nginx (optional but recommended)
    location /static/ {
        alias /opt/portfolio/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Serve media files directly through Nginx (optional)
    location /media/ {
        alias /opt/portfolio/media/;
        expires 30d;
        add_header Cache-Control "public";
        access_log off;
    }
}

# Optional: Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

## Troubleshooting

### Service Won't Start
```bash
# Check detailed status
sudo systemctl status portfolio -l

# Check logs
sudo journalctl -u portfolio -n 50

# Verify environment file
cat /opt/portfolio/.env

# Test manually
cd /opt/portfolio
source venv/bin/activate
export $(cat .env | grep -v '^#' | xargs)
python manage.py check --deploy
```

### Database Connection Issues
```bash
# Test PostgreSQL connection
sudo -u postgres psql -c "SELECT version();"

# Test from Django
cd /opt/portfolio
source venv/bin/activate
python manage.py dbshell
```

### Static Files Not Loading
```bash
# Recollect static files
cd /opt/portfolio
source venv/bin/activate
python manage.py collectstatic --noinput

# Check static files directory
ls -la staticfiles/
```

## Maintenance Commands

### Application Updates
```bash
# Update code (if using git)
cd /opt/portfolio
git pull

# Update dependencies
source venv/bin/activate
pip install -r requirements-prod.txt --upgrade

# Apply migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Restart service
sudo systemctl restart portfolio
```

### Database Backup
```bash
# Create backup
pg_dump -h localhost -U portfolio_user portfolio_db > backup_$(date +%Y%m%d).sql

# Restore backup (if needed)
psql -h localhost -U portfolio_user portfolio_db < backup_20231201.sql
```

### Log Monitoring
```bash
# View application logs
sudo journalctl -u portfolio -f

# Check service status
sudo systemctl status portfolio
```

## Security Best Practices

- [ ] `SECRET_KEY` - Generate a unique, random secret key
- [ ] `DEBUG=False` - Never run debug mode in production  
- [ ] `ALLOWED_HOSTS` - Set to your specific domain names
- [ ] Strong database passwords
- [ ] Regular security updates: `sudo apt update && sudo apt upgrade`
- [ ] Firewall configured to only allow necessary ports
- [ ] SSL/TLS certificates for HTTPS (handled by your reverse proxy)

## Performance Tips

- [ ] Use a reverse proxy (Nginx) for SSL termination and static files
- [ ] Enable database connection pooling for high traffic
- [ ] Set up monitoring and log rotation
- [ ] Regular database maintenance and backups

Your portfolio is now deployed and running in production! 🚀
