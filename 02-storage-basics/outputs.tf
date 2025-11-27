# =============================================================================
# OUTPUTS
# =============================================================================

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.attachments.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.attachments.arn
}

output "bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.attachments.region
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.attachments.bucket_domain_name
}

output "summary" {
  description = "S3 bucket summary"
  value       = <<-EOT

    ============================================
    TaskFlow S3 Storage - ${var.environment}
    ============================================

    Bucket Name:   ${aws_s3_bucket.attachments.id}
    Bucket ARN:    ${aws_s3_bucket.attachments.arn}
    Region:        ${var.aws_region}

    Features:
      - Versioning: Enabled
      - Encryption: AES-256 (SSE-S3)
      - Public Access: Blocked
      - CORS: Configured for localhost

    Usage in FastAPI:
      AWS_S3_BUCKET=${aws_s3_bucket.attachments.id}
      AWS_REGION=${var.aws_region}

    ============================================
  EOT
}
