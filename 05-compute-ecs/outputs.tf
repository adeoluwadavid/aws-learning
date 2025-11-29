# =============================================================================
# OUTPUTS - Phase 5: Compute (ECS Fargate)
# =============================================================================

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "backend_service_name" {
  description = "Name of the backend ECS service"
  value       = aws_ecs_service.backend.name
}

output "frontend_service_name" {
  description = "Name of the frontend ECS service"
  value       = aws_ecs_service.frontend.name
}

output "backend_task_definition" {
  description = "Backend task definition ARN"
  value       = aws_ecs_task_definition.backend.arn
}

output "frontend_task_definition" {
  description = "Frontend task definition ARN"
  value       = aws_ecs_task_definition.frontend.arn
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------

output "ecs_summary" {
  description = "Summary of ECS deployment"
  value = <<-EOT

    ============================================
    TaskFlow ECS Deployment - ${var.environment}
    ============================================

    Application URL:
      http://${aws_lb.main.dns_name}

    API Endpoint:
      http://${aws_lb.main.dns_name}/api/

    API Docs:
      http://${aws_lb.main.dns_name}/docs

    ECS Cluster:
      Name: ${aws_ecs_cluster.main.name}
      ARN:  ${aws_ecs_cluster.main.arn}

    Services:
      Backend:  ${aws_ecs_service.backend.name} (${var.backend_desired_count} tasks)
      Frontend: ${aws_ecs_service.frontend.name} (${var.frontend_desired_count} tasks)

    View Logs:
      Backend:  aws logs tail /ecs/${var.project_name}-${var.environment}/backend --follow
      Frontend: aws logs tail /ecs/${var.project_name}-${var.environment}/frontend --follow

    ============================================
  EOT
}
