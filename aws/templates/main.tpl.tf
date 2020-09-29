terraform {
  required_version = "= 0.13.2"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "remote" {
    hostname       = "app.terraform.io"
    organization   = "__TF_ORGANIZATION__"

    workspaces {
      name         = "__TF_WORKSPACE__"
    }
  }
}