# =============================================================================
# S3 BUCKET FOR FILE ATTACHMENTS
# =============================================================================
# S3 (Simple Storage Service) is object storage for any type of file.
#
# Key concepts:
# - Bucket: A container for objects (like a folder)
# - Object: A file + metadata (key = path, value = file content)
# - Key: The unique identifier/path for an object (e.g., "uploads/task-1/file.pdf")
#
# S3 is NOT a filesystem - it's flat storage with keys that look like paths.

# -----------------------------------------------------------------------------
# S3 BUCKET
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "attachments" {
  # Bucket names must be globally unique across ALL AWS accounts
  bucket = "${var.project_name}-${var.environment}-attachments-${var.aws_account_id}"

  # Prevent accidental deletion (set to true in production)
  force_destroy = true # Allows terraform destroy to delete non-empty bucket

  tags = {
    Name = "${var.project_name}-${var.environment}-attachments"
  }
}

# -----------------------------------------------------------------------------
# BUCKET VERSIONING
# -----------------------------------------------------------------------------
# Keeps multiple versions of an object. Useful for:
# - Recovering accidentally deleted files
# - Maintaining file history
# - Protection against overwrites

resource "aws_s3_bucket_versioning" "attachments" {
  bucket = aws_s3_bucket.attachments.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# SERVER-SIDE ENCRYPTION
# -----------------------------------------------------------------------------
# Encrypts data at rest. Options:
# - SSE-S3: AWS managed keys (default, free)
# - SSE-KMS: Customer managed keys (more control, costs extra)
# - SSE-C: Customer provided keys (you manage keys)

resource "aws_s3_bucket_server_side_encryption_configuration" "attachments" {
  bucket = aws_s3_bucket.attachments.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3, free and simple
    }
    bucket_key_enabled = true
  }
}

# -----------------------------------------------------------------------------
# BLOCK PUBLIC ACCESS
# -----------------------------------------------------------------------------
# Security best practice: block ALL public access by default.
# Use pre-signed URLs for controlled access instead.

resource "aws_s3_bucket_public_access_block" "attachments" {
  bucket = aws_s3_bucket.attachments.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# CORS CONFIGURATION
# -----------------------------------------------------------------------------
# Required for browser-based uploads (React frontend).
# Without CORS, browsers will block requests to S3 from your domain.

resource "aws_s3_bucket_cors_configuration" "attachments" {
  bucket = aws_s3_bucket.attachments.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = [
      "http://localhost:5173",     # Local development
      "http://localhost:3000",     # Alternative local port
      # Add your production domain here later:
      # "https://taskflow.yourdomain.com"
    ]
    expose_headers  = ["ETag", "Content-Length", "Content-Type"]
    max_age_seconds = 3600
  }
}

# -----------------------------------------------------------------------------
# LIFECYCLE RULES
# -----------------------------------------------------------------------------
# Automatically manage objects over time:
# - Move old files to cheaper storage classes
# - Delete incomplete multipart uploads
# - Expire old versions

resource "aws_s3_bucket_lifecycle_configuration" "attachments" {
  bucket = aws_s3_bucket.attachments.id

  # Clean up incomplete multipart uploads after 7 days
  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Move old versions to cheaper storage after 30 days
  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA" # Infrequent Access - cheaper
    }

    # Delete very old versions after 90 days
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# -----------------------------------------------------------------------------
# BUCKET POLICY
# -----------------------------------------------------------------------------
# Define who can access the bucket and what they can do.
# This policy allows the ECS task role from Phase 1 to access the bucket.

data "aws_iam_policy_document" "attachments_bucket_policy" {
  # Allow ECS tasks to read/write objects
  statement {
    sid    = "AllowECSTaskAccess"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.aws_account_id}:role/${var.project_name}-${var.environment}-ecs-task-role"
      ]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.attachments.arn,
      "${aws_s3_bucket.attachments.arn}/*"
    ]
  }

  # Allow Lambda functions to access (for thumbnail generation, etc.)
  statement {
    sid    = "AllowLambdaAccess"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.aws_account_id}:role/${var.project_name}-${var.environment}-lambda-execution-role"
      ]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.attachments.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  policy = data.aws_iam_policy_document.attachments_bucket_policy.json
}
