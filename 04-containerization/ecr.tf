# =============================================================================
# ECR (Elastic Container Registry) - Phase 4: Containerization
# =============================================================================
# ECR is a fully managed Docker container registry.
# Benefits:
# - Integrated with ECS, EKS, and Lambda
# - Automatic image scanning for vulnerabilities
# - Lifecycle policies to manage image retention
# - Private by default (no public access)
# - Pay only for storage used (~$0.10/GB/month)

# -----------------------------------------------------------------------------
# ECR Repository for Backend (FastAPI)
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-${var.environment}-backend"
  image_tag_mutability = "MUTABLE"  # Allow overwriting tags (e.g., 'latest')

  # Enable image scanning on push
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encrypt images at rest (free with AWS-managed key)
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backend"
  }
}

# -----------------------------------------------------------------------------
# ECR Repository for Frontend (React/Nginx)
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-${var.environment}-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend"
  }
}

# -----------------------------------------------------------------------------
# Lifecycle Policies - Automatically clean up old images
# -----------------------------------------------------------------------------
# This saves storage costs by removing untagged and old images

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only last ${var.image_retention_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only last ${var.image_retention_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
