variable "app_name" {
  description = "The name of the application."
  default     = "paragon-on-prem"
}

variable "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production)."
  default     = "production"
}

variable "aws_region" {
  description = "The AWS region resources are created in."
}

variable "aws_access_key_id" {
  description = "AWS Access Key for AWS account to provision resources on."
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for AWS account to provision resources on."
}

variable "az_count" {
  description = "Number of AZs to cover in a given region."
  default     = "2"
}

variable "public_key" {
  description = "The public key for the EC2 instance and bastion."
}

variable "ssl_domain" {
  description = "The domain that your SSL certificate is registered to."
}

variable "microservices" {
  description   = "A key / value mapping of microservices to ports."
  default       = {
    "cerberus"  = 1700
    "hercules"  = 1701
    "hermes"    = 1702
    "rest-api"  = 1703
    "web-app"   = 1704
  }
}