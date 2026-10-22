# ==========================================
# 1. APPLICATION LOAD BALANCER (ALB)
# ==========================================

# Public ALB in Public Subnets
resource "aws_lb" "main" {
  name               = "${var.env_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.env_prefix}-alb"
    Environment = var.env_prefix
  }
}

# Target Group for App Servers
resource "aws_lb_target_group" "app" {
  name     = "${var.env_prefix}-app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "8080"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name        = "${var.env_prefix}-app-tg"
    Environment = var.env_prefix
  }
}

# ALB Listener for HTTP (Port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


# ==========================================
# 2. AUTO SCALING GROUP (ASG) & LAUNCH TEMPLATE
# ==========================================

# Data source to get the latest secure Amazon Linux 2 AMI automatically
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Launch Template for Application Servers
resource "aws_launch_template" "app" {
  name_prefix   = "${var.env_prefix}-app-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
  }

  iam_instance_profile {
    name = var.app_instance_profile_name
  }

  # User data script that runs when the server boots up in AWS
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install python3.8 -y
              yum install httpd -y
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Enterprise 3-Tier Web App on AWS - Environment: ${var.env_prefix}</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.env_prefix}-app-server"
      Environment = var.env_prefix
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group (ASG) across Private Subnets
resource "aws_autoscaling_group" "app" {
  name_prefix         = "${var.env_prefix}-app-asg-"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "EC2"

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.env_prefix}-app-asg-node"
    propagate_at_launch = true
  }
}