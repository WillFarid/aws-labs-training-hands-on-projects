variable "env_prefix" {
  type        = string
  description = "Environment identifier used for naming resources (e.g., production, staging)"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the main VPC network"
}

variable "azs" {
  type        = list(string)
  description = "List of Availability Zones for high availability deployment"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the private application subnets"
}

variable "database_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the isolated database subnets"
}