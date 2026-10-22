output "storage_bucket_name" {
  value       = aws_s3_bucket.app_storage.id
  description = "The name of the secure S3 storage bucket"
}

output "storage_bucket_arn" {
  value       = aws_s3_bucket.app_storage.arn
  description = "The ARN of the secure S3 storage bucket for IAM policies"
}