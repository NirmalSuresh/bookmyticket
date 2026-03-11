#!/bin/bash

echo "🔧 Deploying Sign Out Fix to EC2"
echo "================================="

# Configuration - Use environment variables or provide as arguments
EC2_IP="${EC2_IP:-$1}"
EC2_USER="${EC2_USER:-ec2-user}"
KEY_FILE="${KEY_FILE:-your-key.pem}"

# Check required parameters
if [ -z "$EC2_IP" ] || [ -z "$KEY_FILE" ]; then
    echo "❌ Error: EC2_IP and KEY_FILE must be provided"
    echo "Usage: $0 <EC2_IP> <KEY_FILE> [EC2_USER]"
    exit 1
fi

echo "📍 Target: $EC2_USER@$EC2_IP"
echo "📁 Fixing: app/views/layouts/application.html.erb"
echo ""

# Test SSH connection
echo "🔍 Testing SSH connection..."
if ssh -i "$KEY_FILE" -o ConnectTimeout=10 $EC2_USER@$EC2_IP "echo 'SSH connection successful'" 2>/dev/null; then
    echo "✅ SSH connection successful"
else
    echo "❌ SSH connection failed!"
    echo "Please check your EC2 instance and SSH configuration"
    exit 1
fi

echo ""
echo "📦 Deploying JavaScript import fix..."

# Create backup and apply fix
ssh -i "$KEY_FILE" $EC2_USER@$EC2_IP << 'EOF'
cd /home/ec2-user/bookmyticket

# Backup current file
cp app/views/layouts/application.html.erb app/views/layouts/application.html.erb.backup

# Check if the fix is already applied
if grep -q "javascript_importmap_tags" app/views/layouts/application.html.erb; then
    echo "✅ JavaScript import already exists in layout"
else
    echo "🔧 Applying JavaScript import fix..."
    
    # Use sed to add the JavaScript import after stylesheet_link_tag
    sed -i '/<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>/a\    <%= javascript_importmap_tags %>' app/views/layouts/application.html.erb
    
    echo "✅ Fix applied successfully"
fi

# Verify the fix
echo ""
echo "🔍 Verifying the fix:"
grep -A2 -B2 "javascript_importmap_tags" app/views/layouts/application.html.erb

echo ""
echo "🔄 Restarting Rails server..."
# Kill existing Rails server and restart with logging
pkill -f "rails server" || true
cd /home/ec2-user/bookmyticket

# Create log directory if it doesn't exist
mkdir -p logs

# Start server with logging
nohup rails server -b 0.0.0.0 -p 3000 -e production > logs/rails.log 2>&1 &

echo "✅ Server restart initiated"
EOF

echo ""
echo "🎉 Deployment Complete!"
echo "📍 Your app should be available at: http://$EC2_IP:3000"
echo ""
echo "⏱️  Please wait 30 seconds for server to fully restart"
echo "🧪 Test sign_out functionality after the restart"
echo ""
echo "📋 To check server status:"
echo "ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'ps aux | grep rails'"
echo ""
echo "📋 To view logs:"
echo "ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'tail -f logs/rails.log'"
echo ""
