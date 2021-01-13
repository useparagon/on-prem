data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block            = var.vpc_cidr
  enable_dns_hostnames  = true
  enable_dns_support    = true

  tags                  = merge(local.default_tags, {
    Name                = "${var.environment}-${var.app_name}-vpc"
  })
}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  tags                    = merge(local.default_tags, {
    Name                  = "${var.environment}-${var.app_name}-public-subnet"
  })
}

# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false

  tags                    = merge(local.default_tags, {
    Name                  = "${var.environment}-${var.app_name}-private-subnet"
  })
}

resource "aws_eip" "gw" {
  count      = var.az_count
  vpc        = true
  depends_on = [aws_internet_gateway.gw]

  tags       = merge(local.default_tags, {
    Name     = "${var.environment}-${var.app_name}-gw-eip"
  })
}

resource "aws_eip" "ec2" {
  for_each    = local.ec2s
  vpc         = true
  depends_on  = [aws_internet_gateway.gw]

  tags        = merge(local.default_tags, {
    Name      = "${var.environment}-${var.app_name}-ec2-${each.key}-eip"
  })
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id      = aws_vpc.main.id

  tags        = merge(local.default_tags, {
    Name      = "${var.environment}-${var.app_name}-internet-gw"
  })
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Create a NAT gateway with an Elastic IP for each private subnet to get internet connectivity
resource "aws_nat_gateway" "gw" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)

  tags          = merge(local.default_tags, {
    Name        = "${var.environment}-${var.app_name}-nat-gw"
  })
}

# Create a new route table for the private subnets, make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }

  tags          = merge(local.default_tags, {
    Name        = "${var.environment}-${var.app_name}-private-route-table"
  })
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_eip_association" "ec2_eip_assoc" {
  for_each        = local.ec2s
  instance_id     = element(values(aws_instance.ec2).*.id, index(keys(local.ec2s), each.key))
  allocation_id   = element(values(aws_eip.ec2).*.id, index(keys(local.ec2s), each.key))

  depends_on = [aws_instance.ec2, aws_eip.ec2]
}