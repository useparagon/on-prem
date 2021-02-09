resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.app_name}-elasticache-subnet"
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id                    = "${local.app_name}-redis"
  engine                        = "redis"
  node_type                     = var.elasticache_node_type
  num_cache_nodes               = 1
  parameter_group_name          = "default.redis5.0"
  engine_version                = "5.0.6"
  port                          = 6379

  apply_immediately             = true
 
  snapshot_retention_limit      = 5
  snapshot_window               = "00:00-05:00"
 
  subnet_group_name             = aws_elasticache_subnet_group.main.name
  security_group_ids            = [aws_security_group.elasticache.id]

  tags                          = merge(local.default_tags, {
    Name                        = "${local.app_name}-redis"
    Cluster                     = "false"
  })
}