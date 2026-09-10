# ── Login/usuário/banco da aplicação (gearflow_app) ──────────────────────
# Antes, esse passo era manual (sqlcmd direto na instância) e se perdia toda vez
# que o RDS era recriado (ex.: troca de major version do engine muda o endpoint).
# Aqui fica automatizado e sobrevive a recriações da instância.
#
# A senha mestre é gerenciada pelo RDS (manage_master_user_password em database.tf)
# e rotaciona sozinha — por isso é lida do Secrets Manager em vez de fixada aqui.
data "aws_secretsmanager_secret_version" "master" {
  secret_id = aws_db_instance.sqlserver.master_user_secret[0].secret_arn
}

locals {
  master_creds = jsondecode(data.aws_secretsmanager_secret_version.master.secret_string)
}

variable "app_db_password" {
  description = "Senha do login SQL gearflow_app usado pela aplicação (mesmo valor do DB_PASSWORD em gearflow-infra-k8s)."
  type        = string
  sensitive   = true
}

# Nem o aws_db_instance (a engine sqlserver-ex do RDS não aceita "db_name" na
# criação, ao contrário de MySQL/Postgres) nem o provider mssql (só tem
# mssql_login/mssql_user, sem recurso de "database") criam o banco lógico —
# esse é o único passo imperativo aqui. Idempotente via IF DB_ID(...) IS NULL.
resource "null_resource" "app_database" {
  triggers = {
    db_instance_id = aws_db_instance.sqlserver.id
  }

  provisioner "local-exec" {
    environment = {
      SQLCMD_HOST     = aws_db_instance.sqlserver.address
      SQLCMD_PORT     = tostring(aws_db_instance.sqlserver.port)
      SQLCMD_USER     = local.master_creds.username
      SQLCMD_PASSWORD = local.master_creds.password
      DB_NAME         = var.database_name
    }
    command = "sqlcmd -S \"$SQLCMD_HOST,$SQLCMD_PORT\" -U \"$SQLCMD_USER\" -P \"$SQLCMD_PASSWORD\" -C -Q \"IF DB_ID('$DB_NAME') IS NULL CREATE DATABASE [$DB_NAME];\""
  }
}

resource "mssql_login" "app" {
  server {
    host = aws_db_instance.sqlserver.address
    port = aws_db_instance.sqlserver.port
    login {
      username = local.master_creds.username
      password = local.master_creds.password
    }
  }

  login_name = "gearflow_app"
  password   = var.app_db_password
}

resource "mssql_user" "app" {
  server {
    host = aws_db_instance.sqlserver.address
    port = aws_db_instance.sqlserver.port
    login {
      username = local.master_creds.username
      password = local.master_creds.password
    }
  }

  database   = var.database_name
  username   = "gearflow_app"
  login_name = mssql_login.app.login_name
  roles      = ["db_owner"]

  depends_on = [null_resource.app_database]
}
