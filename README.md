# 🚗 AutoMax Car Dealership - Cloud-Ready DevOps Project

A modern, responsive car dealership website with enterprise-grade CI/CD pipeline and AWS cloud deployment.

## 🏗️ Architecture Overview

```
Developer Push → GitHub → CI/CD Pipeline → AWS ECS Fargate
     │              │           │              │
     │              │           ├── Tests      ├── Application Load Balancer
     │              │           ├── Build      ├── Auto Scaling
     │              │           ├── Docker     ├── CloudWatch Monitoring
     │              │           └── Deploy     └── ECR Registry
```

## 📦 Project Structure

```
automax-dealership/
├── 🐳 Docker & Container
│   ├── Dockerfile              # Multi-stage container build
│   ├── nginx.conf              # Optimized web server config
│   └── .dockerignore           # Container build optimization
│
├── � CI/CD Pipeline
│   └── .github/workflows/
│       └── ci-cd.yml           # Complete automation pipeline
│
├── 🏗️ Infrastructure as Code
│   └── terraform/
│       ├── main.tf             # AWS infrastructure
│       ├── variables.tf        # Configuration variables
│       └── outputs.tf          # Resource outputs
│
├── 🧪 Testing & Quality
│   └── tests/
│       └── test_website.py     # Automated test suite
│
├── 🌐 Application Files
│   ├── index.html              # Main website
│   ├── styles.css              # Responsive styling
│   ├── script.js               # Interactive functionality
│   └── requirements.txt        # Python dependencies
│
└── 📋 Documentation
    ├── README.md               # This file
    └── package.json            # NPM configuration
```

## 🚀 Quick Start

### Prerequisites
- **Node.js** (v16+)
- **Docker** (v20+)
- **AWS CLI** (v2+)
- **Terraform** (v1.6+)
- **Git**

### Local Development

1. **Clone & Install:**
   ```bash
   git clone <repository-url>
   cd automax-dealership
   npm install
   ```

2. **Start Development Server:**
   ```bash
   npm run dev      # Live reload server
   npm start        # Basic HTTP server
   ```

3. **Run Tests:**
   ```bash
   python -m pytest tests/ -v
   ```

4. **Build Container:**
   ```bash
   docker build -t automax-dealership .
   docker run -p 8080:80 automax-dealership
   ```

## 🌥️ Cloud Deployment

### AWS Infrastructure Components

| Component | Purpose | Configuration |
|-----------|---------|---------------|
| **VPC** | Network isolation | 10.0.0.0/16 CIDR |
| **ALB** | Load balancing | HTTP/HTTPS traffic |
| **ECS Fargate** | Container hosting | Auto-scaling enabled |
| **ECR** | Container registry | Image scanning enabled |
| **CloudWatch** | Monitoring & logs | 30-day retention |
| **IAM** | Security & permissions | Least privilege |

### Deployment Pipeline

#### 🔄 **CI/CD Workflow**

1. **Code Quality & Testing** 🧪
   - HTML/CSS/JS linting
   - Automated testing suite
   - Security vulnerability scanning

2. **Container Build & Push** 🐳
   - Multi-architecture Docker build
   - Push to Amazon ECR
   - Container vulnerability scanning

3. **Infrastructure Deployment** 🏗️
   - Terraform infrastructure provisioning
   - AWS resource creation/updates
   - Security group configuration

4. **Application Deployment** 🚀
   - ECS service update
   - Rolling deployment strategy
   - Health check validation

5. **Post-Deployment** 📊
   - Smoke tests
   - Monitoring setup
   - Slack notifications

### Manual Deployment Steps

#### 1. **Setup AWS Infrastructure**

```bash
# Navigate to Terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan infrastructure changes
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan
```

#### 2. **Build & Deploy Application**

```bash
# Configure AWS CLI
aws configure

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push image
docker build -t automax-dealership .
docker tag automax-dealership:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/automax-dealership:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/automax-dealership:latest

# Update ECS service
aws ecs update-service --cluster automax-cluster --service automax-service --force-new-deployment
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AWS_REGION` | AWS deployment region | `us-east-1` |
| `ENVIRONMENT` | Deployment environment | `production` |
| `ECS_DESIRED_COUNT` | Number of running tasks | `2` |

### GitHub Secrets Required

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID       # AWS access key
AWS_SECRET_ACCESS_KEY   # AWS secret key

