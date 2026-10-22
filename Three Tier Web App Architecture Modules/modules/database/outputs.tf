output "db_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "The connection endpoint for the database (Host:Port)"
}

output "db_address" {
  value       = aws_db_instance.main.address
  description = "The hostname of the RDS instance"
}

output "db_name" {
  value       = aws_db_instance.main.db_name
  description = "The name of the database"
}