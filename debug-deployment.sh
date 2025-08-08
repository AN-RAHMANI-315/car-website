#!/bin/bash

# AutoMax Car Dealership - Deployment Debugging Script
# This script helps diagnose issues when the load balancer shows no content

set -e

echo "🔍 AutoMax Car Dealership - Deployment Debugging"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="automax-dealership"
CLUSTER_NAME="${PROJECT_NAME}-cluster"
SERVICE_NAME="${PROJECT_NAME}-service"
ALB_NAME="${PROJECT_NAME}-alb"
TARGET_GROUP_NAME="${PROJECT_NAME}-tg"
REGION="us-east-1"

echo "🔧 Configuration:"
echo "  Project: $PROJECT_NAME"
echo "  Cluster: $CLUSTER_NAME"
echo "  Service: $SERVICE_NAME"
echo "  ALB: $ALB_NAME"
echo "  Target Group: $TARGET_GROUP_NAME"
echo "  Region: $REGION"
echo ""

# Function to check if AWS CLI is configured
check_aws_cli() {
    echo -e "${BLUE}🔍 Checking AWS CLI configuration...${NC}"
    if ! aws sts get-caller-identity &>/dev/null; then
        echo -e "${RED}❌ AWS CLI not configured or credentials invalid${NC}"
        echo "💡 Please run: aws configure"
        echo "   Or set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
        exit 1
    else
        ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
        echo -e "${GREEN}✅ AWS CLI configured for account: $ACCOUNT_ID${NC}"
    fi
    echo ""
}

# Function to check Load Balancer status
check_load_balancer() {
    echo -e "${BLUE}🔍 Checking Load Balancer status...${NC}"
    
    LB_INFO=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --region "$REGION" 2>/dev/null || echo "")
    
    if [ -z "$LB_INFO" ]; then
        echo -e "${RED}❌ Load Balancer not found: $ALB_NAME${NC}"
        echo "💡 Check if Terraform deployment completed successfully"
        return 1
    fi
    
    LB_DNS=$(echo "$LB_INFO" | jq -r '.LoadBalancers[0].DNSName')
    LB_STATE=$(echo "$LB_INFO" | jq -r '.LoadBalancers[0].State.Code')
    LB_SCHEME=$(echo "$LB_INFO" | jq -r '.LoadBalancers[0].Scheme')
    
    echo -e "${GREEN}✅ Load Balancer found:${NC}"
    echo "  DNS: $LB_DNS"
    echo "  State: $LB_STATE"
    echo "  Scheme: $LB_SCHEME"
    
    if [ "$LB_STATE" != "active" ]; then
        echo -e "${YELLOW}⚠️  Load Balancer is not active${NC}"
        echo "💡 Wait for Load Balancer to become active before testing"
    fi
    
    echo "🌐 Website URL: http://$LB_DNS"
    echo ""
}

# Function to check Target Group health
check_target_group() {
    echo -e "${BLUE}🔍 Checking Target Group health...${NC}"
    
    TG_ARN=$(aws elbv2 describe-target-groups --names "$TARGET_GROUP_NAME" --region "$REGION" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
    
    if [ -z "$TG_ARN" ] || [ "$TG_ARN" == "None" ]; then
        echo -e "${RED}❌ Target Group not found: $TARGET_GROUP_NAME${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Target Group found: $TARGET_GROUP_NAME${NC}"
    echo "  ARN: $TG_ARN"
    
    # Check target health
    echo ""
    echo -e "${BLUE}🔍 Checking target health...${NC}"
    TARGET_HEALTH=$(aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --region "$REGION" 2>/dev/null || echo "")
    
    if [ -z "$TARGET_HEALTH" ]; then
        echo -e "${RED}❌ Could not retrieve target health${NC}"
        return 1
    fi
    
    # Parse target health
    TARGETS=$(echo "$TARGET_HEALTH" | jq -r '.TargetHealthDescriptions[] | "\(.Target.Id):\(.Target.Port) - \(.TargetHealth.State) - \(.TargetHealth.Description // "No description")"')
    
    if [ -z "$TARGETS" ]; then
        echo -e "${YELLOW}⚠️  No targets registered in Target Group${NC}"
        echo "💡 This is likely the cause of the empty load balancer"
        echo "💡 ECS tasks should automatically register as targets"
        return 1
    else
        echo -e "${GREEN}✅ Targets found:${NC}"
        echo "$TARGETS"
        
        # Check if any targets are healthy
        HEALTHY_COUNT=$(echo "$TARGET_HEALTH" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State == "healthy")] | length')
        UNHEALTHY_COUNT=$(echo "$TARGET_HEALTH" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State != "healthy")] | length')
        
        echo ""
        echo "📊 Target Health Summary:"
        echo "  Healthy: $HEALTHY_COUNT"
        echo "  Unhealthy: $UNHEALTHY_COUNT"
        
        if [ "$HEALTHY_COUNT" -eq 0 ]; then
            echo -e "${RED}❌ No healthy targets - this is why the load balancer shows no content${NC}"
            echo "💡 Check ECS task health and container logs"
        fi
    fi
    echo ""
}

