resource "aws_db_instance" "sqlserver" {
  identifier = var.db_instance_identifier

  engine         = "sqlserver-ex"
  engine_version = var.sqlserver_engine_version
  license_model  = "license-included"
  instance_class = var.db_instance_class

  username                    = var.db_master_username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  allocated_storage     = var.allocated_storage_gib
  max_allocated_storage = var.max_allocated_storage_gib
  storage_type          = "gp3"
  storage_encrypted     = true

  backup_retention_period    = var.backup_retention_days
  copy_tags_to_snapshot      = true
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : var.final_snapshot_identifier
  deletion_protection        = var.deletion_protection
  auto_minor_version_upgrade = true
  apply_immediately          = false

  enabled_cloudwatch_logs_exports = ["agent", "error"]

  tags = {
    Name = "gearflow-sqlserver-${var.environment}"
  }
}
