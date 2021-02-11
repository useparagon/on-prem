resource "aws_alb" "microservice" {
  for_each        = local.microservices
  name            = "${local.app_name}-${each.key}-alb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.alb.id]
}

resource "aws_alb_target_group" "microservice" {
  for_each              = local.microservices
  name                  = "${local.app_name}-${each.key}"
  port                  = each.value
  protocol              = "HTTP"
  vpc_id                = data.aws_vpc.selected.id
  target_type           = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "60"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "10"
    path                = var.health_check_path
    unhealthy_threshold = "5"
  }
}

resource "aws_alb_target_group_attachment" "microservice" {
  for_each         = local.microservices
  target_group_arn = aws_alb_target_group.microservice[each.key].arn
  target_id        = element(
    values(aws_instance.ec2).*.private_ip,
    index(flatten([
      for key, value in local.ec2s : contains(value, each.key)
    ]), true)
  )
  port             = each.value
}

resource "aws_alb_listener" "microservice_https" {
  for_each          = var.ssl_domain != "" ? local.microservices : {}
  load_balancer_arn = aws_alb.microservice[each.key].id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.ssl[0].arn

  default_action {
    target_group_arn = aws_alb_target_group.microservice[each.key].id
    type             = "forward"
  }
}

resource "aws_alb_listener" "microservice_http" {
  for_each          = var.ssl_domain == "" ? local.microservices : {}
  load_balancer_arn = aws_alb.microservice[each.key].id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.microservice[each.key].id
    type             = "forward"
  }
}
