variable "env_prefix" {
  type        = string
  description = "Environment identifier used for naming compute resources"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where compute resources will be deployed"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the Load Balancer"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the application servers"
}

variable "alb_sg_id" {
  type        = string
  description = "Security Group ID for the Application Load Balancer"
}

variable "app_sg_id" {
  type        = string
  description = "Security Group ID for the application servers"
}

variable "app_instance_profile_name" {
  type        = string
  description = "IAM instance profile name for the application servers"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for the application servers"
}