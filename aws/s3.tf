resource "aws_s3_bucket" "workflows" {
  bucket = "${var.environment}-${var.app_name}-workflows"
  acl    = "private"

  tags = {
    Name        = "${var.environment}-${var.app_name}-workflows-s3"
    Environment = var.environment
    Terraform   = "true"
  }
}