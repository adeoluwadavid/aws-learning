# =============================================================================
# IAM ROLES FOR ECS - Phase 5: Compute
# =============================================================================
# ECS tasks need IAM roles to:
# - Pull images from ECR
# - Write logs to CloudWatch
# - Access Secrets Manager for DB credentials
# - Access S3 for file attachments

# -----------------------------------------------------------------------------
# Data source for existing ECS execution role from Phase 1
# -----------------------------------------------------------------------------

data "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"
}

data "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"
}

# -----------------------------------------------------------------------------
# Additional Policy for Secrets Manager Access
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy" "ecs_secrets_access" {
  name = "${var.project_name}-${var.environment}-ecs-secrets-access"
  role = data.aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.db_secret_arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Additional Policy for S3 Access (for task role, not execution role)
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy" "ecs_s3_access" {
  name = "${var.project_name}-${var.environment}-ecs-s3-access"
  role = data.aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}
