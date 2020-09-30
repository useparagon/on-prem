resource "aws_acm_certificate" "ssl" {
  count               = var.ssl_domain != "" ? 1 : 0
  domain_name         = "*.${var.ssl_domain}"
  validation_method   = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name              = "${var.environment}-${var.app_name}-ssl"
    Environment       = var.environment
    Terraform         = "true"
  }
}