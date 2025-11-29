# =============================================================================
# VARIABLES - Phase 5: Compute (ECS Fargate)
# =============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "taskflow"
}

# -----------------------------------------------------------------------------
# VPC References (from Phase 1)
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID from Phase 1"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs from Phase 1 (for ALB)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs from Phase 1 (for ECS tasks)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB security group ID from Phase 1"
  type        = string
}

variable "app_security_group_id" {
  description = "App security group ID from Phase 1"
  type        = string
}

# -----------------------------------------------------------------------------
# ECR References (from Phase 4)
# -----------------------------------------------------------------------------

variable "backend_repository_url" {
  description = "Backend ECR repository URL from Phase 4"
  type        = string
}

variable "frontend_repository_url" {
  description = "Frontend ECR repository URL from Phase 4"
  type        = string
}

# -----------------------------------------------------------------------------
# Database References (from Phase 3)
# -----------------------------------------------------------------------------

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB credentials"
  type        = string
}

# -----------------------------------------------------------------------------
# S3 References (from Phase 2)
# -----------------------------------------------------------------------------

variable "s3_bucket_name" {
  description = "S3 bucket name for file attachments"
  type        = string
}

# -----------------------------------------------------------------------------
# ECS Configuration
# -----------------------------------------------------------------------------

variable "backend_cpu" {
  description = "CPU units for backend task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory for backend task in MB"
  type        = number
  default     = 512
}

variable "frontend_cpu" {
  description = "CPU units for frontend task"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory for frontend task in MB"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "Number of backend tasks to run"
  type        = number
  default     = 1
}

variable "frontend_desired_count" {
  description = "Number of frontend tasks to run"
  type        = number
  default     = 1
}
