# Phase 4: Containerization (ECR)

This phase creates ECR repositories to store Docker images for the TaskFlow application.

## What You'll Learn

- **Amazon ECR**: Elastic Container Registry for Docker images
- **Multi-stage Docker builds**: Smaller, optimized production images
- **Image lifecycle policies**: Automatic cleanup of old images
- **Docker tagging strategies**: Using 'latest' and version tags

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Local Machine                        │
│  ┌─────────────────┐        ┌─────────────────┐             │
│  │  Backend Code   │        │  Frontend Code  │             │
│  │   (FastAPI)     │        │    (React)      │             │
│  └────────┬────────┘        └────────┬────────┘             │
│           │ docker build             │ docker build         │
│           ▼                          ▼                      │
│  ┌─────────────────┐        ┌─────────────────┐             │
│  │  Backend Image  │        │ Frontend Image  │             │
│  └────────┬────────┘        └────────┬────────┘             │
└───────────┼──────────────────────────┼──────────────────────┘
            │ docker push              │ docker push
            ▼                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    AWS ECR                                   │
│  ┌─────────────────┐        ┌─────────────────┐             │
│  │ taskflow-dev-   │        │ taskflow-dev-   │             │
│  │    backend      │        │   frontend      │             │
│  │  (FastAPI)      │        │ (React/Nginx)   │             │
│  └─────────────────┘        └─────────────────┘             │
└─────────────────────────────────────────────────────────────┘
```

## Files

| File | Description |
|------|-------------|
| `providers.tf` | AWS provider configuration |
| `variables.tf` | Input variables |
| `terraform.tfvars` | Variable values |
| `ecr.tf` | ECR repositories and lifecycle policies |
| `outputs.tf` | Repository URLs and push commands |
| `scripts/build-and-push.sh` | Build and push automation script |

## Production Dockerfiles Added

| File | Description |
|------|-------------|
| `00-local-development/backend/Dockerfile.prod` | Optimized FastAPI image (~150MB) |
| `00-local-development/frontend/Dockerfile.prod` | React build served by Nginx (~25MB) |
| `00-local-development/frontend/nginx.conf` | Nginx config with SPA routing |

## Deployment

### 1. Deploy ECR Repositories

```bash
cd 04-containerization

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy
terraform apply
```

### 2. Build and Push Images

**Option A: Use the script**
```bash
cd 04-containerization/scripts
./build-and-push.sh all      # Build and push both
./build-and-push.sh backend  # Backend only
./build-and-push.sh frontend # Frontend only
```

**Option B: Manual commands**
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push backend
cd 00-local-development/backend
docker build -t YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/taskflow-dev-backend:latest -f Dockerfile.prod .
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/taskflow-dev-backend:latest

# Build and push frontend
cd ../frontend
docker build -t YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/taskflow-dev-frontend:latest -f Dockerfile.prod .
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/taskflow-dev-frontend:latest
```

### 3. Verify Images

```bash
# List images in backend repository
aws ecr list-images --repository-name taskflow-dev-backend

# List images in frontend repository
aws ecr list-images --repository-name taskflow-dev-frontend
```

## Cost Estimate

| Resource | Cost |
|----------|------|
| ECR Storage | ~$0.10/GB/month |
| Data Transfer | Free within same region |

**Note**: With lifecycle policies, old images are automatically deleted, keeping costs minimal.

## Docker Image Optimization

### Backend (FastAPI)
- **Base**: `python:3.11-slim` (not full Python image)
- **Multi-stage build**: Build deps separate from runtime
- **Non-root user**: Security best practice
- **Health check**: For container orchestration

### Frontend (React/Nginx)
- **Build stage**: Node.js builds the React app
- **Production stage**: Nginx serves static files
- **Gzip compression**: Faster loading
- **SPA routing**: React Router support

## Lifecycle Policies

Both repositories have lifecycle policies that:
1. Delete untagged images after 1 day
2. Keep only the last 5 tagged images

This prevents storage costs from growing unbounded.

## Troubleshooting

### "no basic auth credentials" error
```bash
# Re-login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

### "denied: Your authorization token has expired"
ECR tokens expire after 12 hours. Re-run the login command.

### Image scan shows vulnerabilities
```bash
# View scan results
aws ecr describe-image-scan-findings \
  --repository-name taskflow-dev-backend \
  --image-id imageTag=latest
```

## Cleanup

```bash
terraform destroy
```

This removes:
- ECR repositories (and all images in them)
- Lifecycle policies

## Next Phase

**Phase 5: Compute (ECS)** - Deploy containers to AWS using ECS Fargate.
