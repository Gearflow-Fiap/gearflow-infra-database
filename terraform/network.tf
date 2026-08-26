# VPC do banco agora tem IGW para permitir acesso público ao RDS (ambiente de lab)
resource "aws_vpc" "database" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "gearflow-database-${var.environment}"
  }
}

resource "aws_internet_gateway" "database" {
  vpc_id = aws_vpc.database.id

  tags = {
    Name = "gearflow-database-${var.environment}"
  }
}

resource "aws_subnet" "database_private" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.database.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "gearflow-database-${var.environment}-public-${count.index + 1}"
    Tier = "database"
  }
}

resource "aws_route_table" "database_private" {
  vpc_id = aws_vpc.database.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.database.id
  }

  tags = {
    Name = "gearflow-database-${var.environment}-public"
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
