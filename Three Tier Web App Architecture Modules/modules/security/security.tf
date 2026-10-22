# ==========================================
# 1. SECURITY GROUPS (NETWORK FIREWALL)
# ==========================================

# Public Application Load Balancer (ALB) Security Group
resource "aws_security_group" "alb" {
  name        = "${var.env_prefix}-alb-sg"
  description = "Allow inbound traffic from internet to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env_prefix}-alb-sg"
    Environment = var.env_prefix
  }
}

# Private Application Servers Security Group
resource "aws_security_group" "app" {
  name        = "${var.env_prefix}-app-sg"
  description = "Allow inbound traffic exclusively from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic only from ALB Security Group"
    from_port       = 8080  #أو بورت التطبيق بتاعي
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic for updates and dependencies"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env_prefix}-app-sg"
    Environment = var.env_prefix
  }
}

# Isolated Database Subnets Security Group
resource "aws_security_group" "database" {
  name        = "${var.env_prefix}-db-sg"
  description = "Allow inbound database traffic exclusively from App Servers"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow MySQL/PostgreSQL traffic only from App Security Group"
    from_port       = 3306   #لبورت MySQL ( لو تستخدم بورت تاني زي 5432 لـ Postgres)
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "No outbound needed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env_prefix}-db-sg"
    Environment = var.env_prefix
  }
}


# ==========================================
# 2. IAM ROLES & POLICIES (LEAST PRIVILEGE)
# ==========================================

# IAM Role for App EC2 Instances
resource "aws_iam_role" "app_server_role" {
  name = "${var.env_prefix}-app-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.env_prefix}-app-server-role"
    Environment = var.env_prefix
  }
}

# Attach AWS Managed Policy for CloudWatch Logging
resource "aws_iam_role_policy_attachment" "app_logs_policy" {
  role       = aws_iam_role.app_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance Profile for EC2 Instances
resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "${var.env_prefix}-app-instance-profile"
  role = aws_iam_role.app_server_role.name
}