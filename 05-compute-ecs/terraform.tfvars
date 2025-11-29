# =============================================================================
# TERRAFORM VARIABLES - Phase 5: Compute (ECS Fargate)
# =============================================================================
# Update these values with outputs from previous phases

aws_region   = "us-east-1"
environment  = "dev"
project_name = "taskflow"

# -----------------------------------------------------------------------------
# VPC References (from Phase 1)
# -----------------------------------------------------------------------------
# Get these values by running:
#   cd ../01-core-infrastructure && terraform output

vpc_id = "vpc-XXXXX"  # UPDATE with your VPC ID

public_subnet_ids = [
  "subnet-XXXXX",  # UPDATE with your public subnet IDs
  "subnet-XXXXX"
]

private_subnet_ids = [
  "subnet-XXXXX",  # UPDATE with your private subnet IDs
  "subnet-XXXXX"
]

alb_security_group_id = "sg-XXXXX"  # UPDATE with your ALB security group ID
app_security_group_id = "sg-XXXXX"  # UPDATE with your App security group ID

# -----------------------------------------------------------------------------
# ECR References (from Phase 4)
# -----------------------------------------------------------------------------
# Get these values by running:
#   cd ../04-containerization && terraform output

backend_repository_url  = "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/taskflow-dev-backend"   # UPDATE
frontend_repository_url = "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/taskflow-dev-frontend"  # UPDATE

# -----------------------------------------------------------------------------
# Database References (from Phase 3)
# -----------------------------------------------------------------------------
# Get this value by running:
#   cd ../03-database-layer && terraform output db_secret_arn

db_secret_arn = "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:taskflow-dev-db-credentials-XXXXX"  # UPDATE

# -----------------------------------------------------------------------------
# S3 References (from Phase 2)
# -----------------------------------------------------------------------------
# Get this value by running:
#   cd ../02-storage-basics && terraform output

s3_bucket_name = "taskflow-dev-attachments-ACCOUNT_ID"  # UPDATE

# -----------------------------------------------------------------------------
# ECS Configuration
# -----------------------------------------------------------------------------

# Fargate pricing (us-east-1):
# - CPU: $0.04048 per vCPU per hour
# - Memory: $0.004445 per GB per hour
# Minimum: 0.25 vCPU + 0.5 GB = ~$0.012/hour per task

backend_cpu           = 256    # 0.25 vCPU
backend_memory        = 512    # 0.5 GB
backend_desired_count = 1

frontend_cpu           = 256
frontend_memory        = 512
frontend_desired_count = 1
