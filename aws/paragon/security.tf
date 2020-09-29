resource "aws_security_group" "alb" {
  name        = "${var.environment}-${var.app_name}-alb-sg"
  description = "Controls access to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound secure HTTP traffic from anywhere."
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic to the EC2 service."
    protocol    = "tcp"
    from_port   = 1700
    to_port     = 1704
    security_groups = [aws_security_group.ec2.id]
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
  vpc_id            = var.vpc_id

  ingress {
    description     = "Allow inbound HTTP traffic from the alb"
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Allow inbound HTTP traffic from services in the private subnet."
    protocol        = "tcp"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = var.private_subnet.*.cidr_block
  }

  ingress {
    description     = "Allow inbound HTTP traffic from the bastion."
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [var.aws_security_groups.bastion.id]
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
