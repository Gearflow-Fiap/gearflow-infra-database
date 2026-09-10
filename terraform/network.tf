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

# Subnets privadas: hospedam o RDS. Sem IP público e sem rota direta ao IGW —
# a única saída é via NAT Gateway (necessária para a Lambda check-client, que
# roda nessas mesmas subnets e precisa alcançar outros serviços AWS, ex. CloudWatch Logs).
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

# Subnet pública: existe só para hospedar o NAT Gateway que dá saída à internet
# para as subnets privadas (RDS + Lambda check-client via vpc_config).
resource "aws_subnet" "database_public" {
  vpc_id                  = aws_vpc.database.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, length(var.availability_zones))
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "gearflow-database-${var.environment}-public"
    Tier = "nat"
  }
}

resource "aws_route_table" "database_public" {
  vpc_id = aws_vpc.database.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.database.id
  }

  tags = {
    Name = "gearflow-database-${var.environment}-public"
  }
}

resource "aws_route_table_association" "database_public" {
  subnet_id      = aws_subnet.database_public.id
  route_table_id = aws_route_table.database_public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "gearflow-database-${var.environment}-nat"
  }
}

resource "aws_nat_gateway" "database" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.database_public.id

  tags = {
    Name = "gearflow-database-${var.environment}"
  }

  depends_on = [aws_internet_gateway.database]
}

resource "aws_route_table" "database_private" {
  vpc_id = aws_vpc.database.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.database.id
  }

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
