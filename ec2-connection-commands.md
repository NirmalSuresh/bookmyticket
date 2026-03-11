# EC2 Connection Commands

## Your Specific Connection Command

### Direct Connection Command (Copy-Paste)
```bash
ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

### If key file is in Downloads folder
```bash
ssh -i ~/Downloads/your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

### Make key usable (if permission denied)
```bash
chmod 400 your-key.pem
```

## 1. Connect to EC2 Server via SSH

### Basic SSH Connection
```bash
ssh -i /path/to/your-key-pair.pem ec2-user@your-ec2-public-ip
```

### Example with placeholder values
```bash
ssh -i ~/Downloads/your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

### Alternative using IP address directly
```bash
ssh -i /path/to/your-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

## 2. Make Key Pair Usable (if needed)
```bash
chmod 400 /path/to/your-key-pair.pem
```

## 3. Connect with Specific User (depending on AMI)
```bash
# For Amazon Linux, CentOS, RHEL
ssh -i /path/to/key.pem ec2-user@YOUR_EC2_PUBLIC_IP

# For Ubuntu
ssh -i /path/to/key.pem ubuntu@YOUR_EC2_PUBLIC_IP

# For Debian
ssh -i /path/to/key.pem admin@YOUR_EC2_PUBLIC_IP
```

## 4. Port Forwarding (if needed)
```bash
ssh -i /path/to/key.pem -L 3000:localhost:3000 ec2-user@YOUR_EC2_PUBLIC_IP
```

## 5. Copy Files to/from EC2
```bash
# Copy file TO EC2
scp -i /path/to/key.pem local-file.txt ec2-user@YOUR_EC2_PUBLIC_IP:~/

# Copy file FROM EC2
scp -i /path/to/key.pem ec2-user@YOUR_EC2_PUBLIC_IP:~/remote-file.txt ./
```

## Required Information:
- **Key Pair Path**: Location of your .pem file
- **EC2 Public IP**: Your instance's public IP or DNS name
- **Username**: Usually `ec2-user` for Amazon Linux, `ubuntu` for Ubuntu

## Common Issues & Solutions:
1. **Permission denied**: Run `chmod 400 your-key.pem`
2. **Connection timeout**: Check security group allows SSH (port 22)
3. **Host key verification**: Add `-o StrictHostKeyChecking=no` for first connection (use with caution)
