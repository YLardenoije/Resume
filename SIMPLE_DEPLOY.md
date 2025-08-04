# 🚀 Simple Server Deployment

Since you have a reverse proxy with SSL, here's the simplified process:

## Step 1: Upload Files to Your Server

Choose one method:

**Option A: SCP (from your local machine)**
```bash
scp -r /media/yves/Data/Repositories/Resume/ username@your-server:/opt/portfolio/
```

**Option B: Git Clone (on your server)**
```bash
git clone https://github.com/YLardenoije/Resume.git /opt/portfolio
```

## Step 2: Run the Simple Deployment Script

On your server:
```bash
cd /opt/portfolio
./simple-deploy.sh
```

This script will:
- ✅ Install PostgreSQL (no Nginx)
- ✅ Set up Django on port 8000
- ✅ Create secure database credentials
- ✅ Open firewall port 8000
- ✅ Start the application service

## Step 3: Configure Your Reverse Proxy

Add this to your existing Nginx reverse proxy:

```nginx
upstream portfolio {
    server your-server-ip:8000;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;
    
    # Your existing SSL config stays the same
    
    location / {
        proxy_pass http://portfolio;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Step 4: Update Domain Settings

On your server:
```bash
nano /opt/portfolio/.env
# Change this line:
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# Then restart:
sudo systemctl restart portfolio
```

## That's It!

Your portfolio will be accessible through your reverse proxy at `https://yourdomain.com`

### Quick Commands:
- **View logs**: `sudo journalctl -u portfolio -f`
- **Restart app**: `sudo systemctl restart portfolio`
- **Check status**: `sudo systemctl status portfolio`

Much simpler! 🎉
