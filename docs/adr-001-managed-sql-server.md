# ADR 001 - Manter SQL Server em serviço gerenciado

**Status:** Aceito

## Contexto

Na Fase 2, o GearFlow executa SQL Server em um container Kubernetes local. A
Fase 3 exige um banco de dados gerenciado em nuvem.

## Decisão

Substituir o container SQL Server local por Amazon RDS for SQL Server, mantendo
o motor SQL Server e o banco lógico planejado `GearFlowDb`.

## Consequências

- O repositório deixa de gerenciar Deployment, PVC e Service Kubernetes do banco.
- Backups, patches e infraestrutura do host passam a ser responsabilidade da AWS.
- A aplicação futura usará endpoint privado e segredos, em vez de
  `sqlserver-service` dentro do Kubernetes.
- O `GearFlowDb` será criado pelas migrations quando a aplicação for integrada.