# Notifications (Optional)
SLACK_WEBHOOK_URL       # Slack webhook for notifications
```

## 📊 Monitoring & Observability

### CloudWatch Dashboards
- **Application Metrics**: Response time, error rates
- **Infrastructure Metrics**: CPU, memory, network
- **Custom Metrics**: Business KPIs

### Health Checks
- **Load Balancer**: `/health` endpoint
- **Container**: Internal health checks
- **Application**: Custom health monitoring

### Logging
- **Centralized Logging**: CloudWatch Logs
- **Log Retention**: 30 days
- **Log Analysis**: CloudWatch Insights

## � Security Features

### Infrastructure Security
- ✅ **VPC Isolation**: Private subnets for applications
- ✅ **Security Groups**: Restrictive network rules
- ✅ **IAM Roles**: Least privilege access
- ✅ **Encryption**: EBS and ECR encryption
- ✅ **HTTPS**: SSL/TLS termination at ALB

### Container Security
- ✅ **Non-root User**: Container runs as nginx user
- ✅ **Vulnerability Scanning**: Trivy security scans
- ✅ **Image Signing**: Container image verification
- ✅ **Resource Limits**: CPU and memory constraints

### Application Security
- ✅ **Security Headers**: XSS, CSRF protection
- ✅ **Content Security Policy**: Script injection prevention
- ✅ **Input Validation**: Form data sanitization

## 🚀 Performance Optimizations

### Frontend Optimizations
- **Gzip Compression**: Reduced payload sizes
- **Static Asset Caching**: Browser and CDN caching
- **Image Optimization**: Compressed images
- **Minification**: CSS and JS minification

### Infrastructure Optimizations
- **Auto Scaling**: Horizontal scaling based on CPU
- **Multi-AZ Deployment**: High availability
- **CloudFront CDN**: Global content distribution
- **Connection Pooling**: Optimized connections

## 🧪 Testing Strategy

### Automated Tests
```bash
# Unit Tests
pytest tests/test_website.py -v

# Integration Tests
pytest tests/test_integration.py -v

# Load Tests
artillery run loadtest.yml

# Security Tests
trivy image automax-dealership:latest
```

### Test Coverage
- ✅ **Functional Testing**: Core functionality
- ✅ **Performance Testing**: Load and stress tests
- ✅ **Security Testing**: Vulnerability assessments
- ✅ **Accessibility Testing**: WCAG compliance

## 📈 Scaling & Performance

### Horizontal Scaling
- **Auto Scaling**: 1-10 instances based on CPU
- **Load Balancing**: Traffic distribution
- **Database Scaling**: Read replicas (future)

### Vertical Scaling
- **Resource Allocation**: CPU and memory tuning
- **Performance Monitoring**: CloudWatch metrics
- **Optimization**: Continuous performance tuning

## 🔄 CI/CD Best Practices

### GitOps Workflow
1. **Feature Branch**: Development on feature branches
2. **Pull Request**: Code review process
3. **Automated Testing**: CI pipeline validation
4. **Deployment**: Automated deployment to production
5. **Monitoring**: Post-deployment monitoring

### Deployment Strategies
- **Rolling Deployment**: Zero-downtime updates
- **Blue-Green**: Future enhancement
- **Canary**: Future enhancement
- **Feature Flags**: Future enhancement

## 🛠️ Troubleshooting

### Common Issues

#### Container Issues
```bash
# Check container logs
docker logs <container-id>

# Debug container
docker exec -it <container-id> sh
```

#### ECS Issues
```bash
# Check service status
aws ecs describe-services --cluster automax-cluster --services automax-service

# View task logs
aws logs get-log-events --log-group-name /ecs/automax-dealership
```

#### Terraform Issues
```bash
# Check state
terraform show

# Refresh state
terraform refresh

# Plan with debug
TF_LOG=DEBUG terraform plan
```

## 📚 Additional Resources

### Documentation
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Monitoring Tools
- [AWS CloudWatch](https://aws.amazon.com/cloudwatch/)
- [AWS X-Ray](https://aws.amazon.com/xray/)
- [Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 📞 Support

- **Email**: devops@automax.com
- **Phone**: (555) 123-AUTO
- **Documentation**: [Wiki](./docs/)
- **Issues**: [GitHub Issues](./issues)

---

**Built with ❤️ by the AutoMax DevOps Team**

*This project demonstrates enterprise-grade DevOps practices for modern web applications.*
