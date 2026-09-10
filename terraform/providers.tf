# Conexão é declarada por recurso (server { ... }), não aqui — ver app-database.tf.
provider "mssql" {}

provider "aws" {
  # Esta variável será definida em homolog.tfvars quando a conta AWS for usada.
  # Declarar o provider não cria recursos nem tenta se conectar à AWS.
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "GearFlow"
      Repository  = "gearflow-infra-database"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
