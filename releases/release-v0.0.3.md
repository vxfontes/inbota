# Release 0.0.3

Data: 2026-03-08

## Visão Geral
A versão 0.0.3 marca uma mudança significativa na arquitetura de produtividade do Inbota com a introdução do **Cronograma (Routines)**. Esta feature substitui a antiga aba de Lembretes, consolidando atividades recorrentes em um fluxo de rotina inteligente, enquanto a Home absorve a gestão de itens pontuais.

## Features
- **Módulo de Cronograma (Routines) com IA:** Substituição da aba de Lembretes por um sistema de rotinas recorrentes (semanal, quinzenal, etc.) com detecção inteligente via IA, nova visão semanal, gestão de streaks e integração de tarefas/lembretes pontuais na Home.
  - **Substituição da Navegação:** A aba "Lembretes" foi descontinuada para dar lugar ao **Cronograma**, uma visão semanal focada em hábitos e atividades recorrentes.
  - **Tipos de Recorrência:** Suporte completo para rotinas semanais, quinzenais (biweekly), tri-semanais e mensais baseadas em dias da semana (ex: "toda 1ª segunda do mês").
  - **Gestão de Estados:** Implementação de `routine_completions` para rastrear o cumprimento das tarefas e `routine_exceptions` para permitir "pular" ou reagendar ocorrências específicas.
  - **Visualização por Período:** Organização automática da agenda em blocos de "Manhã", "Tarde" e "Noite".