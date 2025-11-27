# AWS Learning - TaskFlow Project

A hands-on, project-based approach to learning AWS services by building a full-stack task management application.

## Project Overview

**TaskFlow** is a collaborative task management app built incrementally across 13 phases, each introducing new AWS services and concepts.

## Learning Path

| Phase | Folder | Services | Status |
|-------|--------|----------|--------|
| 0 | `00-local-development/` | React, FastAPI, Docker | ✅ Complete |
| 1 | `01-core-infrastructure/` | VPC, IAM | ⏳ Pending |
| 2 | `02-storage-basics/` | S3 | ⏳ Pending |
| 3 | `03-database-layer/` | RDS / DynamoDB | ⏳ Pending |
| 4 | `04-containerization/` | ECR | ⏳ Pending |
| 5 | `05-compute-ecs/` | ECS, Fargate | ⏳ Pending |
| 6 | `06-networking/` | ALB, Route 53, CloudFront | ⏳ Pending |
| 7 | `07-authentication/` | Cognito | ⏳ Pending |
| 8 | `08-serverless-functions/` | Lambda | ⏳ Pending |
| 9 | `09-api-gateway/` | API Gateway, SAM | ⏳ Pending |
| 10 | `10-cicd-pipeline/` | CodePipeline, CodeBuild, CodeDeploy | ⏳ Pending |
| 11 | `11-security-hardening/` | Secrets Manager, KMS | ⏳ Pending |
| 12 | `12-infrastructure-as-code/` | CDK / Terraform | ⏳ Pending |

## Quick Start

### Phase 0: Local Development

```bash
cd 00-local-development

# Option 1: Docker
docker compose up --build

# Option 2: Manual
# Backend
cd backend && python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python -m uvicorn app.main:app --reload

# Frontend (new terminal)
cd frontend && pnpm install && pnpm dev
```

- Frontend: http://localhost:5173
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## Architecture Evolution

```
Phase 0 (Local):
┌─────────┐     ┌─────────┐     ┌─────────┐
│  React  │────▶│ FastAPI │────▶│ SQLite  │
└─────────┘     └─────────┘     └─────────┘

Phase 12 (Full AWS):
┌─────────────────────────────────────────────────────────────┐
│                      Route 53 (DNS)                         │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 CloudFront (CDN + S3 Static)                │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    ALB (Load Balancer)                      │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              ECS Fargate (FastAPI Containers)               │
│                    + Cognito Auth                           │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│          RDS/DynamoDB + S3 (Files) + Lambda (Tasks)         │
└─────────────────────────────────────────────────────────────┘
```

## Estimated AWS Cost

Total: ~$10 for the complete learning path

| Phase | Cost |
|-------|------|
| 0-1 | $0.50 |
| 2 | $0.50 |
| 3 | $2.00 |
| 4 | Free |
| 5 | $2-3 |
| 6 | $1.00 |
| 7-9 | Free tier |
| 10-11 | $0.50 |
| 12 | Free |

**Tip**: Destroy resources after each phase to minimize costs!

## Prerequisites

- AWS Account
- AWS CLI installed and configured
- Docker
- Node.js 20+ with pnpm
- Python 3.11+
