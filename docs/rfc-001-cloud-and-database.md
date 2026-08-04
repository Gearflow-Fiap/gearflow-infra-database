# RFC 001 - AWS e SQL Server gerenciado

## Contexto

O GearFlow atual usa SQL Server e Entity Framework Core. A Fase 3 exige banco
gerenciado, Terraform, segurança e CI/CD, mas não exige troca de banco.

## Decisão proposta

Usar AWS como nuvem e Amazon RDS for SQL Server Express como banco gerenciado
inicial de homologação.

## Motivos

- Mantém compatibilidade com o código e migrations existentes do GearFlow.
- Evita migrar dados, sintaxe SQL e provider do Entity Framework nesta fase.
- RDS transfere para a AWS a operação de host, armazenamento, backups e patches.
- A escolha é compatível com a futura Lambda e com infraestrutura Kubernetes.

## Consequências

- O RDS possui custos e deve ser acompanhado pelo orçamento do AWS Academy.
- A instância SQL Server não cria automaticamente o banco lógico `GearFlowDb`.
- Algumas permissões administrativas do SQL Server são limitadas em RDS.
