# =============================================================================
# TERRAFORM VARIABLES FILE
# =============================================================================
# This file contains the actual values for variables defined in variables.tf
# You can have different .tfvars files for different environments:
# - terraform.tfvars (default, auto-loaded)
# - dev.tfvars
# - prod.tfvars (use with: terraform apply -var-file=prod.tfvars)

aws_region   = "us-east-1"
environment  = "dev"
project_name = "taskflow"

# VPC Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Subnet CIDRs
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
