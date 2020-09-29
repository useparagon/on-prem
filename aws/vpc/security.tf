resource "aws_security_group" "bastion" {
  name              = "${var.environment}-${var.app_name}-bastion"
  description       = "Security access rules in and out of the bastion server."
  vpc_id            = aws_vpc.main.id

  ingress {
    description     = "Allow inbound SSH traffic"
    from_port       = 22
    to_port         = 22
    protocol        = "ssh"
    // TODO: optional filter by ip address
  }

  egress {
    description     = "Allow outbound TCP to Redis instances in private network."
    from_port       = 6379
    to_port         = 6379
    protocol        = "TCP"
    cidr_blocks     = aws_subnet.private.*.cidr_block
  }

  egress {
    description     = "Allow outbound TCP to Postgres instances in private network."
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = aws_subnet.private.*.cidr_block
  }

  egress {
    description     = "Allow outbound TCP to Paragon instance in private network."
    from_port       = 1700
    to_port         = 1704
    protocol        = "tcp"
    cidr_blocks     = aws_subnet.private.*.cidr_block
  }

  tags = {
    Name            = "${var.environment}-${var.app_name}-bastion-security-group"
    Environment     = var.environment
    Terraform       = "true"
  }
}