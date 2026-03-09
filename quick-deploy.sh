#!/bin/bash

echo "⚡ Quick Deploy to Your EC2"
echo "=========================="

# Get EC2 IP from user
read -p "Enter your EC2 Public IP: " EC2_IP
read -p "Enter your key file path (e.g., ~/Downloads/my-key.pem): " KEY_FILE

# Convert Windows path to Linux/WSL path if needed
if [[ "$KEY_FILE" == C:* ]]; then
    # Convert Windows path to WSL path
    KEY_FILE=$(echo "$KEY_FILE" | sed 's/C:\\/\\/mnt\\/c\\/' | sed 's/\\/\//g')
    echo "🔄 Converting Windows path to: $KEY_FILE"
fi

# Remove quotes if present
KEY_FILE=$(echo "$KEY_FILE" | sed 's/^"//' | sed 's/"$//')

# Debug: show final path
echo "🔍 Looking for key file at: $KEY_FILE"

# Validate inputs
if [ -z "$EC2_IP" ]; then
    echo "❌ EC2 IP is required!"
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Key file not found: $KEY_FILE"
    exit 1
fi

# Set key permissions
chmod 400 "$KEY_FILE"

echo "🔧 Deploying to: $EC2_IP"
echo "🔑 Using key: $KEY_FILE"
echo ""

# Test SSH connection
echo "🔍 Testing connection..."
if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ec2-user@$EC2_IP "echo 'SSH connection successful'" 2>/dev/null; then
    echo "✅ SSH connection successful"
else
    echo "❌ SSH connection failed!"
    echo "Please check:"
    echo "1. EC2 instance is running"
    echo "2. Security group allows SSH (port 22) from your IP"
    echo "3. Key file is correct and has proper permissions"
    echo "4. Try: chmod 400 $KEY_FILE"
    echo ""
    echo "Manual test: ssh -i $KEY_FILE ec2-user@$EC2_IP"
    exit 1
fi

# Quick deploy
echo "🚀 Starting deployment..."
ssh -i "$KEY_FILE" ec2-user@$EC2_IP << 'EOSSH'
# Quick setup
sudo yum update -y
sudo yum install -y git ruby ruby-devel postgresql15 postgresql15-server postgresql15-contrib nodejs npm gcc make

# Setup database
sudo /usr/pgsql-15/bin/postgresql15-setup initdb
sudo systemctl enable postgresql15
sudo systemctl start postgresql15

sudo -u postgres createdb bookmyticket_production 2>/dev/null
sudo -u postgres createuser ec2-user 2>/dev/null
sudo -u postgres psql -c "ALTER USER ec2-user PASSWORD 'bookmyticket123';" 2>/dev/null
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bookmyticket_production TO ec2-user;" 2>/dev/null

# Clone app
git clone https://github.com/yourusername/bookmyticket.git bookmyticket 2>/dev/null || (cd bookmyticket && git pull)
cd bookmyticket

# Install gems
gem install bundler
bundle install

# Setup environment
export RAILS_ENV=production
export DATABASE_URL="postgresql://ec2-user:bookmyticket123@localhost/bookmyticket_production"
export RAILS_SERVE_STATIC_FILES=true
export RAILS_MASTER_KEY="$(cat config/master.key 2>/dev/null || echo 'your_master_key_here')"

# Setup database
./bin/rails db:migrate RAILS_ENV=production

# Precompile assets
./bin/rails assets:precompile RAILS_ENV=production

# Start server
echo "Starting server..."
nohup ./bin/rails server -b 0.0.0.0 -p 3000 -e production > server.log 2>&1 &
echo $! > server.pid

echo "Server started!"
EOSSH

echo ""
echo "🎉 Deployment Complete!"
echo "📍 App URL: http://$EC2_IP:3000"
echo "🔧 To connect: ssh -i $KEY_FILE ec2-user@$EC2_IP"
echo "📋 To check logs: ssh -i $KEY_FILE ec2-user@$EC2_IP 'cd bookmyticket && tail -f server.log'"
echo ""
echo "⚠️  Ensure your EC2 security group allows port 3000!"
