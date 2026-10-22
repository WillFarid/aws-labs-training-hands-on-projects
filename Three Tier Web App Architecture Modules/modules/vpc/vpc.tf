# Main VPC Resource
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.env_prefix}-vpc"
    Environment = var.env_prefix
    ManagedBy   = "Terraform"
  }
}

# Internet Gateway for Public Subnets internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.env_prefix}-igw"
    Environment = var.env_prefix
  }
}

# Public Subnets across Multi-AZs
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.env_prefix}-public-subnet-${var.azs[count.index]}"
    Environment = var.env_prefix
    Tier        = "Public"
  }
}

# Private Application Subnets across Multi-AZs
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name        = "${var.env_prefix}-private-subnet-${var.azs[count.index]}"
    Environment = var.env_prefix
    Tier        = "Private"
  }
}

# Isolated Database Subnets across Multi-AZs
resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name        = "${var.env_prefix}-database-subnet-${var.azs[count.index]}"
    Environment = var.env_prefix
    Tier        = "Database"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name        = "${var.env_prefix}-nat-eip-${var.azs[count.index]}"
    Environment = var.env_prefix
  }

  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateways for Private Subnets outbound traffic
resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.env_prefix}-nat-gw-${var.azs[count.index]}"
    Environment = var.env_prefix
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.env_prefix}-rt-public"
    Environment = var.env_prefix
  }
}

# Private Route Tables per AZ
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name        = "${var.env_prefix}-rt-private-${var.azs[count.index]}"
    Environment = var.env_prefix
  }
}

# Isolated Database Route Table (No internet route)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.env_prefix}-rt-database"
    Environment = var.env_prefix
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Route Table Associations for Database Subnets
resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}