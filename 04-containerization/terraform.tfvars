# =============================================================================
# TERRAFORM VARIABLES - Phase 4: Containerization (ECR)
# =============================================================================

aws_region   = "us-east-1"
environment  = "dev"
project_name = "taskflow"

# ECR Configuration
image_retention_count = 5  # Keep last 5 images per repository
