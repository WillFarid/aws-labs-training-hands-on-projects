output "alb_sg_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the ALB Security Group"
}

output "app_sg_id" {
  value       = aws_security_group.app.id
  description = "The ID of the App Servers Security Group"
}

output "database_sg_id" {
  value       = aws_security_group.database.id
  description = "The ID of the Database Security Group"
}

output "app_instance_profile_name" {
  value       = aws_iam_instance_profile.app_instance_profile.name
  description = "The IAM Instance Profile name for application servers"
}