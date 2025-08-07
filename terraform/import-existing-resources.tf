# Import block for existing resources
# This allows Terraform to manage existing AWS resources without recreating them

# Import existing Application Load Balancer if it exists
import {
  to = aws_lb.main
  id = "${var.project_name}-alb"
}

# Import existing Target Group if it exists  
import {
  to = aws_lb_target_group.main
  id = "${var.project_name}-tg"
}

# Import existing CloudWatch Log Group if it exists
import {
  to = aws_cloudwatch_log_group.ecs
  id = "/ecs/${var.project_name}"
}

# Import existing IAM roles if they exist
import {
  to = aws_iam_role.ecs_task_execution
  id = "${var.project_name}-ecs-task-execution-role"
}

import {
  to = aws_iam_role.ecs_task
  id = "${var.project_name}-ecs-task-role"
}