# Function to check ECS Cluster
check_ecs_cluster() {
    echo -e "${BLUE}🔍 Checking ECS Cluster...${NC}"
    
    CLUSTER_INFO=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$REGION" 2>/dev/null || echo "")
    
    if [ -z "$CLUSTER_INFO" ]; then
        echo -e "${RED}❌ ECS Cluster not found: $CLUSTER_NAME${NC}"
        return 1
    fi
    
    CLUSTER_STATUS=$(echo "$CLUSTER_INFO" | jq -r '.clusters[0].status')
    ACTIVE_CAPACITY=$(echo "$CLUSTER_INFO" | jq -r '.clusters[0].activeServicesCount')
    RUNNING_TASKS=$(echo "$CLUSTER_INFO" | jq -r '.clusters[0].runningTasksCount')
    
    echo -e "${GREEN}✅ ECS Cluster found:${NC}"
    echo "  Status: $CLUSTER_STATUS"
    echo "  Active Services: $ACTIVE_CAPACITY"
    echo "  Running Tasks: $RUNNING_TASKS"
    echo ""
}

# Function to check ECS Service
check_ecs_service() {
    echo -e "${BLUE}🔍 Checking ECS Service...${NC}"
    
    SERVICE_INFO=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --region "$REGION" 2>/dev/null || echo "")
    
    if [ -z "$SERVICE_INFO" ]; then
        echo -e "${RED}❌ ECS Service not found: $SERVICE_NAME${NC}"
        return 1
    fi
    
    SERVICE_STATUS=$(echo "$SERVICE_INFO" | jq -r '.services[0].status')
    DESIRED_COUNT=$(echo "$SERVICE_INFO" | jq -r '.services[0].desiredCount')
    RUNNING_COUNT=$(echo "$SERVICE_INFO" | jq -r '.services[0].runningCount')
    PENDING_COUNT=$(echo "$SERVICE_INFO" | jq -r '.services[0].pendingCount')
    
    echo -e "${GREEN}✅ ECS Service found:${NC}"
    echo "  Status: $SERVICE_STATUS"
    echo "  Desired: $DESIRED_COUNT"
    echo "  Running: $RUNNING_COUNT"
    echo "  Pending: $PENDING_COUNT"
    
    if [ "$RUNNING_COUNT" -eq 0 ]; then
        echo -e "${RED}❌ No running tasks - this is why the load balancer shows no content${NC}"
        echo "💡 Check task definition and service events"
    fi
    
    # Check service events for errors
    echo ""
    echo -e "${BLUE}🔍 Recent service events:${NC}"
    EVENTS=$(echo "$SERVICE_INFO" | jq -r '.services[0].events[0:5][] | "\(.createdAt) - \(.message)"')
    echo "$EVENTS"
    echo ""
}

# Function to check ECS Tasks
check_ecs_tasks() {
    echo -e "${BLUE}🔍 Checking ECS Tasks...${NC}"
    
    TASK_ARNS=$(aws ecs list-tasks --cluster "$CLUSTER_NAME" --service-name "$SERVICE_NAME" --region "$REGION" --query 'taskArns' --output text 2>/dev/null || echo "")
    
    if [ -z "$TASK_ARNS" ] || [ "$TASK_ARNS" == "None" ]; then
        echo -e "${RED}❌ No tasks found for service: $SERVICE_NAME${NC}"
        echo "💡 Check why ECS tasks are not starting"
        return 1
    fi
    
    echo -e "${GREEN}✅ Tasks found, getting details...${NC}"
    
    # Get task details
    TASK_DETAILS=$(aws ecs describe-tasks --cluster "$CLUSTER_NAME" --tasks $TASK_ARNS --region "$REGION" 2>/dev/null || echo "")
    
    if [ -z "$TASK_DETAILS" ]; then
        echo -e "${RED}❌ Could not retrieve task details${NC}"
        return 1
    fi
    
    # Parse task information
    echo "$TASK_DETAILS" | jq -r '.tasks[] | "Task: \(.taskArn | split("/") | last) - Status: \(.lastStatus) - Health: \(.healthStatus // "Unknown")"'
    
    # Check for stopped tasks with stop reasons
    STOPPED_TASKS=$(echo "$TASK_DETAILS" | jq -r '.tasks[] | select(.lastStatus == "STOPPED") | "STOPPED: \(.stoppedReason // "Unknown reason")"')
    if [ ! -z "$STOPPED_TASKS" ]; then
        echo ""
        echo -e "${RED}❌ Stopped tasks found:${NC}"
        echo "$STOPPED_TASKS"
    fi
    
    echo ""
}

