variable "app_name" {
  description = "The name of the application."
}

variable "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production)."
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region."
}

variable "public_key" {
  description = "The public key for the EC2 instance and bastion."
}

variable "ssl_domain" {
  description = "The domain that your SSL certificate is registered to."
}