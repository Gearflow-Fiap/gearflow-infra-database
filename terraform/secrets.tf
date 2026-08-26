# A senha do usuário mestre é gerada e gerenciada pelo RDS porque
# manage_master_user_password = true está definido em database.tf. Dessa forma,
# a senha não aparece em arquivos Terraform nem é duplicada neste segredo.
#
# Este segredo contém somente os metadados necessários para uma integração
# futura. A aplicação consultará também master_credentials_secret_arn para
# obter a credencial quando essa integração existir.
resource "aws_secretsmanager_secret" "connection_metadata" {
  name                    = "gearflow/database/${var.environment}/connection-metadata"
  description             = "Metadados de conexão do banco gerenciado do GearFlow"
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = {
    Name = "gearflow-database-connection-metadata-${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "connection_metadata" {
  secret_id = aws_secretsmanager_secret.connection_metadata.id

  secret_string = jsonencode({
    database_name                 = var.database_name
    engine                        = "sqlserver"
    host                          = aws_db_instance.sqlserver.address
    port                          = aws_db_instance.sqlserver.port
    master_credentials_secret_arn = aws_db_instance.sqlserver.master_user_secret[0].secret_arn
  })
}
