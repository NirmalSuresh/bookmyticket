#!/bin/bash

echo "🚀 Deploy BookMyTicket to EC2"
echo "============================="

# Configuration - UPDATE THESE VALUES
EC2_IP="your-ec2-public-ip"
KEY_FILE="your-aws-key.pem"
REPO_URL="https://github.com/yourusername/bookmyticket.git"

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Key file '$KEY_FILE' not found!"
    echo "Please update KEY_FILE variable with your actual .pem file path"
    exit 1
fi

echo "🔧 Configuration:"
echo "EC2 IP: $EC2_IP"
echo "Key File: $KEY_FILE"
echo "Repository: $REPO_URL"
echo ""

# Test SSH connection
echo "🔍 Testing SSH connection..."
if ssh -i "$KEY_FILE" -o ConnectTimeout=10 ubuntu@$EC2_IP "echo 'SSH connection successful'" 2>/dev/null; then
    echo "✅ SSH connection successful"
else
    echo "❌ SSH connection failed!"
    echo "Please check:"
    echo "1. EC2 instance is running"
    echo "2. Security group allows SSH (port 22)"
    echo "3. Key file path is correct"
    echo "4. Key file permissions: chmod 400 $KEY_FILE"
    exit 1
fi

# Deploy to EC2
echo "📦 Deploying application..."
ssh -i "$KEY_FILE" ubuntu@$EC2_IP << EOF
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git curl gnupg build-essential postgresql postgresql-contrib nodejs npm

# Install rbenv if not exists
if ! command -v rbenv &> /dev/null; then
    echo "Installing rbenv..."
    cd ~
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    echo 'export PATH="\$HOME/.rbenv/bin:\$PATH"' >> ~/.bashrc
    echo 'eval "\$(rbenv init -)"' >> ~/.bashrc
    export PATH="\$HOME/.rbenv/bin:\$PATH"
    eval "\$(rbenv init -)"
    
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# Install Ruby 3.3.5
RUBY_VERSION=\$(rbenv version | cut -d' ' -f1)
if [ "\$RUBY_VERSION" != "3.3.5" ]; then
    echo "Installing Ruby 3.3.5..."
    rbenv install 3.3.5
    rbenv global 3.3.5
    gem install bundler
fi

# Setup PostgreSQL
echo "Setting up PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

sudo -u postgres createdb bookmyticket_production 2>/dev/null || echo "Database exists"
sudo -u postgres createuser ubuntu 2>/dev/null || echo "User exists"
sudo -u postgres psql -c "ALTER USER ubuntu PASSWORD 'bookmyticket123';" 2>/dev/null
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bookmyticket_production TO ubuntu;" 2>/dev/null

# Clone or update app
if [ ! -d "bookmyticket" ]; then
    echo "Cloning repository..."
    git clone $REPO_URL
else
    echo "Updating existing code..."
    cd bookmyticket
    git pull origin main
    cd ..
fi

cd bookmyticket

# Install gems
echo "Installing gems..."
bundle install

# Set environment variables
echo "Setting up environment..."
cat > .env << EOL
RAILS_ENV=production
DATABASE_URL=postgresql://ubuntu:bookmyticket123@localhost/bookmyticket_production
RAILS_MASTER_KEY=\$(cat config/master.key 2>/dev/null || echo "Set your master key in config/master.key")
RAILS_SERVE_STATIC_FILES=true
EOL

# Load environment variables
export \$(cat .env | xargs)

# Setup database
echo "Running migrations..."
rails db:migrate RAILS_ENV=production

# Precompile assets
echo "Precompiling assets..."
rails assets:precompile RAILS_ENV=production

# Create systemd service
echo "Creating service..."
sudo cat > /etc/systemd/system/bookmyticket.service << 'EOS'
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
EOS

# Start service
sudo systemctl daemon-reload
sudo systemctl enable bookmyticket
sudo systemctl start bookmyticket

echo "Deployment completed!"
EOF

echo ""
echo "🎉 Deployment Complete!"
echo "📍 Your app is available at: http://$EC2_IP:3000"
echo "🔧 Check status: ssh -i $KEY_FILE ubuntu@$EC2_IP 'sudo systemctl status bookmyticket'"
echo "📋 View logs: ssh -i $KEY_FILE ubuntu@$EC2_IP 'sudo journalctl -u bookmyticket -f'"
echo ""
echo "⚠️  Make sure your EC2 security group allows HTTP (port 3000) traffic!"
