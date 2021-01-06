output "albs" { 
  value = {
    for key, value in aws_alb.microservice:
    key => value.dns_name
  }
}

output "ec2" {
  value = {
    public_dns  = aws_eip.ec2.public_dns
    public_ip   = aws_eip.ec2.public_ip
    keys        = aws_key_pair.ec2.key_name
  }
}

output "s3" {
  value = {
    bucket          = aws_s3_bucket.app.bucket
    domain          = aws_s3_bucket.app.bucket_domain_name
    accessKeyId     = aws_iam_access_key.app.id
    accessKeySecret = aws_iam_access_key.app.secret
  }
}

output "elasticache" {
  value         = {
    host        = aws_elasticache_cluster.redis.cache_nodes[0].address
    port        = aws_elasticache_cluster.redis.cache_nodes[0].port
  }
}

output "rds" {
  value         = {
    host        = aws_db_instance.postgres.address
    port        = aws_db_instance.postgres.port
    user        = var.postgres_root_username
    password    = var.postgres_root_password
    database    = aws_db_instance.postgres.name
  }
}