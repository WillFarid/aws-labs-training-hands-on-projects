variable "env_prefix" {
  type        = string
  description = "Environment identifier used for naming database resources"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where the database will be deployed"
}

variable "database_subnet_ids" {
  type        = list(string)
  description = "List of isolated database subnet IDs across multiple AZs"
}

variable "db_sg_id" {
  type        = string
  description = "Security Group ID allowed to access the database"
}

variable "db_name" {
  type        = string
  default     = "webappdb"
  description = "The name of the initial database to create"
}

variable "db_username" {
  type        = string
  default     = "adminuser"
  description = "Master username for the database"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Master password for the database (should be passed securely via environment or tfvars)"
}

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "RDS instance class size"
}