# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "automax-dealership"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Network Configuration (AWS Free Tier Optimized)
variable "vpc_cidr" {
  description = "CIDR block for VPC (Free Tier: VPCs are free)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (Free Tier: Single AZ to minimize costs)"
  type        = list(string)
  default     = ["10.0.1.0/24"]  # Single subnet for free tier
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (Disabled for free tier - no NAT costs)"
  type        = list(string)
  default     = ["10.0.10.0/24"]
}

# ECR Configuration
variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "automax-dealership"
}

# ECS Configuration (AWS Free Tier Optimized)
variable "ecs_task_cpu" {
  description = "CPU units for the ECS task (Free Tier: 256 CPU units)"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "Memory for the ECS task (Free Tier: 512 MB)"
  type        = string
  default     = "512"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks (Free Tier: 1 task to stay within limits)"
  type        = number
  default     = 1
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks (Free Tier: 1 task)"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks (Free Tier: 2 tasks max)"
  type        = number
  default     = 2
}

# Application Configuration
variable "image_uri" {
  description = "Docker image URI"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Project     = "AutoMax Car Dealership"
    Owner       = "DevOps Team"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
