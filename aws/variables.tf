variable "organization" {
  description = "The name of the organization running the on-prem installation."
}

variable "app_name" {
  description = "An optional name to override the name of the resources created."
  default     = null
}

variable "installation_name_override" {
  description = "Override for the name used for creating resources (legacy support)."
  default     = null
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

variable "ssl_domain" {
  description = "The domain that your SSL certificate is registered to."
  type        = string
  default     = null
}

variable "ssl_only" {
  description = "Whether or not to only accept HTTPS connections."
  type        = bool
  default     = false
}

variable "acl_policy" {
  description = "The access control list for the albs. Must be `public` or `private`."
  type        = string
  default     = "public"
  validation {
    condition     = contains(["public", "private"], var.acl_policy)
    error_message = "The `acl_policy` must be either `public` or `private`."
  }
}

variable "acl_public_services" {
  description = "An optional list of microservices to allow public access to if `acl_policy` is `private`."
  type        = list(string)
  default     = []
  # TODO: validate that the values passed are valid microservices
}

variable "acl_public_ip_override" {
  description = "An optional list of IP addresses to whitelist access public access."
  type        = list(string)  
  default     = ["0.0.0.0./0"]
}

variable "ip_whitelist" {
  description = "An optional list of IP addresses to whitelist access to for microservices with private acl."
  type        = list(string)  
  default     = []
}

variable "alb_external_security_groups" {
  description = "An optional list security groups created outside of Terraform to apply to the albs."
  type        = list(string)
  default     = []
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

  microservice_acls = {
    for key, value in local.microservices:
    key => var.acl_policy == "public" ? "public" : (contains(var.acl_public_services, key) ? "public" : "private")
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

  app_name = var.app_name != null ? var.app_name : "paragon-${var.organization}"

  default_tags  = {
    Name        = local.app_name
    Environment = var.environment
    Terraform   = "true"
  }
}