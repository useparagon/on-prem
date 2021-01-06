resource "aws_s3_bucket" "app" {
  bucket = "${var.environment}-${var.app_name}"
  acl    = "private"

  tags = {
    Name        = "${var.environment}-${var.app_name}-app-s3"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_iam_user" "app" {
  name              = "${var.environment}-${var.app_name}-s3-user"

  tags = {
    Name            = "${var.environment}-env-${var.app_name}-s3-system"
    Environment     = var.environment
    Creator         = "Terraform"
  }
}

resource "aws_iam_access_key" "app" {
  user              = aws_iam_user.app.name
}

resource "aws_iam_user_policy" "app" {
  name              = "${var.environment}-${var.app_name}-s3-policy"
  user              = aws_iam_user.app.name

  policy            = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowObjectActions",
      "Action": "s3:*Object",
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.app.arn}/*"
    }
  ]
}
EOF
}