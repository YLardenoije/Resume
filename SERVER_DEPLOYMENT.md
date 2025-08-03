# 🚀 Deploy to Your Existing Server

## Quick Deployment Steps

### 1. Upload Your Portfolio Files
Transfer your portfolio files to your server using one of these methods:

**Option A: Using SCP**
```bash
# From your local machine, upload the entire portfolio
scp -r /media/yves/Data/Repositories/Resume/ username@your-server-ip:/opt/portfolio/
```

**Option B: Using Git**
```bash
# On your server, clone the repository
git clone https://github.com/YLardenoije/Resume.git /opt/portfolio
cd /opt/portfolio
```

**Option C: Using rsync**
```bash
# From your local machine
rsync -avz --exclude='.git' /media/yves/Data/Repositories/Resume/ username@your-server-ip:/opt/portfolio/
```

### 2. Run the Deployment Script
On your server, run:
```bash
# Make sure you're in the portfolio directory
cd /opt/portfolio

# Run the deployment script
./server-deploy.sh
```

This script will:
- ✅ Install PostgreSQL, Nginx, Python dependencies
- ✅ Create database and user with secure password
- ✅ Set up environment variables
- ✅ Configure Django (migrations, static files, admin user)
- ✅ Set up Gunicorn service
- ✅ Configure Nginx web server
- ✅ Set up firewall rules

### 3. Update Domain Configuration
After deployment, update your domain settings:

```bash
# Edit the environment file
nano /opt/portfolio/.env

# Update ALLOWED_HOSTS with your domain
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,your-server-ip
```

### 4. Set Up SSL (Recommended)
```bash
# Install SSL certificate with Let's Encrypt
sudo certbot --nginx

# Follow the prompts to set up HTTPS
```

### 5. Point Your Domain
Update your domain's DNS records:
- **A Record**: `yourdomain.com` → `your-server-ip`
- **CNAME Record**: `www.yourdomain.com` → `yourdomain.com`

## Quick Commands for Your Server

### Service Management
```bash
# Restart the application
sudo systemctl restart portfolio

# View application logs
sudo journalctl -u portfolio -f

# Check service status
sudo systemctl status portfolio
```

### Nginx Management
```bash
# Restart Nginx
sudo systemctl restart nginx

# Test Nginx configuration
sudo nginx -t

# View access logs
sudo tail -f /var/log/nginx/access.log
```

### Database Management
```bash
# Connect to PostgreSQL
sudo -u postgres psql portfolio_db

# Create database backup
pg_dump -h localhost -U portfolio_user portfolio_db > backup.sql
```

### Application Updates
```bash
# Update your code (if using git)
cd /opt/portfolio
git pull
source venv/bin/activate
pip install -r requirements-prod.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart portfolio
```

## Troubleshooting

### Common Issues

**1. Application won't start**
```bash
# Check logs
sudo journalctl -u portfolio -e

# Check if port 8000 is in use
sudo netstat -tlnp | grep :8000
```

**2. Database connection errors**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test database connection
sudo -u postgres psql -c "SELECT version();"
```

**3. Static files not loading**
```bash
# Recollect static files
cd /opt/portfolio
source venv/bin/activate
python manage.py collectstatic --noinput
sudo systemctl restart nginx
```

**4. Permission errors**
```bash
# Fix file permissions
cd /opt/portfolio
sudo chown -R $USER:$USER .
chmod +x server-deploy.sh
```

## Security Checklist

After deployment, verify:
- [ ] Firewall is enabled (`sudo ufw status`)
- [ ] Only necessary ports are open (22, 80, 443)
- [ ] SSL certificate is installed
- [ ] Database has strong password
- [ ] Django DEBUG is False
- [ ] Static files are served by Nginx

## Performance Optimization

### Enable Gzip Compression
Add to your Nginx config:
```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript;
```

### Set Up Log Rotation
```bash
sudo nano /etc/logrotate.d/portfolio
```

## Monitoring

### Set Up Basic Monitoring
```bash
# Install htop for system monitoring
sudo apt install htop

# Monitor application logs
sudo journalctl -u portfolio -f

# Monitor system resources
htop
```

Your portfolio will be live and accessible once the deployment completes! 🎉
