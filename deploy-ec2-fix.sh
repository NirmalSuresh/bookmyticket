#!/bin/bash

# EC2 Deployment Fix for Poster Display Issue
echo "Setting up EC2 environment for poster display..."

# 1. Set up AWS credentials environment variables
echo "Configuring AWS credentials..."
export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
export AWS_REGION="us-east-1"

# 2. Set up Rails environment variables
echo "Configuring Rails environment..."
export RAILS_ENV="production"
export RAILS_MASTER_KEY="YOUR_RAILS_MASTER_KEY"
export DATABASE_URL="postgresql://bookmyticket:YOUR_DB_PASSWORD@localhost/bookmyticket_production"

# 3. Precompile assets
echo "Precompiling assets..."
rails assets:precompile

# 4. Set up database (if needed)
echo "Setting up database..."
rails db:migrate RAILS_ENV=production

# 5. Start the server
echo "Starting Rails server..."
rails server -b 0.0.0.0 -p 3000 -e production

echo "EC2 deployment setup complete!"
echo "Make sure to:"
echo "1. Replace YOUR_AWS_ACCESS_KEY_ID with your actual AWS access key"
echo "2. Replace YOUR_AWS_SECRET_ACCESS_KEY with your actual AWS secret key"
echo "3. Replace YOUR_RAILS_MASTER_KEY with your actual master key"
echo "4. Replace YOUR_DB_PASSWORD with your actual database password"
echo "5. Ensure your EC2 instance has proper IAM roles for S3 access"
