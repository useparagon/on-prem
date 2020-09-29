module "vpc" {
  source        = "./vpc"

  app_name      = var.app_name
  environment   = var.environment
  az_count      = var.az_count
  public_key    = var.public_key
  ssl_domain    = var.ssl_domain
}

module "storage" {
  source        = "./storage"

  app_name      = var.app_name
  environment   = var.environment
}