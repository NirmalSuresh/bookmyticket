# AWS Deployment Guide - BookMyTicket

## Option 1: AWS EC2 (Recommended)

### Step 1: Launch EC2 Instance
1. Go to AWS Console → EC2 → Launch Instance
2. Choose: Ubuntu Server 22.04 LTS
3. Instance type: t2.micro (free tier) or t3.small
4. Configure Security Group:
   - SSH (port 22) - Your IP
   - HTTP (port 80) - Anywhere (0.0.0.0/0)
   - HTTPS (port 443) - Anywhere (0.0.0.0/0)
   - Custom (port 3000) - Anywhere (0.0.0.0/0)

### Step 2: Connect to EC2
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### Step 3: Setup Environment
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Ruby, Rails dependencies
sudo apt install -y git curl gnupg build-essential postgresql postgresql-contrib nodejs npm

# Install rbenv
cd ~
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec bash

# Install ruby-build
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Install Ruby 3.3.5
rbenv install 3.3.5
rbenv global 3.3.5

# Install Bundler
gem install bundler
```

### Step 4: Deploy App
```bash
# Clone your app
git clone your-repo-url
cd bookmyticket

# Install gems
bundle install

# Setup PostgreSQL
sudo -u postgres createdb bookmyticket_production
sudo -u postgres createuser bookmyticket
sudo -u postgres psql -c "ALTER USER bookmyticket PASSWORD 'secure_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bookmyticket_production TO bookmyticket;"

# Set environment variables
cat > .env << EOF
RAILS_ENV=production
DATABASE_URL=postgresql://bookmyticket:secure_password@localhost/bookmyticket_production
RAILS_MASTER_KEY=your_master_key_here
RAILS_SERVE_STATIC_FILES=true
EOF

# Setup database
rails db:migrate RAILS_ENV=production

# Precompile assets
rails assets:precompile RAILS_ENV=production

# Start server
rails server -b 0.0.0.0 -p 3000 -e production
```

### Step 5: Access Your App
Visit: `http://your-ec2-ip:3000`

---

## Option 2: AWS Elastic Beanstalk (Easiest)

### Step 1: Install EB CLI
```bash
# On your local machine
pip install awsebcli --upgrade --user
```

### Step 2: Initialize EB
```bash
cd /home/nirmal/bookmyticket
eb init -p "Ruby 3.3 running on 64bit Amazon Linux 2023" bookmyticket
```

### Step 3: Create Environment
```bash
eb create production
```

### Step 4: Deploy
```bash
eb deploy
```

---

## Option 3: AWS App Runner (Modern)

### Step 1: Create Dockerfile
```dockerfile
FROM ruby:3.3.5

RUN apt-get update -qq && apt-get install -y postgresql-client

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN RAILS_ENV=production rails assets:precompile

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000", "-e", "production"]
```

### Step 2: Create apprunner.yaml
```yaml
version: 1.0
runtime: ruby3
build:
  commands:
    build:
      - bundle install
    post_build:
      - rails assets:precompile RAILS_ENV=production
run:
  runtime-version: 3.3.5
  command: rails server -b 0.0.0.0 -p 3000 -e production
  environment:
    - name: RAILS_ENV
      value: production
    - name: RAILS_SERVE_STATIC_FILES
      value: true
    - name: DATABASE_URL
      value: your-rds-connection-string
    - name: RAILS_MASTER_KEY
      value: your-master-key
```

---

## Option 4: AWS Lightsail (Simple)

### Step 1: Create Lightsail Instance
1. AWS Console → Lightsail → Create instance
2. Choose: Linux/Unix → Ruby
3. Instance plan: $3.50/month (free tier)
4. Configure firewall: Allow HTTP (80) and HTTPS (443)

### Step 2: Deploy
```bash
# Connect via SSH
ssh -i your-key.pem user@your-lightsail-ip

# Deploy your app
git clone your-repo
cd bookmyticket
bundle install
# ... rest of setup similar to EC2
```

---

## Database Options

### Option A: RDS (Recommended for Production)
```bash
# Create RDS PostgreSQL instance
# Get connection string
export DATABASE_URL="postgresql://user:pass@your-rds-endpoint:5432/dbname"
```

### Option B: PostgreSQL on EC2 (Cheaper)
```bash
# Already setup in EC2 guide above
```

---

## Static Assets (S3)

### Step 1: Create S3 Bucket
1. AWS Console → S3 → Create bucket
2. Name: `bookmyticket-assets-production`
3. Make public

### Step 2: Configure Rails
```ruby
# config/environments/production.rb
config.active_storage.service = :amazon
config.asset_host = "https://your-bucket.s3.amazonaws.com"
```

### Step 3: Upload Assets
```bash
rails assets:precompile RAILS_ENV=production
aws s3 sync public/assets s3://your-bucket/assets
```

---

## Domain & SSL

### Step 1: Get Domain
- Route 53 → Register domain OR use existing

### Step 2: SSL Certificate
- AWS Certificate Manager → Request certificate
- Validate via DNS

### Step 3: Load Balancer
- Create Application Load Balancer
- Add SSL certificate
- Point to EC2 instances

---

## Environment Variables Setup

### Method 1: EC2 User Data
```bash
#!/bin/bash
echo "export RAILS_ENV=production" >> /etc/environment
echo "export DATABASE_URL=postgresql://..." >> /etc/environment
echo "export RAILS_MASTER_KEY=..." >> /etc/environment
```

### Method 2: AWS Secrets Manager
```bash
# Store secrets in Secrets Manager
# Access in your app via AWS SDK
```

### Method 3: Parameter Store
```bash
aws ssm put-parameter --name "/bookmyticket/RAILS_MASTER_KEY" --value "your-key" --type SecureString
```

---

## Monitoring & Logging

### CloudWatch
```bash
# Install CloudWatch agent
sudo apt install amazon-cloudwatch-agent

# Configure to send Rails logs
```

### Health Checks
```bash
# Add health check endpoint
# config/routes.rb
get '/health', to: 'application#health'

# app/controllers/application_controller.rb
def health
  render json: { status: 'ok', timestamp: Time.current }
end
```

---

## Cost Optimization

1. **Free Tier**: Use t2.micro and RDS free tier
2. **Reserved Instances**: Save up to 60% on EC2
3. **Auto Scaling**: Scale based on traffic
4. **S3 Lifecycle**: Move old assets to Glacier

---

## Quick EC2 Deploy Script

```bash
#!/bin/bash
# aws-quick-deploy.sh

# Set variables
EC2_IP="your-ec2-ip"
KEY_FILE="your-key.pem"

# Deploy to EC2
ssh -i $KEY_FILE ubuntu@$EC2_IP << 'EOF'
cd ~/bookmyticket
git pull origin main
bundle install
rails db:migrate RAILS_ENV=production
rails assets:precompile RAILS_ENV=production
sudo systemctl restart bookmyticket
EOF

echo "Deployment complete!"
```

Choose the option that fits your budget and technical comfort level. EC2 gives you most control, Elastic Beanstalk is easiest, App Runner is most modern.
