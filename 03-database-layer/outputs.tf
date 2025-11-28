# =============================================================================
# OUTPUTS - Phase 3: Database Layer
# =============================================================================

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint (hostname:port)"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "RDS instance hostname"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "db_secrets_policy_arn" {
  description = "ARN of IAM policy for accessing DB credentials"
  value       = aws_iam_policy.db_secrets_access.arn
}

# -----------------------------------------------------------------------------
# Connection Info Summary
# -----------------------------------------------------------------------------

output "database_summary" {
  description = "Summary of database configuration"
  value = <<-EOT

    ============================================
    TaskFlow Database - ${var.environment}
    ============================================

    RDS Instance:
      ID:       ${aws_db_instance.main.id}
      Engine:   PostgreSQL ${aws_db_instance.main.engine_version}
      Class:    ${aws_db_instance.main.instance_class}
      Storage:  ${aws_db_instance.main.allocated_storage}GB

    Connection:
      Host:     ${aws_db_instance.main.address}
      Port:     ${aws_db_instance.main.port}
      Database: ${aws_db_instance.main.db_name}

    Secrets Manager:
      Secret:   ${aws_secretsmanager_secret.db_credentials.name}
      ARN:      ${aws_secretsmanager_secret.db_credentials.arn}

    To retrieve credentials:
      aws secretsmanager get-secret-value \
        --secret-id ${aws_secretsmanager_secret.db_credentials.name} \
        --query SecretString --output text | jq

    ============================================
  EOT
}
