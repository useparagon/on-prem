resource "aws_acm_certificate" "ssl" {
  count               = var.ssl_domain != "" ? 1 : 0
  domain_name         = "*.${var.ssl_domain}"
  validation_method   = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags, {
    Name              = "${local.app_name}-ssl"
  })
}
