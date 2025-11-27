# =============================================================================
# OUTPUTS
# =============================================================================
# Outputs expose values from your Terraform state that can be:
# - Displayed after `terraform apply`
# - Used by other Terraform configurations
# - Queried via `terraform output`

# -----------------------------------------------------------------------------
# VPC OUTPUTS
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main[0].id
}

# -----------------------------------------------------------------------------
# SECURITY GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# -----------------------------------------------------------------------------
# IAM OUTPUTS
# -----------------------------------------------------------------------------

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

# -----------------------------------------------------------------------------
# SUMMARY OUTPUT
# -----------------------------------------------------------------------------

output "infrastructure_summary" {
  description = "Summary of created infrastructure"
  value = <<-EOT

    ============================================
    TaskFlow Infrastructure - ${var.environment}
    ============================================

    VPC:
      ID:   ${aws_vpc.main.id}
      CIDR: ${aws_vpc.main.cidr_block}

    Public Subnets:
      ${join("\n      ", [for s in aws_subnet.public : "${s.availability_zone}: ${s.cidr_block}"])}

    Private Subnets:
      ${join("\n      ", [for s in aws_subnet.private : "${s.availability_zone}: ${s.cidr_block}"])}

    Security Groups:
      ALB: ${aws_security_group.alb.id}
      App: ${aws_security_group.app.id}
      DB:  ${aws_security_group.database.id}

    IAM Roles:
      ECS Execution: ${aws_iam_role.ecs_task_execution.name}
      ECS Task:      ${aws_iam_role.ecs_task.name}
      Lambda:        ${aws_iam_role.lambda_execution.name}

    ============================================
  EOT
}
