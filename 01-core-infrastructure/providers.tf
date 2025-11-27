# =============================================================================
# TERRAFORM PROVIDERS
# =============================================================================
# This file configures the providers (cloud platforms) Terraform will use.
# A provider is a plugin that lets Terraform manage resources on a platform.

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
# Terraform will use credentials from ~/.aws/credentials (configured via `aws configure`)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "TaskFlow"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
