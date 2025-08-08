#!/bin/bash

# resolve-alb-conflict.sh
# Script to resolve "ELBv2 Load Balancer already exists" conflicts
# This addresses the recurring issue where ALB exists in AWS but not in Terraform state

set -e

echo "🔧 ALB Conflict Resolution Script"
echo "================================="

# Configuration
PROJECT_NAME="automax-dealership"
ALB_NAME="${PROJECT_NAME}-alb"
TG_NAME="${PROJECT_NAME}-tg"

# Function to check if resource exists in Terraform state
check_tf_state() {
    local resource=$1
    if terraform state show "$resource" &>/dev/null; then
        echo "✅ $resource already in Terraform state"
        return 0
    else
        echo "❌ $resource NOT in Terraform state"
        return 1
    fi
}

# Function to clean up orphaned resources
cleanup_orphaned_resources() {
    echo "🧹 Cleaning up any orphaned resources that might cause conflicts..."
    
    # Check for orphaned Target Groups first
    echo "🔍 Checking for orphaned Target Groups..."
    local tg_arn
    tg_arn=$(aws elbv2 describe-target-groups --names "$TG_NAME" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
    
    if [ "$tg_arn" != "" ] && [ "$tg_arn" != "None" ]; then
        # Check if Target Group is associated with any ALB
        local associated_albs
        associated_albs=$(aws elbv2 describe-target-groups --target-group-arns "$tg_arn" --query 'TargetGroups[0].LoadBalancerArns' --output text 2>/dev/null || echo "")
        
        if [ "$associated_albs" = "" ] || [ "$associated_albs" = "None" ] || [ "$associated_albs" = "[]" ]; then
            echo "🔄 Found orphaned Target Group (not associated with any ALB): $tg_arn"
            echo "🗑️ Deleting orphaned Target Group..."
            
            if aws elbv2 delete-target-group --target-group-arn "$tg_arn" 2>/dev/null; then
                echo "✅ Orphaned Target Group deleted"
                sleep 10
            else
                echo "⚠️ Failed to delete orphaned Target Group"
            fi
        else
            echo "ℹ️ Target Group is associated with ALB(s): $associated_albs"
        fi
    else
        echo "ℹ️ No Target Group found with name: $TG_NAME"
    fi
}

# Function to safely import or remove resource
handle_alb_conflict() {
    echo "🔍 Checking for ALB conflict..."
    
    # Check if ALB exists in Terraform state
    if check_tf_state "aws_lb.main"; then
        echo "✅ ALB already managed by Terraform, no action needed"
        return 0
    fi
    
    # Check if ALB exists in AWS
    local lb_arn
    lb_arn=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
    
    if [ "$lb_arn" != "" ] && [ "$lb_arn" != "None" ]; then
        echo "⚠️ ALB exists in AWS but not in Terraform state: $lb_arn"
        echo "🔄 This is the root cause of the 'already exists' error"
        
        # Option 1: Try to import the ALB
        echo "🔄 Attempting to import existing ALB into Terraform state..."
        if terraform import 'aws_lb.main' "$ALB_NAME" 2>/dev/null; then
            echo "✅ Successfully imported ALB into Terraform state"
            
            # Also try to import related resources
            import_related_resources "$lb_arn"
            return 0
        else
            echo "❌ ALB import failed"
            
            # Option 2: Remove the conflicting ALB
            echo "🗑️ Removing existing ALB to prevent conflict..."
            remove_existing_alb "$lb_arn"
            return 0
        fi
    else
        echo "✅ No ALB conflict detected"
        return 0
    fi
}

# Function to import related resources
import_related_resources() {
    local lb_arn=$1
    
    echo "🔄 Attempting to import related resources..."
    
    # Import target group
    local tg_arn
    tg_arn=$(aws elbv2 describe-target-groups --names "$TG_NAME" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
    if [ "$tg_arn" != "" ] && [ "$tg_arn" != "None" ]; then
        if ! check_tf_state "aws_lb_target_group.main"; then
            echo "🔄 Importing target group..."
            if terraform import 'aws_lb_target_group.main' "$tg_arn" 2>/dev/null; then
                echo "✅ Target group imported"
            else
                echo "❌ Target group import failed"
                echo "🔄 Checking if Target Group is orphaned or misconfigured..."
                
                # If import fails, it might be orphaned or misconfigured
                # Delete it so Terraform can create a new one
                echo "🗑️ Deleting problematic Target Group to allow fresh creation..."
                if aws elbv2 delete-target-group --target-group-arn "$tg_arn" 2>/dev/null; then
                    echo "✅ Problematic Target Group deleted"
                    sleep 10
                else
                    echo "⚠️ Failed to delete Target Group"
                fi
            fi
        fi
    fi
    
    # Import listener
    local listener_arn
    listener_arn=$(aws elbv2 describe-listeners --load-balancer-arn "$lb_arn" --query 'Listeners[0].ListenerArn' --output text 2>/dev/null || echo "")
    if [ "$listener_arn" != "" ] && [ "$listener_arn" != "None" ]; then
        if ! check_tf_state "aws_lb_listener.main"; then
            echo "🔄 Importing listener..."
            terraform import 'aws_lb_listener.main' "$listener_arn" 2>/dev/null && echo "✅ Listener imported" || echo "⚠️ Listener import failed"
        fi
    fi
}

# Function to remove existing ALB and related resources
remove_existing_alb() {
    local lb_arn=$1
    
    echo "🗑️ Removing existing ALB and ALL related resources to resolve conflict..."
    
    # Get and delete all listeners first
    local listeners
    listeners=$(aws elbv2 describe-listeners --load-balancer-arn "$lb_arn" --query 'Listeners[].ListenerArn' --output text 2>/dev/null || echo "")
    
    if [ "$listeners" != "" ]; then
        echo "🔄 Deleting listeners..."
        for listener in $listeners; do
            if aws elbv2 delete-listener --listener-arn "$listener" 2>/dev/null; then
                echo "✅ Deleted listener: $listener"
            else
                echo "⚠️ Failed to delete listener: $listener"
            fi
        done
        sleep 10
    fi
    
    # Delete the ALB
    echo "🔄 Deleting ALB..."
    if aws elbv2 delete-load-balancer --load-balancer-arn "$lb_arn" 2>/dev/null; then
        echo "✅ ALB deletion initiated"
        
        # Wait for deletion to complete
        echo "⏳ Waiting for ALB deletion to complete..."
        local max_wait=180
        local wait_time=0
        
        while [ $wait_time -lt $max_wait ]; do
            if ! aws elbv2 describe-load-balancers --names "$ALB_NAME" &>/dev/null; then
                echo "✅ ALB deletion confirmed"
                break
            fi
            sleep 10
            wait_time=$((wait_time + 10))
            echo "⏳ Still waiting... ($wait_time/${max_wait}s)"
        done
        
        # Clean up orphaned Target Groups after ALB deletion
        echo "🧹 Cleaning up orphaned Target Groups..."
        local tg_arn
        tg_arn=$(aws elbv2 describe-target-groups --names "$TG_NAME" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
        
        if [ "$tg_arn" != "" ] && [ "$tg_arn" != "None" ]; then
            echo "🔄 Found orphaned Target Group after ALB deletion: $tg_arn"
            echo "🗑️ Deleting orphaned Target Group..."
            
            if aws elbv2 delete-target-group --target-group-arn "$tg_arn" 2>/dev/null; then
                echo "✅ Orphaned Target Group deleted"
                
                # Wait for Target Group deletion
                sleep 15
                echo "✅ Target Group cleanup completed"
            else
                echo "⚠️ Failed to delete orphaned Target Group"
            fi
        else
            echo "ℹ️ No orphaned Target Groups found"
        fi
        
        return 0
    else
        echo "❌ Failed to delete ALB"
        return 1
    fi
}

# Main execution
echo "🚀 Starting ALB conflict resolution..."

# Ensure we're in the right directory
if [ ! -f "main.tf" ]; then
    echo "❌ Error: main.tf not found. Run this script from the terraform directory."
    exit 1
fi

# Ensure Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# First, clean up any orphaned resources
cleanup_orphaned_resources

# Handle the ALB conflict
if handle_alb_conflict; then
    echo "✅ ALB conflict resolution completed successfully"
    echo "🎯 This should resolve the 'ELBv2 Load Balancer already exists' error"
else
    echo "❌ ALB conflict resolution failed"
    exit 1
fi

echo ""
echo "🎉 ALB Conflict Resolution Summary:"
echo "  - Checked for existing ALB in AWS and Terraform state"
echo "  - Either imported existing resources or removed conflicts"
echo "  - Terraform apply should now work without ALB conflicts"
echo ""
