resource "aws_db_subnet_group" "postgres" {
  name                                      = "${local.app_name}-postgres-subnet"
  description                               = "${local.app_name} postgres subnet group"
  subnet_ids                                = aws_subnet.private.*.id

  tags = {
    Name                                    = "${local.app_name}-postgres-subnet"
    Environment                             = var.environment
    Terraform                               = "true"
  }
}

resource "aws_db_instance" "postgres" {
  identifier                                = local.app_name
  name                                      = "postgres"
  port                                      = "5432"
  username                                  = var.postgres_root_username
  password                                  = var.postgres_root_password

  engine                                    = "postgres"
  engine_version                            = "11.5"
  instance_class                            = var.rds_instance_class
  parameter_group_name                      = aws_db_parameter_group.postgres.name
  storage_type                              = "gp2"
  replicate_source_db                       = null

  allocated_storage                         = 20
  max_allocated_storage                     = 1000
  allow_major_version_upgrade               = false
  auto_minor_version_upgrade                = false
  availability_zone                         = data.aws_availability_zones.available.names[0]
  backup_retention_period                   = 7
  monitoring_interval                       = 0 #specify number higher than 0 to enable pull analytics
  multi_az                                  = false
  backup_window                             = "06:00-07:00"
  maintenance_window                        = "Tue:04:00-Tue:05:00"

  db_subnet_group_name                      = aws_db_subnet_group.postgres.id
  vpc_security_group_ids                    = [aws_security_group.postgres.id]
  publicly_accessible                       = false
  deletion_protection                       = true
  skip_final_snapshot                       = true
  # snapshot_identifier                       = ""
  storage_encrypted                         = true
  
  performance_insights_enabled              = false
  performance_insights_retention_period     = null

  apply_immediately                         = true

  tags                                      = merge(local.default_tags, {
    Name                                    = "${local.app_name}-postgres"
  })
}

resource "aws_db_parameter_group" "postgres" {
  name                                      = "${local.app_name}-postgres"
  family                                    = "postgres11"

  dynamic "parameter" {
    for_each = [
      {
        name            = "log_statement"
        value           = "ddl"
        apply_method    = "pending-reboot"
      },
      {
        name            = "log_min_duration_statement"
        value           = 1000
        apply_method    = "pending-reboot"
      }
    ]
    content {
      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags                                      = merge(local.default_tags, {
    Name                                    = "${local.app_name}-postgres-group"
  })
}