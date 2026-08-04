terraform {
  required_version = "1.15.8"

  # State remoto do ambiente de homologação. A autenticação com o Terraform
  # Cloud será feita somente no primeiro `terraform init` com backend ativo.
  cloud {
    organization = "gearflowfiapmurilo"

    workspaces {
      name = "gearflow-infra-database"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
