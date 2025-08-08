#!/bin/bash

# AutoMax Car Dealership - Quick Fix Script
# This script attempts to fix common issues when load balancer shows no content

set -e

echo "🔧 AutoMax Car Dealership - Quick Fix"
echo "====================================="
echo ""

# Configuration
PROJECT_NAME="automax-dealership"
CLUSTER_NAME="${PROJECT_NAME}-cluster"
SERVICE_NAME="${PROJECT_NAME}-service"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎯 Attempting to fix common deployment issues...${NC}"
echo ""

# Function to check AWS CLI
check_aws_cli() {
    if ! aws sts get-caller-identity &>/dev/null; then
        echo -e "${RED}❌ AWS CLI not configured. Please run: aws configure${NC}"
        exit 1
    fi
}

# Function to force new ECS deployment
force_ecs_deployment() {
    echo -e "${BLUE}🔄 Forcing new ECS deployment...${NC}"
    
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --force-new-deployment \
        --region "$REGION" \
        &>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ New deployment triggered successfully${NC}"
        echo "⏳ Waiting for deployment to complete..."
        
        # Wait for service to stabilize
        aws ecs wait services-stable \
            --cluster "$CLUSTER_NAME" \
            --services "$SERVICE_NAME" \
            --region "$REGION"
        
        echo -e "${GREEN}✅ Service deployment completed${NC}"
    else
        echo -e "${RED}❌ Failed to trigger new deployment${NC}"
        return 1
    fi
}

# Function to check and fix task definition issues
check_task_definition() {
    echo -e "${BLUE}🔍 Checking task definition...${NC}"
    
    TASK_DEF_ARN=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --region "$REGION" \
        --query 'services[0].taskDefinition' \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$TASK_DEF_ARN" ]; then
        echo -e "${RED}❌ Could not get task definition${NC}"
        return 1
    fi
    
    echo "📋 Current task definition: $(basename "$TASK_DEF_ARN")"
    
    # Get task definition details to check container configuration
    TASK_DEF_DETAILS=$(aws ecs describe-task-definition \
        --task-definition "$TASK_DEF_ARN" \
        --region "$REGION" 2>/dev/null || echo "")
    
    if [ ! -z "$TASK_DEF_DETAILS" ]; then
        CONTAINER_PORT=$(echo "$TASK_DEF_DETAILS" | jq -r '.taskDefinition.containerDefinitions[0].portMappings[0].containerPort // "none"')
        echo "🔌 Container port: $CONTAINER_PORT"
        
        if [ "$CONTAINER_PORT" != "80" ]; then
            echo -e "${YELLOW}⚠️  Container port is not 80, this might cause issues${NC}"
        fi
    fi
}

# Function to restart tasks by scaling down and up
restart_tasks() {
    echo -e "${BLUE}🔄 Restarting ECS tasks...${NC}"
    
    # Get current desired count
    CURRENT_COUNT=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --region "$REGION" \
        --query 'services[0].desiredCount' \
        --output text 2>/dev/null || echo "0")
    
    echo "📊 Current desired count: $CURRENT_COUNT"
    
    if [ "$CURRENT_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Service already has 0 tasks, setting to 1${NC}"
        CURRENT_COUNT=1
    fi
    
    # Scale down to 0
    echo "📉 Scaling down to 0 tasks..."
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --desired-count 0 \
        --region "$REGION" \
        &>/dev/null
    
    # Wait for tasks to stop
    echo "⏳ Waiting for tasks to stop..."
    sleep 30
    
    # Scale back up
    echo "📈 Scaling back up to $CURRENT_COUNT tasks..."
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --desired-count "$CURRENT_COUNT" \
        --region "$REGION" \
        &>/dev/null
    
    echo -e "${GREEN}✅ Task restart initiated${NC}"
}

# Function to check and display load balancer URL
get_load_balancer_url() {
    echo -e "${BLUE}🌐 Getting Load Balancer URL...${NC}"
    
    LB_DNS=$(aws elbv2 describe-load-balancers \
        --names "${PROJECT_NAME}-alb" \
        --region "$REGION" \
        --query 'LoadBalancers[0].DNSName' \
        --output text 2>/dev/null || echo "")
    
    if [ ! -z "$LB_DNS" ] && [ "$LB_DNS" != "None" ]; then
        echo -e "${GREEN}✅ Load Balancer URL: http://$LB_DNS${NC}"
        echo ""
        echo -e "${BLUE}🔍 Testing connectivity in 30 seconds...${NC}"
        sleep 30
        
        # Test the URL
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$LB_DNS/" --connect-timeout 10 --max-time 30 || echo "000")
        
        if [ "$HTTP_STATUS" == "200" ]; then
            echo -e "${GREEN}✅ Website is responding! HTTP Status: $HTTP_STATUS${NC}"
        else
            echo -e "${YELLOW}⚠️  Website not yet responding. HTTP Status: $HTTP_STATUS${NC}"
            echo "💡 Please wait a few more minutes for the application to fully start"
        fi
    else
        echo -e "${RED}❌ Could not get Load Balancer DNS${NC}"
    fi
}

# Function to show debugging commands
show_debug_commands() {
    echo ""
    echo -e "${YELLOW}💡 If the issue persists, try these debugging commands:${NC}"
    echo ""
    echo "1. Check ECS service events:"
    echo "   aws ecs describe-services --cluster '$CLUSTER_NAME' --services '$SERVICE_NAME' --region '$REGION' --query 'services[0].events[0:5]'"
    echo ""
    echo "2. Check task logs:"
    echo "   aws logs tail '/ecs/$PROJECT_NAME' --follow --region '$REGION'"
    echo ""
    echo "3. Check target group health:"
    echo "   aws elbv2 describe-target-health --target-group-arn \$(aws elbv2 describe-target-groups --names '${PROJECT_NAME}-tg' --query 'TargetGroups[0].TargetGroupArn' --output text) --region '$REGION'"
    echo ""
    echo "4. Run full debugging:"
    echo "   ./debug-deployment.sh"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting quick fix process...${NC}"
    echo ""
    
    check_aws_cli
    check_task_definition
    force_ecs_deployment
    restart_tasks
    get_load_balancer_url
    show_debug_commands
    
    echo ""
    echo -e "${GREEN}🎉 Quick fix completed!${NC}"
    echo "🌐 Your website should be available shortly."
    echo "⏰ Allow 2-3 minutes for the application to fully initialize."
}

# Run main function
main
