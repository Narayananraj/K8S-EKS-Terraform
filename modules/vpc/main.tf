resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "nr-${var.project}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "nr-${var.project}-${var.environment}-igw"
  }
}

# ---------- Public subnets (for_each over AZ map) ----------
resource "aws_subnet" "public" {
  for_each = var.azs

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value.public_cidr
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "nr-${var.project}-${var.environment}-public-${each.key}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ---------- Private subnets ----------
resource "aws_subnet" "private" {
  for_each = var.azs

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value.private_cidr

  tags = {
    Name                                        = "nr-${var.project}-${var.environment}-private-${each.key}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ---------- NAT Gateway(s) — cost lever ----------
resource "aws_eip" "nat" {
  for_each = var.single_nat_gateway ? { "shared" = tolist(keys(var.azs))[0] } : var.azs

  domain = "vpc"

  tags = {
    Name = "nr-${var.project}-${var.environment}-nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each = var.single_nat_gateway ? { "shared" = tolist(keys(var.azs))[0] } : var.azs

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value].id

  tags = {
    Name = "nr-${var.project}-${var.environment}-nat-${each.key}"
  }

  depends_on = [aws_internet_gateway.this]
}

# ---------- Route tables ----------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "nr-${var.project}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = var.azs

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this["shared"].id : aws_nat_gateway.this[each.key].id
  }

  tags = {
    Name = "nr-${var.project}-${var.environment}-private-rt-${each.key}"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# ---------- S3 Gateway Endpoint (free — cost lever) ----------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id], [for rt in aws_route_table.private : rt.id])

  tags = {
    Name = "nr-${var.project}-${var.environment}-s3-endpoint"
  }
}

data "aws_region" "current" {}
