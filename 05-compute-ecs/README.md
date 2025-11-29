# Phase 5: Compute (ECS Fargate)

This phase deploys the TaskFlow application to AWS using ECS Fargate - serverless containers.

## What You'll Learn

- **ECS Cluster**: Logical grouping of containerized services
- **Task Definitions**: Container blueprints (image, CPU, memory, env vars)
- **ECS Services**: Maintain desired number of running tasks
- **Application Load Balancer**: Distribute traffic and path-based routing
- **Fargate**: Serverless compute - no EC2 instances to manage

## Architecture

```
                         Internet
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Application Load Balancer                 │
│                    (Public Subnets)                         │
│                                                             │
│     /*  ──────────────►  Frontend Target Group              │
│     /api/* ───────────►  Backend Target Group               │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    ECS Fargate Cluster                       │
│                    (Private Subnets)                         │
│                                                              │
│  ┌─────────────────┐           ┌─────────────────┐          │
│  │ Frontend Service│           │ Backend Service │          │
│  │   (React/Nginx) │           │    (FastAPI)    │          │
│  │                 │           │                 │          │
│  │  ┌───────────┐  │           │  ┌───────────┐  │          │
│  │  │   Task    │  │           │  │   Task    │  │          │
│  │  │  (Nginx)  │  │           │  │ (Uvicorn) │  │          │
│  │  └───────────┘  │           │  └───────────┘  │          │
│  └─────────────────┘           └────────┬────────┘          │
│                                         │                    │
└─────────────────────────────────────────┼────────────────────┘
                                          │
                          ┌───────────────┼───────────────┐
                          ▼               ▼               ▼
                    ┌─────────┐    ┌─────────┐    ┌─────────┐
                    │   RDS   │    │   S3    │    │ Secrets │
                    │PostgreSQL│   │ Bucket  │    │ Manager │
                    └─────────┘    └─────────┘    └─────────┘
```

## Prerequisites

Ensure these phases are deployed:
- Phase 1: Core Infrastructure (VPC, subnets, security groups)
- Phase 2: S3 Storage (bucket for attachments)
- Phase 3: Database (RDS PostgreSQL running)
- Phase 4: ECR (images pushed)

## Files

| File | Description |
|------|-------------|
| `providers.tf` | AWS provider configuration |
| `variables.tf` | Input variables |
| `terraform.tfvars` | Variable values (update with your IDs) |
| `ecs-cluster.tf` | ECS cluster with Fargate capacity |
| `ecs-tasks.tf` | Task definitions for backend and frontend |
| `ecs-services.tf` | ECS services with load balancer integration |
| `alb.tf` | Application Load Balancer and target groups |
| `iam.tf` | Additional IAM policies for secrets/S3 access |
| `outputs.tf` | URLs and deployment info |

## Deployment

### 1. Get Values from Previous Phases

```bash
# Phase 1 outputs
cd ../01-core-infrastructure
terraform output vpc_id
terraform output public_subnet_ids
terraform output private_subnet_ids
terraform output alb_security_group_id
terraform output app_security_group_id

# Phase 2 outputs
cd ../02-storage-basics
terraform output bucket_name

# Phase 3 outputs
cd ../03-database-layer
terraform output db_secret_arn

# Phase 4 outputs
cd ../04-containerization
terraform output backend_repository_url
terraform output frontend_repository_url
```

### 2. Update terraform.tfvars

Edit `terraform.tfvars` with all the values from above.

### 3. Deploy

```bash
cd 05-compute-ecs

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy (takes 3-5 minutes)
terraform apply
```

### 4. Access the Application

After deployment, Terraform outputs the ALB URL:

```
Application URL:
  http://taskflow-dev-alb-XXXXXXXXX.us-east-1.elb.amazonaws.com

API Docs:
  http://taskflow-dev-alb-XXXXXXXXX.us-east-1.elb.amazonaws.com/docs
```

## Cost Estimate

| Resource | Cost |
|----------|------|
| ALB | ~$0.0225/hour (~$16/month) |
| Fargate (2 tasks, 0.25 vCPU, 0.5GB each) | ~$0.024/hour (~$18/month) |
| **Total** | **~$0.05/hour (~$35/month)** |

**Cost Tips:**
- Scale down to 0 tasks when not using: `aws ecs update-service --cluster taskflow-dev-cluster --service taskflow-dev-backend --desired-count 0`
- Or run `terraform destroy` to remove everything

## Monitoring

### View Logs
```bash
# Backend logs
aws logs tail /ecs/taskflow-dev/backend --follow

# Frontend logs
aws logs tail /ecs/taskflow-dev/frontend --follow
```

### Check Service Status
```bash
aws ecs describe-services \
  --cluster taskflow-dev-cluster \
  --services taskflow-dev-backend taskflow-dev-frontend
```

### View Running Tasks
```bash
aws ecs list-tasks --cluster taskflow-dev-cluster
```

## Troubleshooting

### Tasks keep restarting
1. Check CloudWatch logs for errors
2. Verify RDS is running and accessible
3. Check security group rules allow traffic

### "Service unavailable" from ALB
1. Wait 2-3 minutes for tasks to become healthy
2. Check target group health: AWS Console → EC2 → Target Groups
3. Verify health check paths return 200

### Database connection errors
1. Verify RDS is running: `cd ../03-database-layer && terraform output`
2. Check Secrets Manager has correct credentials
3. Verify backend task has Secrets Manager access

## Scaling

### Manual Scaling
```bash
# Scale backend to 2 tasks
aws ecs update-service \
  --cluster taskflow-dev-cluster \
  --service taskflow-dev-backend \
  --desired-count 2
```

### Scale to Zero (Stop Billing)
```bash
# Stop all tasks
aws ecs update-service --cluster taskflow-dev-cluster --service taskflow-dev-backend --desired-count 0
aws ecs update-service --cluster taskflow-dev-cluster --service taskflow-dev-frontend --desired-count 0
```

## Cleanup

```bash
terraform destroy
```

This removes:
- ECS cluster and services
- Task definitions
- ALB and target groups
- CloudWatch log groups

**Note**: This does NOT destroy RDS, S3, ECR, or VPC - they are managed in other phases.

## Next Phase

**Phase 6: Networking** - Add custom domain with Route 53 and HTTPS with CloudFront/ACM.
