resource "aws_security_group" "database" {
  name = "gearflow-database-${var.environment}"
  # A API EC2 aceita apenas caracteres ASCII neste campo.
  description = "Firewall for GearFlow SQL Server RDS"
  vpc_id      = aws_vpc.database.id

  tags = {
    Name = "gearflow-database-${var.environment}"
  }
}

# Nenhuma regra de entrada é criada com os valores padrão vazios. As regras
# abaixo só serão materializadas quando a integração futura informar um CIDR
# ou security group explicitamente autorizado.
resource "aws_vpc_security_group_ingress_rule" "sqlserver_cidr" {
  for_each = var.allowed_cidr_blocks

  security_group_id = aws_security_group.database.id
  cidr_ipv4         = each.value
  from_port         = 1433
  to_port           = 1433
  ip_protocol       = "tcp"
  description       = "Acesso SQL Server autorizado futuramente"
}

resource "aws_vpc_security_group_ingress_rule" "sqlserver_security_group" {
  for_each = var.allowed_security_group_ids

  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = each.value
  from_port                    = 1433
  to_port                      = 1433
  ip_protocol                  = "tcp"
  description                  = "Acesso SQL Server autorizado futuramente"
}

resource "aws_vpc_security_group_ingress_rule" "sqlserver_database_provisioner" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.database_provisioner.id
  from_port                    = 1433
  to_port                      = 1433
  ip_protocol                  = "tcp"
  description                  = "Private GitHub Actions database runner"
}
