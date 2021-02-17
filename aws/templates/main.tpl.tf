terraform {
  required_version = "= 0.13.2"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  __TF_CONFIG__ {}
}