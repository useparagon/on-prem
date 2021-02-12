locals {
  alb_security_groups = {
    private = aws_security_group.alb_private
    public  = aws_security_group.alb_public
  }
}

resource "aws_security_group" "alb_private" {
  name        = "${local.app_name}-alb-private"
  description = "Allows whitelisted access to the alb."
  vpc_id      = data.aws_vpc.selected.id

  tags              = merge(local.default_tags, {
    Name            = "${local.app_name}-alb-private"
  })
}

resource "aws_security_group" "alb_public" {
  name        = "${local.app_name}-alb-public"
  description = "Allows public access to the alb."
  vpc_id      = data.aws_vpc.selected.id

  tags              = merge(local.default_tags, {
    Name            = "${local.app_name}-alb-public"
  })
}

resource "aws_security_group_rule" "ingress_private" {
  description               = "Allow inbound traffic from whitelisted ips."
  type                      = "ingress"
  protocol                  = "tcp"
  from_port                 = var.ssl_domain != "" ? 443 : 80
  to_port                   = var.ssl_domain != "" ? 443 : 80
  security_group_id         = aws_security_group.alb_private.id
  cidr_blocks               = var.ip_whitelist
}

resource "aws_security_group_rule" "ingress_public" {
  description               = "Allow inbound traffic from anywhere."
  type                      = "ingress"
  protocol                  = "tcp"
  from_port                 = var.ssl_domain != "" ? 443 : 80
  to_port                   = var.ssl_domain != "" ? 443 : 80
  security_group_id         = aws_security_group.alb_public.id
  cidr_blocks               = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_alb_private" {
  for_each                  = local.alb_security_groups
  description               = "Allow inbound traffic from the private albs."
  type                      = "ingress"
  protocol                  = "tcp"
  from_port                 = var.ssl_domain != "" ? 443 : 80
  to_port                   = var.ssl_domain != "" ? 443 : 80
  security_group_id         = each.value.id
  source_security_group_id  = aws_security_group.alb_private.id
}

resource "aws_security_group_rule" "ingress_alb_public" {
  for_each                  = local.alb_security_groups
  description               = "Allow inbound traffic from the public albs."
  type                      = "ingress"
  protocol                  = "tcp"
  from_port                 = var.ssl_domain != "" ? 443 : 80
  to_port                   = var.ssl_domain != "" ? 443 : 80
  security_group_id         = each.value.id
  source_security_group_id  = aws_security_group.alb_public.id
}

resource "aws_security_group_rule" "egress_public_subnet" {
  for_each          = local.alb_security_groups
  description       = "Allow outbound HTTP traffic to the public subnet."
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 9999
  cidr_blocks       = aws_subnet.public.*.cidr_block
  security_group_id = each.value.id
}

resource "aws_security_group_rule" "egress_private_subnet" {
  for_each          = local.alb_security_groups
  description       = "Allow outbound HTTP traffic to the private subnet."
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 9999
  cidr_blocks       = aws_subnet.private.*.cidr_block
  security_group_id = each.value.id
}

resource "aws_security_group" "ec2" {
  name              = "${local.app_name}-ec2-sg"
  description       = "Controls access from the ALB"
  vpc_id            = data.aws_vpc.selected.id

  ingress {
    description     = "Allow inbound SSH traffic from whitelisted IPs."
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    cidr_blocks     = var.ip_whitelist
  }

  ingress {
    description     = "Allow inbound HTTP traffic from the alb."
    protocol        = "tcp"
    from_port       = 80
    to_port         = 9999
    security_groups = [aws_security_group.alb_private.id, aws_security_group.alb_public.id]
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

  tags              = merge(local.default_tags, {
    Name            = "${local.app_name}-ec2-sg"
  })
}

resource "aws_security_group" "elasticache" {
  name_prefix       = "${local.app_name}-elasticache"
  description       = "Security access rules for Elasticache."
  vpc_id            = data.aws_vpc.selected.id

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

  tags              = merge(local.default_tags, {
    Name            = "${local.app_name}-elasticache-security-group"
  })
}

resource "aws_security_group" "postgres" {
  name_prefix       = "${local.app_name}-postgres"
  description       = "Security access rules for Postgres."
  vpc_id            = data.aws_vpc.selected.id

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

  tags              = merge(local.default_tags, {
    Name            = "${local.app_name}-postgres-security-group"
  })
}