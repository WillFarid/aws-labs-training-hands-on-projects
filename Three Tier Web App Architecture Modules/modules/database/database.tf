# ==========================================
# 1. DB SUBNET GROUP (Multi-AZ Isolation)
# ==========================================

# This groups the isolated subnets so RDS knows where it can deploy across multiple AZs
resource "aws_db_subnet_group" "main" {
  name        = "${var.env_prefix}-db-subnet-group"
  subnet_ids  = var.database_subnet_ids
  description = "Database subnet group for high availability across isolated subnets"

  tags = {
    Name        = "${var.env_prefix}-db-subnet-group"
    Environment = var.env_prefix
  }
}


# ==========================================
# 2. RDS DATABASE INSTANCE (MySQL)
# ==========================================

resource "aws_db_instance" "main" {
  identifier     = "${var.env_prefix}-mysql-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage     = 20
  max_allocated_storage = 100 # Enables Storage Autoscaling
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Security and Network isolation
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false # CRITICAL: Ensures database is completely isolated from the internet

  # Enterprise Backup and Maintenance settings
  multi_az               = true # High Availability across multiple AZs
  skip_final_snapshot    = true # Set to false in strict production if you want a snapshot on destruction
  backup_retention_period = 7   # Keep automated backups for 7 days
  deletion_protection    = false # Set to true in strict production to prevent accidental deletion

  tags = {
    Name        = "${var.env_prefix}-mysql-db"
    Environment = var.env_prefix
  }
}