# Arquitetura do banco de dados

## Escopo

Este repositório entrega a camada de dados gerenciada do GearFlow, sem
integrar, nesta etapa, API, Kubernetes ou Lambda.

## Componentes

| Componente | Responsabilidade |
|---|---|
| Terraform Cloud | Armazenar o state remoto do Terraform. |
| VPC | Isolar a rede do banco. |
| Duas subnets privadas | Permitir que o RDS use mais de uma zona de disponibilidade. |
| Security Group | Bloquear a porta SQL Server enquanto não há consumidores autorizados. |
| Amazon RDS SQL Server | Executar o motor de banco como serviço gerenciado. |
| AWS Secrets Manager | Guardar a credencial mestre e os metadados de conexão. |

## Segurança atual

- O RDS não terá endereço público.
- A porta TCP 1433 não terá regras de entrada por padrão.
- Credenciais não são versionadas no Git.
- O acesso futuro será adicionado somente por CIDR ou Security Group explícito.
- As zonas são variáveis explícitas. Isso evita a permissão
  `ec2:DescribeAvailabilityZones`, bloqueada pelo AWS Academy Lab.

## Contratos futuros

Quando os outros repositórios existirem, eles receberão somente outputs deste
repositório: endpoint, porta, IDs de VPC/Security Group e ARNs dos segredos.
Nenhuma integração é criada automaticamente nesta fase.
