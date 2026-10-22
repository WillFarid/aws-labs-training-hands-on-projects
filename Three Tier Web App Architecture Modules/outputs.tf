output "load_balancer_url" {
  value       = module.my_compute.alb_dns_name
  description = "The public URL to access your enterprise 3-tier web application"
}

output "storage_bucket_name" {
  value       = module.my_storage.storage_bucket_name
  description = "The secure S3 storage bucket name for media uploads"
}

output "database_endpoint" {
  value       = module.my_database.db_endpoint
  description = "The internal database connection endpoint for application settings"
  sensitive   = true
}