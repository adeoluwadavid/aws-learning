# =============================================================================
# SECRETS MANAGER - Database Credentials
# =============================================================================
# Secrets Manager securely stores sensitive data like database passwords.
# Benefits:
# - Automatic encryption with KMS
# - Fine-grained access control via IAM
# - Audit trail via CloudTrail
# - Can rotate secrets automatically

# -----------------------------------------------------------------------------
# Generate a Random Password
# -----------------------------------------------------------------------------
# We generate a secure random password instead of hardcoding one

resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"  # Avoid characters that cause issues
}

# -----------------------------------------------------------------------------
# Store Credentials in Secrets Manager
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}-${var.environment}-db-credentials"
  description = "Database credentials for TaskFlow ${var.environment}"

  # For learning: allow immediate deletion (production would use recovery window)
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-${var.environment}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
    # Full connection string for convenience
    url      = "postgresql://${var.db_username}:${random_password.db_password.result}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}"
  })
}

# -----------------------------------------------------------------------------
# IAM Policy for Accessing the Secret
# -----------------------------------------------------------------------------
# This policy can be attached to ECS tasks or Lambda functions

resource "aws_iam_policy" "db_secrets_access" {
  name        = "${var.project_name}-${var.environment}-db-secrets-access"
  description = "Allow access to database credentials secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      }
    ]
  })
}
