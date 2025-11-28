# =============================================================================
# OUTPUTS - Phase 4: Containerization (ECR)
# =============================================================================

output "backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "backend_repository_arn" {
  description = "ARN of the backend ECR repository"
  value       = aws_ecr_repository.backend.arn
}

output "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

output "frontend_repository_arn" {
  description = "ARN of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.arn
}

output "aws_account_id" {
  description = "AWS Account ID (needed for ECR login)"
  value       = data.aws_caller_identity.current.account_id
}

output "ecr_registry_url" {
  description = "ECR registry URL"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# -----------------------------------------------------------------------------
# Summary Output with Push Commands
# -----------------------------------------------------------------------------

output "ecr_summary" {
  description = "Summary of ECR repositories with push commands"
  value = <<-EOT

    ============================================
    TaskFlow ECR Repositories - ${var.environment}
    ============================================

    Backend Repository:
      URL: ${aws_ecr_repository.backend.repository_url}

    Frontend Repository:
      URL: ${aws_ecr_repository.frontend.repository_url}

    ============================================
    Docker Push Commands
    ============================================

    1. Login to ECR:
       aws ecr get-login-password --region ${var.aws_region} | \
         docker login --username AWS --password-stdin \
         ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

    2. Build and push backend:
       cd 00-local-development/backend
       docker build -t ${aws_ecr_repository.backend.repository_url}:latest -f Dockerfile.prod .
       docker push ${aws_ecr_repository.backend.repository_url}:latest

    3. Build and push frontend:
       cd 00-local-development/frontend
       docker build -t ${aws_ecr_repository.frontend.repository_url}:latest -f Dockerfile.prod .
       docker push ${aws_ecr_repository.frontend.repository_url}:latest

    ============================================
  EOT
}

# -----------------------------------------------------------------------------
# Data Source for AWS Account ID
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
