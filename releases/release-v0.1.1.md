# Release v0.1.1

Hotfix focado em inconsistências de horário/ordenação que impactavam a Home, notificações e interpretações de datas pela IA.

## Fixes

### Home / Rotinas
- Corrige bug onde rotina com horário correto (ex.: 09:30–10:10) aparecia como 06:30–07:10 na Home ("A seguir").
  - Causa: fallback de timezone (UTC) quando `user.timezone` estava vazio/inválido.
  - Solução: fallback padrão para `America/Sao_Paulo`.

### Notificações
- Ordenação agora é por mais recentes primeiro.
  - Backend: `ORDER BY created_at DESC, id DESC`.

### Inbox / IA
- Corrige interpretação de datas relativas por weekday (ex.: "sexta 17h") quando `user.timezone` não estava definido.
  - Agora o backend envia `Now` para a IA com fallback em `America/Sao_Paulo`.

## Commits
- 82daefb fix(home): default routine times to Brazil timezone when user tz missing
- b7797b9 fix: notifications ordering + AI weekday timezone fallback
