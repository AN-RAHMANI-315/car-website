# 🔧 AutoMax Car Dealership - Load Balancer Troubleshooting Guide

## Issue: Load Balancer Shows No Content

When your deployment completes successfully but the load balancer shows no content or error pages, this usually indicates that the ECS tasks aren't healthy or aren't properly registering with the target group.

## 🚀 Quick Solutions

### 1. **Run the Quick Fix Script (Recommended)**
```bash
./quick-fix.sh
```
This script will:
- Force a new ECS deployment
- Restart ECS tasks
- Check target group health
- Test connectivity
- Provide the website URL

### 2. **Run Detailed Diagnostics**
```bash
./debug-deployment.sh
```
This script provides comprehensive debugging information about all components.

## 🔍 Manual Troubleshooting Steps

### Step 1: Check Target Group Health
```bash
# Get target group ARN
TG_ARN=$(aws elbv2 describe-target-groups --names automax-dealership-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

# Check target health
aws elbv2 describe-target-health --target-group-arn $TG_ARN
```

**Expected Output:**
- Should show registered targets (ECS task IPs)
- Targets should have `State: "healthy"`

**If No Targets:** ECS tasks aren't registering → Check ECS service configuration
**If Unhealthy Targets:** ECS tasks failing health checks → Check container logs

### Step 2: Check ECS Service Status
```bash
aws ecs describe-services --cluster automax-dealership-cluster --services automax-dealership-service
```

**Key Fields to Check:**
- `runningCount`: Should be > 0
- `desiredCount`: Should match runningCount
- `events`: Check for error messages

### Step 3: Check ECS Task Logs
```bash
# Get all log streams
aws logs describe-log-streams --log-group-name "/ecs/automax-dealership"

# Tail logs (replace TASK_ID with actual task ID)
aws logs tail "/ecs/automax-dealership" --follow
```

**Common Log Issues:**
- Container exit codes
- Port binding failures
- Health check failures
- Application startup errors

### Step 4: Check Security Groups
```bash
# Get ALB security group
ALB_SG=$(aws elbv2 describe-load-balancers --names automax-dealership-alb --query 'LoadBalancers[0].SecurityGroups[0]' --output text)

# Check ALB security group rules
aws ec2 describe-security-groups --group-ids $ALB_SG

# Get ECS security group
ECS_SG=$(aws ecs describe-services --cluster automax-dealership-cluster --services automax-dealership-service --query 'services[0].networkConfiguration.awsvpcConfiguration.securityGroups[0]' --output text)

# Check ECS security group rules
aws ec2 describe-security-groups --group-ids $ECS_SG
```

**Required Rules:**
- ALB SG: Inbound 80/443 from 0.0.0.0/0
- ECS SG: Inbound 80 from ALB SG

## 🔧 Common Fixes

### Fix 1: Force New Deployment
```bash
aws ecs update-service \
    --cluster automax-dealership-cluster \
    --service automax-dealership-service \
    --force-new-deployment
```

### Fix 2: Restart Tasks by Scaling
```bash
# Scale down to 0
aws ecs update-service \
    --cluster automax-dealership-cluster \
    --service automax-dealership-service \
    --desired-count 0

# Wait 30 seconds
sleep 30

# Scale back up to 1
aws ecs update-service \
    --cluster automax-dealership-cluster \
    --service automax-dealership-service \
    --desired-count 1
```

### Fix 3: Check Container Health Endpoint
```bash
# Get task private IP
TASK_IP=$(aws ecs describe-tasks \
    --cluster automax-dealership-cluster \
    --tasks $(aws ecs list-tasks --cluster automax-dealership-cluster --service-name automax-dealership-service --query 'taskArns[0]' --output text) \
    --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' \
    --output text)

# Test container directly (if in same VPC)
curl http://$TASK_IP:80/health
```

## 🚨 Emergency Reset

If nothing else works, reset the infrastructure:

```bash
cd terraform
terraform destroy -auto-approve
terraform apply -auto-approve
```

Then trigger a new deployment from GitHub Actions.

## 📊 Health Check Requirements

Your application must respond to:
- **Root path** (`/`): Should return HTTP 200
- **Health path** (`/health`): Should return HTTP 200 with "healthy" text

The nginx configuration already provides both endpoints.

## 🔍 Expected Behavior

After successful deployment:
1. **ECS Tasks**: 1 running task
2. **Target Group**: 1 healthy target
3. **Load Balancer**: Active state
4. **Website**: HTTP 200 responses

## 📞 Getting Help

If you're still experiencing issues:

1. **Check GitHub Actions logs** for deployment errors
2. **Review ECS task logs** for container issues
3. **Verify AWS Free Tier limits** haven't been exceeded
4. **Test locally** with `docker run` to isolate container issues

## 🔗 Useful AWS Console Links

- [ECS Clusters](https://console.aws.amazon.com/ecs/home#/clusters)
- [Load Balancers](https://console.aws.amazon.com/ec2/v2/home#LoadBalancers)
- [Target Groups](https://console.aws.amazon.com/ec2/v2/home#TargetGroups)
- [CloudWatch Logs](https://console.aws.amazon.com/cloudwatch/home#logsV2:log-groups)

---

**Remember:** After any changes, allow 2-3 minutes for the system to stabilize before testing.
