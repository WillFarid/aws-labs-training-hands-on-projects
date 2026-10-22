output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the created VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of IDs for the public subnets"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of IDs for the private application subnets"
}

output "database_subnet_ids" {
  value       = aws_subnet.database[*].id
  description = "List of IDs for the isolated database subnets"
}