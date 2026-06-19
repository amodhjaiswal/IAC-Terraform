# VPC 
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.env_name}-vpc" }
  )
}

# Public subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.env_name}-public-${count.index + 1}" }
  )
}

# Private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.env_name}-private-${count.index + 1}" }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-${var.env_name}-igw" })
}

# NAT Gateway EIPs
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${var.project_name}-${var.env_name}-nat-eip-${count.index + 1}" })
}

# NAT Gateways
resource "aws_nat_gateway" "this" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(local.common_tags, { Name = "${var.project_name}-${var.env_name}-nat-${count.index + 1}" })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-${var.env_name}-public-rt" })
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ)
resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main_vpc.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-${var.env_name}-private-rt-${count.index + 1}" })
}

resource "aws_route" "private_nat_access" {
  count                  = length(aws_subnet.private)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index % 2].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Local tags
locals {
  common_tags = merge(
    {
      Name        = var.project_name
      Environment = var.env_name
    },
    var.tags
  )
}