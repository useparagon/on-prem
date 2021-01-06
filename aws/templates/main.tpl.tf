terraform {
  required_version = "= 0.13.2"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "local" {
    path = "../../.secure/terraform.tfstate"
  }
}