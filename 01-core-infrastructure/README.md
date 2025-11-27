# Phase 1: Core Infrastructure (VPC & IAM)

This phase sets up the foundational AWS infrastructure that all other services will use.

## What You'll Learn

- **VPC (Virtual Private Cloud)**: Your isolated network in AWS
- **Subnets**: Public vs Private network segments
- **Internet Gateway**: Allows internet access to public resources
- **NAT Gateway**: Allows private resources to reach the internet
- **Route Tables**: Traffic routing rules
- **Security Groups**: Virtual firewalls
- **IAM Roles & Policies**: Permissions for AWS services

## Architecture

```
                              Internet
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │    Internet Gateway     │
                    └───────────┬─────────────┘
                                │
        ┌───────────────────────┴───────────────────────┐
        │                     VPC                        │
        │              10.0.0.0/16                       │
        │                                                │
        │  ┌──────────────────┐  ┌──────────────────┐   │
        │  │  Public Subnet   │  │  Public Subnet   │   │
        │  │   10.0.1.0/24    │  │   10.0.2.0/24    │   │
        │  │    us-east-1a    │  │    us-east-1b    │   │
        │  │                  │  │                  │   │
        │  │  ┌────────────┐  │  │                  │   │
        │  │  │NAT Gateway │  │  │                  │   │
        │  │  └─────┬──────┘  │  │                  │   │
        │  └────────┼─────────┘  └──────────────────┘   │
        │           │                                    │
        │           ▼                                    │
        │  ┌──────────────────┐  ┌──────────────────┐   │
        │  │ Private Subnet   │  │ Private Subnet   │   │
        │  │  10.0.10.0/24    │  │  10.0.11.0/24    │   │
        │  │    us-east-1a    │  │    us-east-1b    │   │
        │  │                  │  │                  │   │
        │  │ [App Servers]    │  │ [App Servers]    │   │
        │  │ [Databases]      │  │ [Databases]      │   │
        │  └──────────────────┘  └──────────────────┘   │
        │                                                │
        └────────────────────────────────────────────────┘
```

## Files Explained

| File | Purpose |
|------|---------|
| `providers.tf` | Configures Terraform and AWS provider |
| `variables.tf` | Defines input variables with defaults |
| `terraform.tfvars` | Actual values for variables |
| `vpc.tf` | VPC, subnets, gateways, route tables |
| `security_groups.tf` | Firewall rules for ALB, App, Database |
| `iam.tf` | IAM roles for ECS and Lambda |
| `outputs.tf` | Values exported after apply |

## Key Concepts

### VPC (Virtual Private Cloud)
Your own isolated network in AWS. You control:
- IP address range (CIDR block)
- Subnets
- Route tables
- Gateways

### Subnets

| Type | Internet Access | Use For |
|------|-----------------|---------|
| **Public** | Direct (via IGW) | Load Balancers, Bastion Hosts |
| **Private** | Outbound only (via NAT) | App Servers, Databases |

### Security Groups vs NACLs

| Feature | Security Groups | NACLs |
|---------|-----------------|-------|
| Level | Instance/ENI | Subnet |
| State | Stateful | Stateless |
| Rules | Allow only | Allow & Deny |
| Default | Deny all in | Allow all |

### IAM Roles

| Role | Used By | Purpose |
|------|---------|---------|
| ECS Task Execution | ECS Service | Pull images, write logs |
| ECS Task | Your containers | Access S3, Secrets Manager |
| Lambda Execution | Lambda functions | CloudWatch, VPC access |

## Cost Breakdown

| Resource | Cost | Notes |
|----------|------|-------|
| VPC | Free | No charge for VPC itself |
| Subnets | Free | No charge |
| Internet Gateway | Free | No charge |
| **NAT Gateway** | ~$0.045/hour | **~$32/month if running 24/7** |
| Elastic IP | Free* | Free when attached to running NAT |
| Security Groups | Free | No charge |
| IAM Roles | Free | No charge |

**Total: ~$0.045/hour while NAT Gateway is running**

### Cost Saving Tips

1. **Destroy when not learning**: `terraform destroy`
2. **Remove NAT Gateway**: Comment out NAT resources in `vpc.tf` (private subnets won't have internet access)
3. **Use 1 AZ**: Change to single availability zone

## Usage

### 1. Initialize Terraform

```bash
cd 01-core-infrastructure
terraform init
```

This downloads the AWS provider plugin.

### 2. Preview Changes

```bash
terraform plan
```

Review what will be created (no changes made yet).

### 3. Apply Changes

```bash
terraform apply
```

Type `yes` when prompted. This creates all resources.

### 4. View Outputs

```bash
terraform output
```

### 5. Destroy (When Done Learning)

```bash
terraform destroy
```

**IMPORTANT**: Always destroy to avoid ongoing charges!

## Common Commands

```bash
# Format code
terraform fmt

# Validate configuration
terraform validate

# Show current state
terraform show

# List resources in state
terraform state list

# View specific output
terraform output vpc_id
```

## Understanding the State File

Terraform creates `terraform.tfstate` to track created resources. This file:
- Maps Terraform config to real AWS resources
- Should NEVER be edited manually
- Should be stored securely (contains sensitive data)
- In production: use remote backend (S3 + DynamoDB)

## Security Group Flow

```
Internet → ALB (port 80/443) → App (port 8000) → Database (port 5432)
    ↑           ↑                    ↑                  ↑
    │           │                    │                  │
 0.0.0.0/0   alb-sg              app-sg              db-sg
             allows              allows              allows
             80,443              8000 from           5432 from
             from any            alb-sg              app-sg
```

## Terraform Workflow

```
┌─────────────────┐
│  Write .tf      │
│  files          │
└────────┬────────┘
         ▼
┌─────────────────┐
│  terraform init │ ← Downloads providers
└────────┬────────┘
         ▼
┌─────────────────┐
│  terraform plan │ ← Preview changes
└────────┬────────┘
         ▼
┌─────────────────┐
│ terraform apply │ ← Create resources
└────────┬────────┘
         ▼
┌─────────────────┐
│    .tfstate     │ ← State file created
└─────────────────┘
```

## Next Steps

After completing this phase:

1. ✅ VPC with public/private subnets
2. ✅ Internet and NAT gateways
3. ✅ Security groups for ALB, App, Database
4. ✅ IAM roles for ECS and Lambda

**Phase 2**: We'll add S3 for file storage and update the FastAPI app to use it instead of local storage.

## Troubleshooting

### "Error: Invalid provider configuration"
Run `aws configure` and ensure credentials are set.

### "Error: creating VPC: VpcLimitExceeded"
You've hit the VPC limit (default 5). Delete unused VPCs in AWS Console.

### "Error: creating NAT Gateway: insufficient permissions"
Your IAM user needs `ec2:*` permissions. Use AdministratorAccess for learning.

### Costs running up?
```bash
terraform destroy
```
Always destroy when not actively learning!
