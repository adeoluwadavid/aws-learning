# =============================================================================
# ECS CLUSTER - Phase 5: Compute
# =============================================================================
# ECS (Elastic Container Service) is AWS's container orchestration service.
# A cluster is a logical grouping of tasks and services.

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  # Enable Container Insights for monitoring (free tier available)
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# -----------------------------------------------------------------------------
# ECS Cluster Capacity Providers
# -----------------------------------------------------------------------------
# Fargate = serverless containers (no EC2 to manage)
# Fargate Spot = up to 70% cheaper but can be interrupted

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
