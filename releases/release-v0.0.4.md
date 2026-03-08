# Release 0.0.4

Data: 2026-03-08

## Visão Geral
Esta versão é focada em escalabilidade e eficiência técnica, trazendo uma reestruturação profunda na camada de acesso a dados do Inbota. O objetivo principal foi a eliminação de gargalos de performance (como consultas N+1) e a simplificação da lógica de negócio no backend Go, delegando agregações complexas para o PostgreSQL através de Views e Functions otimizadas.

## Fix database
- **Eliminação de N+1 Queries no Inbox:** Refatoração do fluxo de listagem e detalhamento de itens do Inbox. Agora, o item e sua sugestão de IA mais recente são recuperados em um único JOIN via `view_inbox_with_latest_suggestion`, reduzindo drasticamente o tempo de resposta.
- **Agenda Consolidada (5 queries → 1):** O endpoint de agenda foi simplificado de 5 viagens ao banco para apenas uma. A nova `view_agenda_consolidada` centraliza Tarefas, Eventos e Lembretes já com seus respectivos nomes e cores de Flags/Subflags aplicados.
- **Otimização do Resumo de Rotinas:** O cálculo do resumo diário ("Hoje") agora utiliza a `view_routine_daily_status`, que consolida rotinas, conclusões e exceções em uma única consulta, eliminando loops de consulta em Go.
- **Cálculo de Streak Preciso:** Correção e otimização do cálculo de sequências (streaks) de rotinas através da função SQL `fnc_get_routine_streak`, utilizando Window Functions para identificar dias consecutivos reais em vez de apenas contar ocorrências recentes.
- **Validação de Sobreposição (Overlap) em Banco:** A checagem de conflitos de horário entre rotinas foi movida para o banco de dados via `fnc_check_routine_overlap`. Isso evita o download de centenas de registros para processamento em memória, utilizando operadores nativos de interseção de arrays do PostgreSQL.
