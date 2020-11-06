resource "aws_s3_bucket" "app" {
  bucket = "${var.environment}-${var.app_name}"
  acl    = "private"

  tags = {
    Name        = "${var.environment}-${var.app_name}-app-s3"
    Environment = var.environment
    Terraform   = "true"
  }
}