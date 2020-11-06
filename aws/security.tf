resource "aws_security_group" "alb" {
  name        = "${var.environment}-${var.app_name}-alb-sg"
  description = "Controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound secure HTTP traffic from anywhere."
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound nonsecure HTTP traffic from anywhere."
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Allow outbound HTTP traffic to the public subnet."
    protocol        = "tcp"
    from_port       = 1700
    to_port         = 1704
    cidr_blocks     = aws_subnet.public.*.cidr_block
  }

  egress {
    description     = "Allow outbound HTTP traffic to the private subnet."
    protocol        = "tcp"
    from_port       = 1700
    to_port         = 1704
    cidr_blocks     = aws_subnet.private.*.cidr_block
  }

  tags = {
    Name        = "${var.environment}-${var.app_name}-alb-access"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_security_group" "ec2" {
  name              = "${var.environment}-${var.app_name}-ec2-sg"
  description       = "Controls access from the ALB"
  vpc_id            = aws_vpc.main.id

  ingress {
    description     = "Allow inbound SSH traffic"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow inbound HTTP traffic from the alb"
    protocol        = "tcp"
    from_port       = 1700
    to_port         = 1704
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Allow inbound HTTP traffic from services in the public subnet."
    protocol        = "tcp"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = aws_subnet.public.*.cidr_block
  }

  ingress {
    description     = "Allow inbound HTTP traffic from services in the private subnet."
    protocol        = "tcp"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = aws_subnet.private.*.cidr_block
  }

  egress {
    description     = "Allow all outbound traffic."
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name            = "${var.environment}-${var.app_name}-ec2-sg"
    Environment     = var.environment
    Terraform       = "true"
  }
}

resource "aws_security_group" "elasticache" {
  name_prefix       = "${var.environment}-${var.app_name}-elasticache"
  description       = "Security access rules for Elasticache."
  vpc_id            = aws_vpc.main.id

  ingress {
    description     = "Allow inbound traffic from services in the public subnet on port 6379."
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    cidr_blocks     = aws_subnet.public.*.cidr_block
  }

  ingress {
    description     = "Allow inbound traffic from services in the private subnet on port 6379."
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    cidr_blocks     = aws_subnet.private.*.cidr_block
  }

  egress {
    description     = "Allow all outbound traffic."
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name            = "${var.environment}-${var.app_name}-elasticache-security-group"
    Environment     = var.environment
    Terraform       = "true"
  }
}

resource "aws_security_group" "postgres" {
  name_prefix       = "${var.environment}-${var.app_name}-postgres"
  description       = "Security access rules for Postgres."
  vpc_id            = aws_vpc.main.id

  ingress {
    description     = "Allow inbound traffic from services in the public subnet on port 5432."
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = aws_subnet.public.*.cidr_block
  }

  ingress {
    description     = "Allow inbound traffic from services in the private subnet on port 5432."
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = aws_subnet.private.*.cidr_block
  }

  egress {
    description     = "Allow all outbound traffic."
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name            = "${var.environment}-${var.app_name}-postgres-security-group"
    Environment     = var.environment
    Terraform       = "true"
  }
}