# Function to test load balancer connectivity
test_connectivity() {
    echo -e "${BLUE}🔍 Testing Load Balancer connectivity...${NC}"
    
    LB_DNS=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --region "$REGION" --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null || echo "")
    
    if [ -z "$LB_DNS" ] || [ "$LB_DNS" == "None" ]; then
        echo -e "${RED}❌ Could not get Load Balancer DNS${NC}"
        return 1
    fi
    
    echo "🌐 Testing: http://$LB_DNS"
    
    # Test root path
    echo "  Testing root path (/)..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$LB_DNS/" --connect-timeout 10 --max-time 30 || echo "000")
    echo "    HTTP Status: $HTTP_STATUS"
    
    if [ "$HTTP_STATUS" == "200" ]; then
        echo -e "${GREEN}    ✅ Root path responding successfully${NC}"
    else
        echo -e "${RED}    ❌ Root path not responding properly${NC}"
    fi
    
    # Test health endpoint
    echo "  Testing health endpoint (/health)..."
    HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$LB_DNS/health" --connect-timeout 10 --max-time 30 || echo "000")
    echo "    HTTP Status: $HEALTH_STATUS"
    
    if [ "$HEALTH_STATUS" == "200" ]; then
        echo -e "${GREEN}    ✅ Health endpoint responding successfully${NC}"
    else
        echo -e "${RED}    ❌ Health endpoint not responding properly${NC}"
    fi
    
    # Get response content for debugging
    echo "  Getting response content..."
    RESPONSE=$(curl -s "http://$LB_DNS/" --connect-timeout 10 --max-time 30 | head -c 200 || echo "No response")
    echo "    First 200 chars: $RESPONSE"
    
    echo ""
}

# Function to provide troubleshooting recommendations
provide_recommendations() {
    echo -e "${YELLOW}💡 TROUBLESHOOTING RECOMMENDATIONS:${NC}"
    echo "============================================"
    echo ""
    
    echo "1. 🔍 Check ECS Task Logs:"
    echo "   aws logs get-log-events --log-group-name '/ecs/$PROJECT_NAME' --log-stream-name 'ecs/automax-container/\$(TASK_ID)' --region $REGION"
    echo ""
    
    echo "2. 🔄 Force new deployment:"
    echo "   aws ecs update-service --cluster '$CLUSTER_NAME' --service '$SERVICE_NAME' --force-new-deployment --region $REGION"
    echo ""
    
    echo "3. 🏥 Check task health manually:"
    echo "   # Get task private IP"
    echo "   aws ecs describe-tasks --cluster '$CLUSTER_NAME' --tasks \$(aws ecs list-tasks --cluster '$CLUSTER_NAME' --service-name '$SERVICE_NAME' --query 'taskArns[0]' --output text) --query 'tasks[0].attachments[0].details[?name==\"privateIPv4Address\"].value' --output text --region $REGION"
    echo ""
    
    echo "4. 🔧 Check security groups:"
    echo "   - Ensure ALB security group allows inbound traffic on port 80"
    echo "   - Ensure ECS security group allows inbound traffic from ALB on port 80"
    echo ""
    
    echo "5. 🌐 Check subnet configuration:"
    echo "   - Ensure ECS tasks are in public subnets with auto-assign public IP"
    echo "   - Ensure subnets have routes to Internet Gateway"
    echo ""
    
    echo "6. 📋 Verify task definition:"
    echo "   - Container port 80 is exposed"
    echo "   - Health check is properly configured"
    echo "   - Container is not crashing on startup"
    echo ""
    
    echo "7. 🔄 If all else fails, restart infrastructure:"
    echo "   cd terraform && terraform destroy -auto-approve && terraform apply -auto-approve"
    echo ""
}

# Main execution
main() {
    check_aws_cli
    check_load_balancer
    check_target_group
    check_ecs_cluster
    check_ecs_service
    check_ecs_tasks
    test_connectivity
    provide_recommendations
    
    echo -e "${BLUE}🎯 Debugging complete!${NC}"
    echo "If the issue persists, check the ECS task logs and consider redeploying."
}

# Run main function
main
