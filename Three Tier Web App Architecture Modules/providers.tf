terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  # Mock Keys Only, Prod project uses en-vars, roles, CLI, Secrets Manager,HashiCorp Vault
  # الخواص السحرية لتجاوز الاتصال بأمازون محلياً والاعتماد على المفاتيح الوهمية
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_key"
  secret_key                  = "mock_key"

  default_tags {
    tags = {
      Project     = "Enterprise-3Tier-App"
      Environment = var.env_prefix
      ManagedBy   = "Terraform"
    }
  }
}