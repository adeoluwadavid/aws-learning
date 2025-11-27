# Phase 2: Storage Basics (S3)

This phase adds AWS S3 for storing file attachments instead of local disk storage.

## What You'll Learn

- **S3 Buckets**: Object storage containers
- **Bucket Policies**: Access control at bucket level
- **Pre-signed URLs**: Temporary, secure access to private files
- **Server-side Encryption**: Data protection at rest
- **CORS**: Cross-origin resource sharing for browser uploads
- **Lifecycle Rules**: Automatic file management

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend                                 │
│                    (React Application)                           │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Backend                                  │
│                    (FastAPI + boto3)                             │
│                                                                  │
│   ┌─────────────────┐        ┌─────────────────┐                │
│   │  Local Storage  │   OR   │   S3 Storage    │                │
│   │   (USE_S3=false)│        │   (USE_S3=true) │                │
│   └─────────────────┘        └────────┬────────┘                │
└───────────────────────────────────────┼─────────────────────────┘
                                        │
                                        ▼
                            ┌─────────────────────┐
                            │     S3 Bucket       │
                            │                     │
                            │  tasks/             │
                            │    1/               │
                            │      file1.pdf      │
                            │      file2.png      │
                            │    2/               │
                            │      report.docx    │
                            └─────────────────────┘
```

## S3 Key Concepts

### Objects and Keys
S3 is **object storage**, not a file system:
- **Object**: A file + metadata
- **Key**: The unique identifier (looks like a path: `tasks/1/file.pdf`)
- **Bucket**: A container for objects

```
# This is a KEY, not a folder structure:
tasks/1/abc123_document.pdf
  │   │  │
  │   │  └── filename (with UUID prefix for uniqueness)
  │   └── task ID
  └── prefix (like a folder, but it's not)
```

### Pre-signed URLs
Since our bucket is private (no public access), we use **pre-signed URLs**:

```python
# Generate a URL that works for 1 hour
url = s3_client.generate_presigned_url(
    "get_object",
    Params={"Bucket": "my-bucket", "Key": "tasks/1/file.pdf"},
    ExpiresIn=3600  # seconds
)
# Result: https://my-bucket.s3.amazonaws.com/tasks/1/file.pdf?X-Amz-Signature=...
```

Benefits:
- No need to make bucket public
- Time-limited access
- Can be generated for upload or download

### Storage Classes
S3 offers different storage classes at different prices:

| Class | Use Case | Retrieval |
|-------|----------|-----------|
| STANDARD | Frequently accessed | Instant |
| STANDARD_IA | Infrequent access | Instant |
| GLACIER | Archival | Minutes to hours |
| DEEP_ARCHIVE | Long-term archive | 12+ hours |

Our lifecycle rules automatically move old versions to cheaper storage.

## Files Created

### Terraform (`02-storage-basics/`)
| File | Purpose |
|------|---------|
| `providers.tf` | AWS provider configuration |
| `variables.tf` | Input variables |
| `terraform.tfvars` | Variable values |
| `s3.tf` | S3 bucket, policies, CORS, lifecycle |
| `outputs.tf` | Bucket name, ARN, etc. |

### Backend Updates (`00-local-development/backend/`)
| File | Changes |
|------|---------|
| `requirements.txt` | Added `boto3` |
| `app/config.py` | Added S3 configuration settings |
| `app/storage.py` | New file - storage abstraction layer |
| `app/routers/attachments.py` | Updated to use storage abstraction |
| `.env.example` | Added S3 environment variables |

## Usage

### 1. Deploy S3 Bucket

```bash
cd 02-storage-basics
terraform init
terraform plan
terraform apply
```

Note the bucket name from the output.

### 2. Update Backend Configuration

Create `.env` file in `00-local-development/backend/`:

```bash
# Copy example and edit
cp .env.example .env
```

Edit `.env`:
```
USE_S3=true
AWS_S3_BUCKET=taskflow-dev-attachments-871253127893
AWS_REGION=us-east-1
```

### 3. Install boto3

```bash
cd 00-local-development/backend
source venv/bin/activate
pip install boto3
```

### 4. Test Upload

```bash
# Start the server
python -m uvicorn app.main:app --reload

# Upload a file (need to create a task first)
curl -X POST "http://localhost:8000/tasks/1/attachments" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test.pdf"
```

## Storage Abstraction Pattern

The code uses a **Strategy Pattern** for storage:

```python
# app/storage.py

class StorageBackend(ABC):
    @abstractmethod
    def upload_file(self, file, filename, folder, content_type) -> (path, size):
        pass

    @abstractmethod
    def delete_file(self, file_path) -> bool:
        pass

    @abstractmethod
    def get_download_url(self, file_path, expires_in) -> str:
        pass

class LocalStorage(StorageBackend):
    # Saves to local disk

class S3Storage(StorageBackend):
    # Saves to S3

def get_storage() -> StorageBackend:
    if settings.USE_S3:
        return S3Storage(...)
    return LocalStorage()
```

This allows:
- Easy switching between local and S3
- Testing without AWS
- Same code works in dev and production

## Security Features

### Bucket Security
```hcl
# Block ALL public access
resource "aws_s3_bucket_public_access_block" "attachments" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Encryption at Rest
```hcl
# AES-256 encryption (free)
resource "aws_s3_bucket_server_side_encryption_configuration" "attachments" {
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### Access Control
Only our ECS and Lambda roles can access the bucket:
```hcl
# Bucket policy allows only specific IAM roles
principals {
  type        = "AWS"
  identifiers = ["arn:aws:iam::...:role/taskflow-dev-ecs-task-role"]
}
```

## Cost Breakdown

| Resource | Cost | Notes |
|----------|------|-------|
| S3 Storage | $0.023/GB/month | First 50TB |
| PUT requests | $0.005/1000 | Uploads |
| GET requests | $0.0004/1000 | Downloads |
| Data transfer | $0.09/GB | Out to internet |

**For learning**: A few MB of test files = essentially free

## Testing Locally (Without S3)

The app works without S3! Just don't set `USE_S3=true`:

```bash
# .env
USE_S3=false  # Uses local uploads/ folder
```

## Common Issues

### "Access Denied" on upload
- Check IAM permissions
- Verify bucket name matches
- Ensure AWS credentials are configured

### "CORS error" from browser
- Check CORS configuration includes your origin
- Add your domain to `allowed_origins` in `s3.tf`

### "NoSuchBucket" error
- Bucket name is globally unique - yours might differ
- Run `terraform output bucket_name` to get exact name

## Cleanup

```bash
cd 02-storage-basics
terraform destroy
```

**Note**: The bucket must be empty to destroy. With `force_destroy = true`, Terraform will delete all objects automatically.

## Next Steps

After completing this phase:
- ✅ S3 bucket for file storage
- ✅ Backend supports S3 uploads/downloads
- ✅ Pre-signed URLs for secure access

**Phase 3**: We'll add a database (RDS PostgreSQL or DynamoDB) to replace SQLite.
