resource "aws_alb" "microservice" {
  for_each        = var.microservices
  name            = "${var.environment}-${var.app_name}-${each.key}-alb"
  subnets         = var.public_subnet.*.id
  security_groups = [aws_security_group.alb.id]
}

resource "aws_alb_target_group" "microservice" {
  for_each    = var.microservices
  name        = "${var.environment}-${var.app_name}-${each.key}-alb-group"
  port        = each.value
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

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

resource "aws_alb_listener" "microservice_https" {
  for_each          = var.microservices
  load_balancer_arn = aws_alb.main.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.ssl.arn

  default_action {
    target_group_arn = aws_alb_target_group.microservice[index(var.microservices, each.value)].id
    type             = "forward"
  }
}

resource "aws_alb_listener" "microservice_http" {
  for_each          = var.microservices
  load_balancer_arn = aws_alb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.microservice[index(var.microservices, each.value)].id
    type             = "forward"
  }
}
