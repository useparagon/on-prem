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

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  default     = "10.0.0.0/16"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)."
  default     = "1024"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)."
  default     = "2048"
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

variable "ssl_domain" {
  description = "The domain that your SSL certificate is registered to."
  default     = ""
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