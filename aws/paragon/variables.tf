variable "app_name" {
  description = "The name of the application."
}

variable "environment" {
  description = "The development environment (sandbox, development, staging, production)"
}

variable "ssl_certificate" {
  description = "The ssl certificate for signing requests."
}

variable "aws_region" {
  description = "The AWS region things are created in."
}

variable "az_count" {
  description = "Number of AZs to cover in a given region."
}

variable "health_check_path" {
  description = "The path to make requests to for verifying container health."
  default     = "/healthz"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)."
  default     = "1024"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)."
  default     = "2048"
}

variable "vpc_id" {
  description = "The id of the VPC the app is in."
}

variable "public_subnet" {
  description = "Public subnet within the VPC."
}

variable "private_subnet" {
  description = "Private subnet within the VPC."
}