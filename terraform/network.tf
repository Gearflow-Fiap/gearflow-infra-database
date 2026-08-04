# Esta VPC é privada e exclusiva do banco nesta primeira etapa. Ela não cria
# Internet Gateway nem NAT Gateway, portanto não expõe o banco à internet.
resource "aws_vpc" "database" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "gearflow-database-${var.environment}"
  }
}

resource "aws_subnet" "database_private" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.database.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "gearflow-database-${var.environment}-private-${count.index + 1}"
    Tier = "database"
  }
}

# A tabela de rotas não possui rota para a internet. Ela existe para tornar a
# topologia explícita e permitir sua evolução futura sem alterar as subnets.
resource "aws_route_table" "database_private" {
  vpc_id = aws_vpc.database.id

  tags = {
    Name = "gearflow-database-${var.environment}-private"
  }
}

resource "aws_route_table_association" "database_private" {
  count = length(aws_subnet.database_private)

  subnet_id      = aws_subnet.database_private[count.index].id
  route_table_id = aws_route_table.database_private.id
}

resource "aws_db_subnet_group" "database" {
  name       = "gearflow-database-${var.environment}"
  subnet_ids = aws_subnet.database_private[*].id

  tags = {
    Name = "gearflow-database-${var.environment}"
  }
}
