# Release 0.1.0

Data: 2026-03-10

## Visão Geral
Esta versão foca na consistência temporal e precisão dos dados, especialmente no que diz respeito ao cálculo de rotinas e status diários. Foram implementadas travas de fuso horário (Timezone) diretamente no banco de dados para garantir que, independentemente da configuração da sessão ou servidor, os dados de rotinas e agendas reflitam o horário local do Brasil (America/Sao_Paulo) de forma determinística.

## Fixes
- **Forçamento de Timezone (America/Sao_Paulo):** Configuração global em nível de banco de dados para garantir que todas as sessões do PostgreSQL operem no fuso horário de Brasília.
- **Ajuste de Versão de Banco:** Migração da estrutura de banco para a versão `0.1.0`, consolidando os ajustes de esquema.
- **Centralização do Status Diário:** Refatoração da lógica de consulta de status de rotinas para a função SQL.
