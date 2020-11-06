resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-${var.app_name}-elasticache-subnet"
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id                    = "${var.environment}-${var.app_name}-redis"
  engine                        = "redis"
  node_type                     = "cache.r4.xlarge"
  num_cache_nodes               = 1
  parameter_group_name          = "default.redis5.0"
  engine_version                = "5.0.6"
  port                          = 6379
 
  snapshot_retention_limit      = 5
  snapshot_window               = "00:00-05:00"
 
  subnet_group_name             = aws_elasticache_subnet_group.main.name
  security_group_ids            = [aws_security_group.elasticache.id]

  tags = {
    Name                        = "${var.environment}-${var.app_name}-redis"
    Environment                 = var.environment
    Terraform                   = "true"
    Cluster                     = "false"
  }
}