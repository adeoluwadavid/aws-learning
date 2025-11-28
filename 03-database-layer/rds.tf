# =============================================================================
# RDS POSTGRESQL - Phase 3: Database Layer
# =============================================================================
# Amazon RDS (Relational Database Service) is a managed database service.
# Benefits over self-managed databases:
# - Automated backups, patching, and maintenance
# - Multi-AZ for high availability (optional)
# - Read replicas for scaling reads (optional)
# - Encryption at rest and in transit
# - Monitoring via CloudWatch

# -----------------------------------------------------------------------------
# DB Subnet Group
# -----------------------------------------------------------------------------
# RDS needs to know which subnets it can use. We place it in private subnets
# so it's not directly accessible from the internet.

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Database subnet group for TaskFlow"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL Instance
# -----------------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  # Engine configuration
  engine               = "postgres"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class

  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = 100  # Enable storage autoscaling up to 100GB
  storage_type          = "gp2"
  storage_encrypted     = true  # Encrypt at rest (free, no reason not to!)

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = 5432

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false  # Not accessible from internet

  # Backup configuration (minimal for dev to save costs)
  backup_retention_period = 1     # Keep backups for 1 day
  backup_window           = "03:00-04:00"  # UTC
  maintenance_window      = "Mon:04:00-Mon:05:00"  # UTC

  # For learning/dev environment:
  skip_final_snapshot       = true   # Don't create snapshot on destroy
  delete_automated_backups  = true   # Delete backups on destroy
  deletion_protection       = false  # Allow terraform destroy

  # Performance Insights (free tier available)
  performance_insights_enabled = true
  performance_insights_retention_period = 7  # Free tier: 7 days

  # Parameter group (use defaults for now)
  # parameter_group_name = "default.postgres15"  # Let AWS choose the right one

  # Apply changes immediately (for dev; production would use maintenance window)
  apply_immediately = true

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms (Optional but good practice)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-db-cpu-high"
  alarm_description   = "Database CPU utilization is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_storage" {
  alarm_name          = "${var.project_name}-${var.environment}-db-storage-low"
  alarm_description   = "Database free storage space is low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5000000000  # 5GB in bytes
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-storage-alarm"
  }
}
