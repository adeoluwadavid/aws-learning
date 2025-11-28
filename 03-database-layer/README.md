# Phase 3: Database Layer (RDS PostgreSQL)

This phase provisions a managed PostgreSQL database using Amazon RDS, replacing SQLite for production use.

## What You'll Learn

- **Amazon RDS**: Managed relational database service
- **DB Subnet Groups**: Placing databases in private subnets
- **Secrets Manager**: Secure credential storage
- **CloudWatch Alarms**: Database monitoring

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                          VPC                                 │
│  ┌─────────────────┐              ┌─────────────────┐       │
│  │  Public Subnet  │              │  Public Subnet  │       │
│  │   (us-east-1a)  │              │   (us-east-1b)  │       │
│  └─────────────────┘              └─────────────────┘       │
│                                                              │
│  ┌─────────────────┐              ┌─────────────────┐       │
│  │ Private Subnet  │              │ Private Subnet  │       │
│  │  (us-east-1a)   │              │  (us-east-1b)   │       │
│  │                 │              │                 │       │
│  │  ┌───────────┐  │              │  (Multi-AZ     │       │
│  │  │    RDS    │  │◄────────────►│   Standby)     │       │
│  │  │ PostgreSQL│  │  replication │                 │       │
│  │  └───────────┘  │              │                 │       │
│  └─────────────────┘              └─────────────────┘       │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                 Secrets Manager                       │   │
│  │            (Database Credentials)                     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. Phase 1 infrastructure deployed (`01-core-infrastructure`)
2. Get values from Phase 1:
   ```bash
   cd ../01-core-infrastructure
   terraform output vpc_id
   terraform output private_subnet_ids
   terraform output database_security_group_id
   ```

## Files

| File | Description |
|------|-------------|
| `providers.tf` | AWS provider and Terraform settings |
| `variables.tf` | Input variables |
| `terraform.tfvars` | Variable values (update with Phase 1 outputs) |
| `rds.tf` | RDS PostgreSQL instance and subnet group |
| `secrets.tf` | Secrets Manager for credentials, IAM policy |
| `outputs.tf` | Output values |

## Deployment

### 1. Update terraform.tfvars

Edit `terraform.tfvars` with your Phase 1 outputs:

```hcl
vpc_id = "vpc-XXXXX"  # Your VPC ID

private_subnet_ids = [
  "subnet-XXXXX",  # Your private subnet IDs
  "subnet-XXXXX"
]

database_security_group_id = "sg-XXXXX"  # Your DB security group ID
```

### 2. Deploy

```bash
cd 03-database-layer

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy (takes ~5-10 minutes for RDS)
terraform apply
```

### 3. View Outputs

```bash
# See connection details
terraform output database_summary

# Get credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id taskflow-dev-db-credentials \
  --query SecretString --output text | jq
```

## Cost Estimate

| Resource | Cost |
|----------|------|
| RDS db.t3.micro | ~$0.02/hour (~$15/month) |
| Secrets Manager | ~$0.40/month per secret |
| CloudWatch Alarms | Free (basic) |

**Cost Tip**: Run `terraform destroy` when not actively learning to stop charges!

## Connecting Your App

### Option 1: Direct Connection String (Development)

Set in `.env`:
```bash
DATABASE_URL=postgresql://taskflow_admin:PASSWORD@RDS_ENDPOINT:5432/taskflow
```

### Option 2: Secrets Manager (Production)

Set in `.env`:
```bash
USE_SECRETS_MANAGER=true
DB_SECRET_NAME=taskflow-dev-db-credentials
AWS_REGION=us-east-1
```

The app will automatically fetch credentials from Secrets Manager.

## Testing the Connection

```bash
# Install PostgreSQL client
brew install postgresql  # macOS

# Connect to RDS (must have network access)
psql "postgresql://taskflow_admin:PASSWORD@RDS_ENDPOINT:5432/taskflow"
```

**Note**: RDS is in private subnets, so you can't connect directly from your laptop. You'll need:
- A bastion host in a public subnet, OR
- AWS Systems Manager Session Manager, OR
- VPN connection to the VPC

## RDS Features Explained

### Storage Autoscaling
```hcl
max_allocated_storage = 100  # Can grow up to 100GB automatically
```

### Performance Insights
Free tier gives you 7 days of performance data to troubleshoot slow queries.

### Encryption
```hcl
storage_encrypted = true  # Encrypts data at rest using AWS-managed KMS key
```

### Automated Backups
```hcl
backup_retention_period = 1  # Keep daily backups for 1 day
```

## Cleanup

```bash
terraform destroy
```

This destroys:
- RDS instance (stops billing immediately)
- DB subnet group
- Secrets Manager secret
- CloudWatch alarms

## Next Phase

**Phase 4: Container Registry (ECR)** - Push Docker images to AWS for deployment.
