# =============================================================================
# VARIABLES - Phase 4: Containerization (ECR)
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
# ECR Configuration
# -----------------------------------------------------------------------------

variable "image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 5
}
