# Release v0.2.3 (hotfix)

Hotfix na ordenação da lista de notificações (sininho).

## Fixes
- **Notificações:** ordenação agora prioriza `sent_at` (quando a notificação foi realmente enviada), com fallback para `created_at`, evitando ordem confusa quando existem notificações futuras/agendadas.
