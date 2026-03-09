# EC2 AWS Credentials Setup for Poster Display

## Quick Fix Steps

### 1. Set AWS Credentials (Run these commands on EC2)

```bash
# Method 1: Using AWS CLI (Recommended)
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json

# Method 2: Set Environment Variables
export AWS_ACCESS_KEY_ID="your_access_key_here"
export AWS_SECRET_ACCESS_KEY="your_secret_key_here"
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Set Rails Environment Variables

```bash
export RAILS_ENV=production
export RAILS_MASTER_KEY="your_master_key_here"
export DATABASE_URL="postgresql://bookmyticket:your_db_password@localhost/bookmyticket_production"
```

### 3. Precompile Assets

```bash
rails assets:precompile
```

### 4. Database Setup

```bash
rails db:migrate RAILS_ENV=production
```

### 5. Start Server

```bash
rails server -b 0.0.0.0 -p 3000 -e production
```

## Alternative: Use IAM Role (Best for EC2)

1. Go to AWS Console → EC2 → Select your instance
2. Actions → Security → Modify IAM role
3. Create/attach IAM role with S3 access policy
4. Restart your Rails app

## Test Poster Display

Visit: `http://your-ec2-ip:3000/movies`

Posters should now display using:
- Real poster URLs if available in database
- Fallback SVG data URIs if no poster URL exists

## Troubleshooting

If posters still don't show:

1. Check AWS credentials: `aws s3 ls`
2. Check Rails logs: `tail -f log/production.log`
3. Verify database connection: `rails console RAILS_ENV=production`
