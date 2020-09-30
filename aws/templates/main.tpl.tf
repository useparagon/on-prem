terraform {
  required_version = "= 0.13.2"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "__TF_BUCKET__"
    key            = "__TF_STATE_KEY__"
    region         = "__AWS_REGION__"
  }
}