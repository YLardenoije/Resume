# 🔄 Reverse Proxy Configuration Guide

Since you're using an Nginx reverse proxy with SSL management, here's how to configure everything properly.

## Server Setup (Application Server)

Your portfolio server will run the Django application on port 8000. The deployment script will:
- ✅ Install and configure PostgreSQL
- ✅ Set up Django with Gunicorn
- ✅ Optionally skip local Nginx (recommended for reverse proxy setup)
- ✅ Configure firewall to allow port 8000

## Reverse Proxy Configuration

Add this configuration to your main Nginx reverse proxy:

### Basic Configuration
```nginx
upstream portfolio_backend {
    server your-portfolio-server-ip:8000;
    # Add more servers here for load balancing if needed
    # server another-server-ip:8000;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # Your existing SSL configuration
    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    # Portfolio application
    location / {
        proxy_pass http://portfolio_backend;
        
        # Essential headers for Django
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Other settings
        proxy_redirect off;
        proxy_buffering off;
        client_max_body_size 20M;
    }

    # Static files (optional - can be served directly by reverse proxy)
    location /static/ {
        alias /path/to/portfolio/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Media files (optional)
    location /media/ {
        alias /path/to/portfolio/media/;
        expires 1y;
        add_header Cache-Control "public";
    }
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

### Advanced Configuration with Load Balancing
```nginx
upstream portfolio_backend {
    # Load balancing methods: round_robin (default), least_conn, ip_hash
    least_conn;
    
    server portfolio-server-1:8000 weight=3 max_fails=3 fail_timeout=30s;
    server portfolio-server-2:8000 weight=2 max_fails=3 fail_timeout=30s;
    
    # Health check (nginx plus feature)
    # health_check;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # Your SSL configuration...
    
    location / {
        proxy_pass http://portfolio_backend;
        
        # Headers for Django
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Connection settings
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        # Caching (optional)
        proxy_cache_bypass $http_pragma;
        proxy_cache_revalidate on;
        
        # Enable if using websockets (future enhancement)
        # proxy_set_header Upgrade $http_upgrade;
        # proxy_set_header Connection "upgrade";
    }
}
```

## Portfolio Server Configuration

### Environment Variables (.env)
```bash
# Production Environment Variables
DEBUG=False
SECRET_KEY=your-generated-secret-key
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# Database Configuration
DB_NAME=portfolio_db
DB_USER=portfolio_user
DB_PASSWORD=generated-secure-password
DB_HOST=localhost
DB_PORT=5432

# Reverse proxy settings
USE_X_FORWARDED_HOST=True
USE_X_FORWARDED_PORT=True
```

### Django Settings for Reverse Proxy
Your Django settings already include these, but here's what's important:

```python
# Trust proxy headers
USE_X_FORWARDED_HOST = True
USE_X_FORWARDED_PORT = True

# Security settings (already configured)
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_SSL_REDIRECT = True  # Only when DEBUG=False
```

## Deployment Steps

### 1. Deploy Portfolio Server
```bash
# On your portfolio server
cd /opt/portfolio
./server-deploy.sh

# When prompted about Nginx, choose 'N' to skip local Nginx
# The application will run on port 8000
```

### 2. Configure Reverse Proxy
```bash
# On your reverse proxy server
# Add the portfolio configuration to your Nginx
sudo nano /etc/nginx/sites-available/portfolio
# (paste the configuration above)

sudo ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Update DNS
Point your domain to your reverse proxy server (not the portfolio server).

### 4. Test Configuration
```bash
# Test from reverse proxy server
curl -H "Host: yourdomain.com" http://portfolio-server-ip:8000

# Test through reverse proxy
curl https://yourdomain.com
```

## Monitoring and Troubleshooting

### Health Checks
```bash
# Check application server
curl http://portfolio-server-ip:8000/

# Check through reverse proxy
curl -I https://yourdomain.com/
```

### Log Monitoring
```bash
# Portfolio server logs
sudo journalctl -u portfolio -f

# Reverse proxy logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Common Issues

**1. 502 Bad Gateway**
- Check if portfolio service is running: `sudo systemctl status portfolio`
- Verify port 8000 is accessible: `netstat -tlnp | grep :8000`
- Check firewall: `sudo ufw status`

**2. CSS/JS not loading**
- Verify static files path in reverse proxy config
- Check ALLOWED_HOSTS includes your domain
- Ensure static files were collected: `python manage.py collectstatic`

**3. CSRF errors**
- Verify X-Forwarded-* headers are set in reverse proxy
- Check ALLOWED_HOSTS includes your domain
- Ensure SECURE_PROXY_SSL_HEADER is configured

## Security Considerations

### Firewall Rules
```bash
# On portfolio server - only allow reverse proxy
sudo ufw allow from reverse-proxy-ip to any port 8000
sudo ufw deny 8000  # Block direct access from internet
```

### Network Isolation
Consider putting portfolio servers on a private network accessible only to your reverse proxy.

### Rate Limiting
Add rate limiting to your reverse proxy:
```nginx
http {
    limit_req_zone $binary_remote_addr zone=portfolio:10m rate=10r/s;
    
    server {
        location / {
            limit_req zone=portfolio burst=20 nodelay;
            proxy_pass http://portfolio_backend;
            # ... other config
        }
    }
}
```

This setup gives you a robust, scalable deployment with SSL termination handled by your reverse proxy! 🚀
