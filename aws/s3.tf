resource "aws_s3_bucket" "app" {
  bucket = local.app_name
  acl    = "private"

  tags   = local.default_tags
}

resource "aws_iam_user" "app" {
  name              = "${local.app_name}-s3-user"

  tags              = merge(local.default_tags, {
    Name            = "${local.app_name}-s3-system"
  })
}

resource "aws_iam_access_key" "app" {
  user              = aws_iam_user.app.name
}

resource "aws_iam_user_policy" "app" {
  name              = "${local.app_name}-s3-policy"
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