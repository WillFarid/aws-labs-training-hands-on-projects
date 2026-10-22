variable "env_prefix" {
  type        = string
  description = "Environment identifier used for naming security resources"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where security groups will be created"
}