# =============================================================================
# TERRAFORM VARIABLES - Phase 3: Database Layer
# =============================================================================
# Update these values with outputs from Phase 1 (01-core-infrastructure)
# Run: cd ../01-core-infrastructure && terraform output

aws_region   = "us-east-1"
environment  = "dev"
project_name = "taskflow"

# -----------------------------------------------------------------------------
# VPC References (UPDATE THESE from Phase 1 output)
# -----------------------------------------------------------------------------
# Get these values by running:
#   cd ../01-core-infrastructure
#   terraform output vpc_id
#   terraform output private_subnet_ids
#   terraform output database_security_group_id

vpc_id = "vpc-0719d930f39fe426a"  # UPDATE with your VPC ID

private_subnet_ids = [
  "subnet-084879e710bb2ee8f",  # UPDATE with your private subnet IDs
  "subnet-02f880911451391c1"
]

database_security_group_id = "sg-0934111f64e478eb3"  # UPDATE with your DB security group ID

# -----------------------------------------------------------------------------
# RDS Configuration
# -----------------------------------------------------------------------------

db_name           = "taskflow"
db_username       = "taskflow_admin"
db_instance_class = "db.t3.micro"  # Smallest instance (~$0.02/hour)
db_allocated_storage = 20          # 20GB minimum
db_engine_version = "15"           # PostgreSQL 15 (latest minor version)
