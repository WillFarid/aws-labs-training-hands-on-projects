# ==========================================
# SECURE S3 BUCKET FOR APPLICATION STORAGE
# ==========================================

# 1. Main S3 Bucket Resource
resource "aws_s3_bucket" "app_storage" {
  bucket        = "${var.env_prefix}-app-media-storage-bucket-2026"
  force_destroy = false 

  tags = {
    Name        = "${var.env_prefix}-app-storage"
    Environment = var.env_prefix
  }
}

# 2. Enable Versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Enable Server-Side Encryption by Default (Updated for AWS Provider v5+)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.app_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Strict Public Access Block
resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket                  = aws_s3_bucket.app_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}