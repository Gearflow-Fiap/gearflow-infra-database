data "aws_ami" "database_runner" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Alterar esta revisao recria o runner uma unica vez, permitindo aplicar
# correcoes no bootstrap sem recriar a EC2 em todos os deploys.
resource "terraform_data" "database_provisioner_bootstrap" {
  input = var.runner_bootstrap_revision
}

resource "aws_security_group" "database_provisioner" {
  name        = "gearflow-database-provisioner-${var.environment}"
  description = "Outbound access for the private GitHub Actions database runner"
  vpc_id      = aws_vpc.database.id
  egress      = []

  tags = {
    Name = "gearflow-database-provisioner-${var.environment}"
  }
}

resource "aws_vpc_security_group_egress_rule" "database_provisioner_https" {
  security_group_id = aws_security_group.database_provisioner.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "GitHub, package repositories, and AWS APIs via NAT"
}

resource "aws_vpc_security_group_egress_rule" "database_provisioner_sqlserver" {
  security_group_id            = aws_security_group.database_provisioner.id
  referenced_security_group_id = aws_security_group.database.id
  from_port                    = 1433
  to_port                      = 1433
  ip_protocol                  = "tcp"
  description                  = "Private RDS SQL Server"
}

resource "aws_instance" "database_provisioner" {
  ami                         = data.aws_ami.database_runner.id
  instance_type               = var.runner_instance_type
  subnet_id                   = aws_subnet.database_private[0].id
  vpc_security_group_ids      = [aws_security_group.database_provisioner.id]
  associate_public_ip_address = false
  user_data_replace_on_change = false

  user_data = <<-USERDATA
    #!/usr/bin/env bash
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive
    exec > >(tee /var/log/gearflow-runner-bootstrap.log /dev/console) 2>&1

    apt-get update
    apt-get install -y ca-certificates curl gnupg jq unzip git awscli

    useradd --create-home --shell /bin/bash actions
    install -d --owner actions --group actions /opt/actions-runner
    RUNNER_VERSION=$$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/^v//')
    curl -fsSL -o /tmp/actions-runner.tar.gz "https://github.com/actions/runner/releases/download/v$${RUNNER_VERSION}/actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz"
    tar xzf /tmp/actions-runner.tar.gz -C /opt/actions-runner
    /opt/actions-runner/bin/installdependencies.sh
    chown -R actions:actions /opt/actions-runner

    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o /usr/share/keyrings/microsoft-prod.gpg
    curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/prod.list | \
      sed 's#^deb #deb [signed-by=/usr/share/keyrings/microsoft-prod.gpg] #' > /etc/apt/sources.list.d/mssql-release.list
    apt-get update
    ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev

    su - actions -c '/opt/actions-runner/config.sh --unattended --replace --url "${var.runner_repository_url}" --token "${var.runner_registration_token}" --labels database-vpc'
    /opt/actions-runner/svc.sh install actions
    /opt/actions-runner/svc.sh start
  USERDATA

  metadata_options {
    http_tokens = "required"
  }

  lifecycle {
    ignore_changes = [user_data]
    replace_triggered_by = [
      terraform_data.database_provisioner_bootstrap,
    ]
  }

  depends_on = [aws_route_table_association.database_private]

  tags = {
    Name = "gearflow-database-provisioner-${var.environment}"
  }
}
