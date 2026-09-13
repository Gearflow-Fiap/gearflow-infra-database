output "db_instance_identifier" {
  description = "Identificador da instância RDS SQL Server."
  value       = aws_db_instance.sqlserver.identifier
}

output "db_endpoint" {
  description = "Endpoint privado do SQL Server. Será usado apenas em integrações futuras."
  value       = aws_db_instance.sqlserver.endpoint
  sensitive   = true
}

output "db_port" {
  description = "Porta TCP do SQL Server gerenciado."
  value       = aws_db_instance.sqlserver.port
}

output "database_name" {
  description = "Nome planejado para o banco lógico da aplicação."
  value       = var.database_name
}

output "master_credentials_secret_arn" {
  description = "ARN do segredo AWS gerenciado pelo RDS com a credencial mestre."
  value       = aws_db_instance.sqlserver.master_user_secret[0].secret_arn
  sensitive   = true
}

output "connection_metadata_secret_arn" {
  description = "ARN do segredo com endpoint, porta, banco lógico e referência da credencial mestre."
  value       = aws_secretsmanager_secret.connection_metadata.arn
  sensitive   = true
}

output "database_vpc_id" {
  description = "ID da VPC privada que contém a instância RDS."
  value       = aws_vpc.database.id
}

output "database_security_group_id" {
  description = "ID do security group do banco para autorizações futuras."
  value       = aws_security_group.database.id
}
