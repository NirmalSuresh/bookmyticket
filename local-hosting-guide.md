# Local Hosting Guide - BookMyTicket

## Option 1: Simple Local Server (Quick Start)

### Step 1: Start PostgreSQL
```bash
# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database
sudo -u postgres createdb bookmyticket_production
sudo -u postgres createuser bookmyticket
sudo -u postgres psql -c "ALTER USER bookmyticket PASSWORD 'your_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bookmyticket_production TO bookmyticket;"
```

### Step 2: Set Environment Variables
```bash
# Create .env file
cat > .env << EOF
RAILS_ENV=production
DATABASE_URL=postgresql://bookmyticket:your_password@localhost/bookmyticket_production
RAILS_MASTER_KEY=$(cat config/master.key)
RAILS_SERVE_STATIC_FILES=true
EOF

# Load environment variables
export $(cat .env | xargs)
```

### Step 3: Setup Database
```bash
rails db:migrate RAILS_ENV=production
rails db:seed RAILS_ENV=production  # If you have seed data
```

### Step 4: Precompile Assets
```bash
rails assets:precompile RAILS_ENV=production
```

### Step 5: Start Server
```bash
rails server -b 0.0.0.0 -p 3000 -e production
```

### Step 6: Access Your App
Visit: `http://localhost:3000`

---

## Option 2: Using Nginx + Puma (Production Ready)

### Step 1: Install Nginx
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx

# macOS
brew install nginx
```

### Step 2: Configure Puma
```bash
# Create Puma config
cat > config/puma.rb << EOF
#!/usr/bin/env puma

directory '/home/nirmal/bookmyticket'
environment 'production'

daemonize true
pidfile '/home/nirmal/bookmyticket/tmp/pids/puma.pid'
state_path '/home/nirmal/bookmyticket/tmp/pids/puma.state'
stdout_redirect '/home/nirmal/bookmyticket/log/puma.log', '/home/nirmal/bookmyticket/log/puma_err.log'

bind 'unix:///home/nirmal/bookmyticket/tmp/sockets/puma.sock'
threads 0, 16
workers 4
max_threads 16
preload_app!

plugin 'tmp_restart'
EOF
```

### Step 3: Configure Nginx
```bash
# Create Nginx site config
sudo cat > /etc/nginx/sites-available/bookmyticket << EOF
upstream bookmyticket {
  server unix:///home/nirmal/bookmyticket/tmp/sockets/puma.sock;
}

server {
  listen 80;
  server_name localhost;

  root /home/nirmal/bookmyticket/public;
  try_files \$uri @bookmyticket;

  location @bookmyticket {
    proxy_pass http://bookmyticket;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Host \$http_host;
    proxy_redirect off;
  }

  location ~ ^/(assets|packs) {
    expires max;
    add_header Cache-Control public;
    add_header Vary Accept-Encoding;
    gzip_static on;
  }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/bookmyticket /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

### Step 4: Create Systemd Service
```bash
# Create systemd service
sudo cat > /etc/systemd/system/bookmyticket.service << EOF
[Unit]
Description=BookMyTicket Rails App
After=network.target

[Service]
Type=simple
User=nirmal
WorkingDirectory=/home/nirmal/bookmyticket
ExecStart=/home/nirmal/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=1
SyslogIdentifier=bookmyticket

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable bookmyticket
sudo systemctl start bookmyticket
```

---

## Option 3: Using Docker (Easiest)

### Step 1: Create Dockerfile
```bash
cat > Dockerfile << EOF
FROM ruby:3.3.5

# Install dependencies
RUN apt-get update -qq && apt-get install -y postgresql-client

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy app code
COPY . .

# Precompile assets
RUN RAILS_ENV=production rails assets:precompile

# Expose port
EXPOSE 3000

# Start command
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000", "-e", "production"]
EOF
```

### Step 2: Create docker-compose.yml
```bash
cat > docker-compose.yml << EOF
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: bookmyticket_production
      POSTGRES_USER: bookmyticket
      POSTGRES_PASSWORD: your_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  web:
    build: .
    command: rails server -b 0.0.0.0 -p 3000 -e production
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://bookmyticket:your_password@db:5432/bookmyticket_production
      - RAILS_ENV=production
      - RAILS_MASTER_KEY=your_master_key_here
    depends_on:
      - db

volumes:
  postgres_data:
EOF
```

### Step 3: Run with Docker
```bash
# Build and start
docker-compose build
docker-compose up -d

# Setup database
docker-compose exec web rails db:migrate
docker-compose exec web rails db:seed

# Access app
# Visit: http://localhost:3000
```

---

## Making it Public (Port Forwarding)

### Option A: ngrok (Easiest)
```bash
# Install ngrok
# Download from https://ngrok.com/download

# Start ngrok
./ngrok http 3000

# You'll get a public URL like: https://abc123.ngrok.io
```

### Option B: LocalTunnel
```bash
# Install
npm install -g localtunnel

# Run
lt --port 3000
```

### Option C: Router Port Forwarding
1. Find your public IP: `curl ifconfig.me`
2. Login to your router
3. Forward port 3000 to your computer's local IP
4. Access via: `http://YOUR_PUBLIC_IP:3000`

---

## SSL Certificate (HTTPS)

### Using Let's Encrypt with Nginx
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d yourdomain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

---

## Troubleshooting

### Common Issues:
1. **Database connection failed**: Check PostgreSQL is running
2. **Assets not loading**: Run `rails assets:precompile`
3. **Permission denied**: Check file permissions
4. **Port already in use**: Kill process with `sudo lsof -ti:3000 | xargs kill`

### Log Files:
- Rails logs: `log/production.log`
- Nginx logs: `/var/log/nginx/error.log`
- Puma logs: `log/puma.log`

### Check Status:
```bash
# Check Rails
ps aux | grep rails

# Check Nginx
sudo systemctl status nginx

# Check PostgreSQL
sudo systemctl status postgresql
```

---

## Security Tips

1. **Change default passwords**
2. **Use firewall**: `sudo ufw enable`
3. **Keep software updated**
4. **Use HTTPS in production**
5. **Backup your database regularly**

Choose the option that best fits your needs. Option 1 is fastest for testing, Option 2 is most robust, Option 3 is easiest for development.
