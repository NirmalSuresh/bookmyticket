#!/bin/bash

echo "🌩️ AWS Quick Start - BookMyTicket"
echo "================================="

# Check if we're on EC2
if curl -s http://169.254.169.254/latest/meta-data/instance-id > /dev/null 2>&1; then
    echo "✅ Running on AWS EC2"
else
    echo "❌ Not running on AWS EC2"
    echo "Please run this script on your EC2 instance"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
sudo apt update -qq
sudo apt install -y git curl gnupg build-essential postgresql postgresql-contrib nodejs npm

# Install rbenv if not exists
if ! command -v rbenv &> /dev/null; then
    echo "🔧 Installing rbenv..."
    cd ~
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# Install Ruby 3.3.5
RUBY_VERSION=$(rbenv version | cut -d' ' -f1)
if [ "$RUBY_VERSION" != "3.3.5" ]; then
    echo "💎 Installing Ruby 3.3.5..."
    rbenv install 3.3.5
    rbenv global 3.3.5
    gem install bundler
fi

# Setup PostgreSQL
echo "🗄️ Setting up PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

sudo -u postgres createdb bookmyticket_production 2>/dev/null || echo "Database exists"
sudo -u postgres createuser ubuntu 2>/dev/null || echo "User exists"
sudo -u postgres psql -c "ALTER USER ubuntu PASSWORD 'bookmyticket123';" 2>/dev/null
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bookmyticket_production TO ubuntu;" 2>/dev/null

# Clone or update app
if [ ! -d "bookmyticket" ]; then
    echo "📥 Cloning your app..."
    # Replace with your actual repository URL
    git clone https://github.com/yourusername/bookmyticket.git
fi

cd bookmyticket

# Install gems
echo "📚 Installing gems..."
bundle install

# Set environment variables
echo "🔧 Setting up environment..."
cat > .env << EOF
RAILS_ENV=production
DATABASE_URL=postgresql://ubuntu:bookmyticket123@localhost/bookmyticket_production
RAILS_MASTER_KEY=$(cat config/master.key 2>/dev/null || echo "Set your master key in config/master.key")
RAILS_SERVE_STATIC_FILES=true
EOF

# Load environment variables
export $(cat .env | xargs)

# Setup database
echo "🏗️ Running migrations..."
rails db:migrate RAILS_ENV=production

# Precompile assets
echo "🎨 Precompiling assets..."
rails assets:precompile RAILS_ENV=production

# Create systemd service
echo "⚙️ Setting up service..."
sudo cat > /etc/systemd/system/bookmyticket.service << EOF
[Unit]
Description=BookMyTicket Rails App
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/bookmyticket
Environment=RAILS_ENV=production
Environment=DATABASE_URL=postgresql://ubuntu:bookmyticket123@localhost/bookmyticket_production
Environment=RAILS_SERVE_STATIC_FILES=true
ExecStart=/home/ubuntu/.rbenv/shims/bundle exec rails server -b 0.0.0.0 -p 3000 -e production
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable bookmyticket
sudo systemctl start bookmyticket

echo "🚀 App is starting..."
echo "📍 Your app will be available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "🔥 To make it public on port 80, setup nginx or ALB"
echo "📋 Check status: sudo systemctl status bookmyticket"
echo "📋 View logs: sudo journalctl -u bookmyticket -f"
