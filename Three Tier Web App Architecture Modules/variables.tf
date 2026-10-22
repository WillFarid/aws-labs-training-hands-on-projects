variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region for deployment"
}

variable "env_prefix" {
  type        = string
  default     = "production"
  description = "Environment name prefix used across all resources"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Master password for the database (passed securely)"
}