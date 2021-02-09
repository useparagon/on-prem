variable "app_name" {
  description = "The name of the application."
  default     = "paragon"
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

variable "vpc_id" {
  description = "Optional id of an existing VPC to create resources in."
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  default     = "10.0.0.0/16"
}

variable "health_check_path" {
  description = "The path to make requests to for verifying container health."
  default     = "/healthz"
}

variable "public_key" {
  description = "The public key for the EC2 instance."
}

variable "private_key" {
  description = "The private key for the EC2 instance."
}

# Currently unused
variable "ssl_domain" {
  description = "The domain that your SSL certificate is registered to."
  default     = ""
}

variable "postgres_root_username" {
  description = "Username for the Postgres root user."
}

variable "postgres_root_password" {
  description = "Password for the Postgres root user."
}

variable "elasticache_node_type" {
  description = "The ElastiCache node type used for Redis."
}

variable "ec2_instance_type" {
  description = "The EC2 class used for running the installation."
}

variable "rds_instance_class" {
  description = "The RDS instance class type used for Postgres."
}

locals {
  microservices = {
    "cerberus"  = 1700
    "hercules"  = 1701
    "hermes"    = 1702
    "passport"  = 1706
    "rest-api"  = 1703
    "web-app"   = 1704
  }

  ec2s = {
    web         = [
      "cerberus",
      "hercules",
      "hermes",
      "passport",
      "rest-api",
      "web-app",
    ]
  }

  default_tags  = {
    Name        = "${var.environment}-${var.app_name}"
    Environment = var.environment
    Terraform   = "true"
  }
}