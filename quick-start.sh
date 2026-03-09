#!/bin/bash

echo "🎬 BookMyTicket Quick Start - Local Hosting"
echo "=========================================="

# Check if PostgreSQL is running
if ! systemctl is-active --quiet postgresql; then
    echo "📦 Starting PostgreSQL..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
fi

# Create database if it doesn't exist
echo "🗄️ Setting up database..."
sudo -u postgres createdb bookmyticket_production 2>/dev/null || echo "Database already exists"
sudo -u postgres createuser bookmyticket 2>/dev/null || echo "User already exists"
sudo -u postgres psql -c "ALTER USER bookmyticket PASSWORD 'bookmyticket123';" 2>/dev/null
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bookmyticket_production TO bookmyticket;" 2>/dev/null

# Set environment variables
echo "🔧 Setting up environment..."
export RAILS_ENV=production
export DATABASE_URL="postgresql://bookmyticket:bookmyticket123@localhost/bookmyticket_production"
export RAILS_MASTER_KEY=$(cat config/master.key 2>/dev/null || echo "Set your master key in config/master.key")
export RAILS_SERVE_STATIC_FILES=true

# Setup database
echo "🏗️ Running migrations..."
rails db:migrate RAILS_ENV=production

# Precompile assets
echo "🎨 Precompiling assets..."
rails assets:precompile RAILS_ENV=production

# Start server
echo "🚀 Starting server..."
echo "📍 Your app will be available at: http://localhost:3000"
echo "🌍 To make it public, use ngrok: https://ngrok.com/download"
echo "⏹️  Press Ctrl+C to stop the server"
echo ""

rails server -b 0.0.0.0 -p 3000 -e production
