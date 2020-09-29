data "aws_acm_certificate" "ssl" {
  domain   = "*.${var.ssl_domain}"
  statuses = ["ISSUED"]
}
