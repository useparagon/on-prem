variable "app_name" {
  description = "The name of the application."
  default     = "paragon-on-prem"
}

variable "environment" {
  description = "The development environment (e.g. sandbox, development, staging, production)."
  default     = "production"
}