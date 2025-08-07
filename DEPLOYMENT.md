# 🚗 AutoMax Car Dealership - Deployment Guide

## 🔄 CI/CD Pipeline Deployment (Recommended)

This project uses **GitHub Actions** for automated deployment following DevOps best practices.

### Prerequisites ✅
- [x] GitHub repository created
- [x] GitHub Secrets configured:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `SLACK_WEBHOOK_URL` (optional)

### Deployment Steps 🚀

#### 1. **Push Code to GitHub**
```bash
# Initialize git repository (if not already done)
git init

# Add GitHub remote
git remote add origin https://github.com/YOUR_USERNAME/automax-dealership.git

# Add all files
git add .

# Commit changes
git commit -m "🚀 Initial deployment: AutoMax Car Dealership with DevOps pipeline"

# Push to main branch (triggers CI/CD)
git push origin main
```

#### 2. **Monitor Pipeline Execution**
- Go to your GitHub repository
- Click on **"Actions"** tab
- Watch the pipeline progress:
  - ✅ Test & Quality Checks
  - ✅ Build & Push Docker Image  
  - ✅ Deploy Infrastructure
  - ✅ Deploy Application
  - ✅ Notify Deployment Status

#### 3. **Access Your Application**
After successful deployment:
- Check pipeline output for **Load Balancer DNS**
- Application will be available at: `http://YOUR-ALB-DNS.amazonaws.com`

## 🏗️ What the Pipeline Does

### **Stage 1: Code Quality & Testing** 🧪
```yaml
- HTML/CSS/JS Linting
- Automated website tests
- Security vulnerability checks
```

### **Stage 2: Container Build** 🐳
```yaml
- Build Docker image
- Multi-architecture support (AMD64/ARM64)
- Push to Amazon ECR
- Container security scanning
```

### **Stage 3: Infrastructure Deployment** 🏗️
```yaml
- Terraform plan & apply
- Create AWS resources:
  - VPC with public/private subnets
  - Application Load Balancer
  - ECS Fargate cluster
  - ECR repository
  - CloudWatch logging
  - Auto Scaling
  - Security Groups
```

### **Stage 4: Application Deployment** 🚀
```yaml
- Update ECS service
- Deploy new container version
- Health check validation
- Rolling deployment strategy
```

### **Stage 5: Post-Deployment** 📊
```yaml
- Smoke tests
- Slack notifications
- Monitoring setup
```

## 📋 Pipeline Configuration Details

### **Triggers**
- **Push to main**: Full deployment
- **Pull Request**: Testing only
- **Manual**: GitHub Actions manual trigger

### **AWS Resources Created**
| Resource | Purpose | Configuration |
|----------|---------|---------------|
| VPC | Network isolation | 10.0.0.0/16 |
| ALB | Load balancing | HTTP/HTTPS |
| ECS Fargate | Container hosting | Auto-scaling |
| ECR | Container registry | Image scanning |
| CloudWatch | Monitoring & logs | 30-day retention |

### **Security Features**
- ✅ Private subnets for applications
- ✅ Security groups with least privilege
- ✅ Container vulnerability scanning
- ✅ IAM roles with minimal permissions
- ✅ Encrypted container registry

## 🔧 Customization

### **Environment Variables** (GitHub Repository Settings > Secrets)
```bash
# Required
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# Optional
SLACK_WEBHOOK_URL=your_slack_webhook
```

### **Terraform Variables** (modify `terraform/variables.tf`)
```hcl
# Change these values as needed
variable "aws_region" {
  default = "us-east-1"  # Change region
}

variable "ecs_desired_count" {
  default = 2  # Number of containers
}

variable "ecs_max_capacity" {
  default = 10  # Max auto-scaling
}
```

## 🐛 Troubleshooting

### **Pipeline Fails at Infrastructure Stage**
- Check AWS credentials in GitHub Secrets
- Verify AWS permissions (EC2, ECS, VPC, ECR, CloudWatch)
- Review Terraform logs in Actions tab

### **Pipeline Fails at Container Build**
- Check Dockerfile syntax
- Verify container builds locally: `docker build -t automax .`
- Check ECR repository permissions

### **Application Not Accessible**
- Wait 5-10 minutes for ALB to become active
- Check ECS service health in AWS console
- Verify security group rules allow HTTP traffic

## 📊 Monitoring After Deployment

### **AWS Console Checks**
1. **ECS**: Check service status and running tasks
2. **ALB**: Verify target group health
3. **CloudWatch**: Monitor logs and metrics
4. **ECR**: Confirm image was pushed

### **Application Health**
```bash
# Get ALB DNS from pipeline output or AWS console
curl http://YOUR-ALB-DNS/health

# Should return: "healthy"
```

## 🚀 Benefits of Pipeline Deployment

### **DevOps Best Practices** ✅
- **GitOps**: Infrastructure as Code
- **Automation**: Zero manual deployment steps
- **Testing**: Automated quality checks
- **Security**: Vulnerability scanning
- **Monitoring**: Built-in observability

### **Enterprise Features** ✅
- **Rollback**: Easy rollback via git revert
- **Auditing**: Full deployment history
- **Notifications**: Slack integration
- **Scaling**: Auto-scaling capabilities
- **High Availability**: Multi-AZ deployment

---

## 🎯 Quick Commands

```bash
# Deploy latest changes
git add .
git commit -m "Update: description of changes"
git push origin main

# Check deployment status
gh run list  # (requires GitHub CLI)

# View logs
gh run view --log  # (requires GitHub CLI)
```

**🎉 Your AutoMax Car Dealership will be live on AWS with enterprise-grade DevOps practices!**
