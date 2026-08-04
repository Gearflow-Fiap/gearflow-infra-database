variable "aws_region" {
  description = "Região AWS em que o ambiente será criado."
  type        = string
  default     = "sa-east-1"
}

variable "environment" {
  description = "Nome do ambiente de infraestrutura."
  type        = string
  default     = "homolog"
}

variable "vpc_cidr" {
  description = "Faixa de endereços IPv4 da VPC exclusiva do banco."
  type        = string
  default     = "10.40.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr deve conter uma faixa IPv4 CIDR válida."
  }
}

variable "db_instance_identifier" {
  description = "Identificador único da instância RDS na região AWS."
  type        = string
  default     = "gearflow-sqlserver-homolog"
}

variable "db_master_username" {
  description = "Nome do usuário mestre do SQL Server gerenciado."
  type        = string
  default     = "gearflow_admin"
}

variable "db_instance_class" {
  description = "Classe de capacidade da instância RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "sqlserver_engine_version" {
  description = "Versão específica do SQL Server. Nulo permite que a AWS escolha a versão padrão compatível."
  type        = string
  default     = null
  nullable    = true
}

variable "allocated_storage_gib" {
  description = "Armazenamento inicial da instância RDS, em GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage_gib" {
  description = "Limite de crescimento automático do armazenamento, em GiB."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Habilita alta disponibilidade Multi-AZ para a instância RDS."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Quantidade de dias de retenção dos backups automáticos."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days deve estar entre 1 e 35."
  }
}

variable "deletion_protection" {
  description = "Impede exclusão acidental da instância RDS."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Define se a exclusão da instância dispensa snapshot final."
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "Nome do snapshot final quando skip_final_snapshot for falso."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.skip_final_snapshot || var.final_snapshot_identifier != null
    error_message = "Informe final_snapshot_identifier quando skip_final_snapshot for falso."
  }
}

variable "database_name" {
  description = "Nome do banco lógico que será criado futuramente pelas migrations da aplicação."
  type        = string
  default     = "GearFlowDb"
}

variable "secret_recovery_window_in_days" {
  description = "Período de recuperação do segredo de metadados após sua exclusão."
  type        = number
  default     = 7
}

variable "allowed_cidr_blocks" {
  description = "CIDRs que poderão acessar o SQL Server no futuro. Deve permanecer vazio nesta fase."
  type        = set(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security groups que poderão acessar o SQL Server no futuro. Deve permanecer vazio nesta fase."
  type        = set(string)
  default     = []
}
