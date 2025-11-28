# =============================================================================
# VARIABLES - Phase 3: Database Layer
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

variable "private_subnet_ids" {
  description = "Private subnet IDs from Phase 1"
  type        = list(string)
}

variable "database_security_group_id" {
  description = "Database security group ID from Phase 1"
  type        = string
}

# -----------------------------------------------------------------------------
# RDS Configuration
# -----------------------------------------------------------------------------

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "taskflow"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "taskflow_admin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}
