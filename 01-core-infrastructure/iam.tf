# =============================================================================
# IAM (Identity and Access Management)
# =============================================================================
# IAM controls WHO can do WHAT in your AWS account.
#
# Key concepts:
# - Users: People (developers, admins)
# - Roles: Identities for AWS services (EC2, ECS, Lambda)
# - Policies: JSON documents defining permissions
# - Groups: Collections of users sharing permissions
#
# Best Practice: Use ROLES for services, USERS for people

# -----------------------------------------------------------------------------
# ECS TASK EXECUTION ROLE
# -----------------------------------------------------------------------------
# This role allows ECS to pull container images from ECR and write logs.
# It's the role ECS uses to START your containers (not what runs inside them).

# Trust policy - allows ECS tasks to assume this role
data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project_name}-${var.environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-execution-role"
  }
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----------------------------------------------------------------------------
# ECS TASK ROLE
# -----------------------------------------------------------------------------
# This role is assumed by the containers themselves (your FastAPI app).
# It defines what AWS services your application code can access.

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.project_name}-${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-role"
  }
}

# Policy for the application to access S3 (for file attachments)
data "aws_iam_policy_document" "ecs_task_policy" {
  # S3 access for file attachments
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-${var.environment}-*",
      "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
    ]
  }

  # Secrets Manager access (for database credentials)
  statement {
    sid    = "SecretsManagerAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}/${var.environment}/*"
    ]
  }

  # CloudWatch Logs access
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecs_task" {
  name   = "${var.project_name}-${var.environment}-ecs-task-policy"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.ecs_task_policy.json
}

# -----------------------------------------------------------------------------
# LAMBDA EXECUTION ROLE
# -----------------------------------------------------------------------------
# For Lambda functions (background tasks like sending emails, generating PDFs)

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution" {
  name               = "${var.project_name}-${var.environment}-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-execution-role"
  }
}

# Attach basic Lambda execution policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy for Lambda to access VPC (if running in VPC)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
