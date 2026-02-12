# Schema do Banco (v0.0.1)

Este documento descreve as tabelas da versao v0.0.1 (beta), incluindo finalidade, atributos e relacionamentos.

## Convencoes gerais
- Todas as tabelas usam `id` como UUID (gerado por `gen_random_uuid()`).
- Quase todas as tabelas sao multi-tenant por `user_id`.
- `created_at` e `updated_at` existem para auditoria basica.
- Statuses sao strings (ex.: `OPEN`, `DONE`, `CONFIRMED`) para manter o MVP flexivel.

## Tabelas

### `users`
Finalidade: armazenar o usuario da aplicacao.

Campos:
- `id`: identificador unico do usuario.
- `email`: email (opcional no MVP).
- `display_name`: nome exibido.
- `password`: hash da senha (nao salvar senha em texto puro).
- `locale`: ex.: `pt-BR`.
- `timezone`: ex.: `America/Sao_Paulo`.
- `created_at` / `updated_at`: timestamps de auditoria.

Relacionamentos:
- 1 usuario -> N flags, subflags, regras, inbox, sugestoes e entidades finais.

### `flags`
Finalidade: contexto principal escolhido pelo usuario (ex.: "Financas", "Saude").

Campos:
- `id`: identificador da flag.
- `user_id`: dono da flag.
- `name`: nome da flag.
- `color`: cor opcional para UI.
- `sort_order`: ordenacao manual na UI.
- `created_at` / `updated_at`.

Relacionamentos:
- `flags.user_id` -> `users.id`.
- 1 flag -> N subflags.
- 1 flag pode ser associada a regras e sugestoes.

### `subflags`
Finalidade: contexto secundario (ex.: "Cartao" dentro de "Financas").

Campos:
- `id`: identificador da subflag.
- `user_id`: dono.
- `flag_id`: flag pai.
- `name`: nome.
- `sort_order`: ordenacao manual.
- `created_at` / `updated_at`.

Relacionamentos:
- `subflags.user_id` -> `users.id`.
- `subflags.flag_id` -> `flags.id`.

### `context_rules`
Finalidade: regra simples "keyword -> contexto" para sugerir flag/subflag.

Campos:
- `id`: identificador da regra.
- `user_id`: dono.
- `keyword`: palavra-chave.
- `flag_id`: flag sugerida.
- `subflag_id`: subflag sugerida (opcional).
- `created_at` / `updated_at`.

Relacionamentos:
- `context_rules.user_id` -> `users.id`.
- `context_rules.flag_id` -> `flags.id`.
- `context_rules.subflag_id` -> `subflags.id` (opcional).

### `inbox_items`
Finalidade: entrada bruta do usuario (texto, depois midia).

Campos:
- `id`: identificador do inbox item.
- `user_id`: dono.
- `source`: origem (ex.: `manual`).
- `raw_text`: texto original.
- `raw_media_url`: url da midia (opcional, pos-MVP).
- `status`: `NEW`, `PROCESSING`, `SUGGESTED`, `NEEDS_REVIEW`, `CONFIRMED`, `DISMISSED`.
- `last_error`: erro do processamento (se houver).
- `created_at` / `updated_at`.

Relacionamentos:
- `inbox_items.user_id` -> `users.id`.
- 1 inbox item -> N sugestoes (versoes).

### `ai_suggestions`
Finalidade: sugestao gerada pela IA para um inbox item.

Campos:
- `id`: identificador da sugestao.
- `user_id`: dono.
- `inbox_item_id`: referencia ao inbox item.
- `type`: `task`, `reminder`, `event`, `shopping`, `note`.
- `title`: titulo sugerido.
- `confidence`: confianca (0..1).
- `flag_id`: contexto sugerido (opcional).
- `subflag_id`: contexto secundario (opcional).
- `needs_review`: true se precisa revisao.
- `payload_json`: JSON especifico do tipo.
- `created_at`.

Relacionamentos:
- `ai_suggestions.user_id` -> `users.id`.
- `ai_suggestions.inbox_item_id` -> `inbox_items.id`.
- `ai_suggestions.flag_id` -> `flags.id` (opcional).
- `ai_suggestions.subflag_id` -> `subflags.id` (opcional).

### `tasks`
Finalidade: tarefa final confirmada pelo usuario.

Campos:
- `id`: identificador da tarefa.
- `user_id`: dono.
- `title`: titulo.
- `description`: descricao (opcional).
- `status`: `OPEN`, `DONE`.
- `due_at`: data limite (opcional).
- `flag_id`: referencia ao contexto principal (opcional).
- `subflag_id`: referencia ao contexto secundario (opcional).
- `source_inbox_item_id`: referencia ao inbox item de origem.
- `created_at` / `updated_at`.

Relacionamentos:
- `tasks.user_id` -> `users.id`.
- `tasks.flag_id` -> `flags.id` (opcional).
- `tasks.subflag_id` -> `subflags.id` (opcional).
- `tasks.source_inbox_item_id` -> `inbox_items.id` (opcional).

### `reminders`
Finalidade: lembretes com data/hora.

Campos:
- `id`: identificador do lembrete.
- `user_id`: dono.
- `title`: titulo.
- `status`: `OPEN`, `DONE`.
- `remind_at`: data/hora do aviso.
- `source_inbox_item_id`: referencia ao inbox item de origem.
- `created_at` / `updated_at`.

Relacionamentos:
- `reminders.user_id` -> `users.id`.
- `reminders.source_inbox_item_id` -> `inbox_items.id` (opcional).

### `events`
Finalidade: eventos de calendario.

Campos:
- `id`: identificador do evento.
- `user_id`: dono.
- `title`: titulo.
- `start_at`: inicio.
- `end_at`: fim.
- `all_day`: evento dia inteiro.
- `location`: local (opcional).
- `source_inbox_item_id`: referencia ao inbox item de origem.
- `created_at` / `updated_at`.

Relacionamentos:
- `events.user_id` -> `users.id`.
- `events.source_inbox_item_id` -> `inbox_items.id` (opcional).

### `shopping_lists`
Finalidade: lista de compras confirmada.

Campos:
- `id`: identificador da lista.
- `user_id`: dono.
- `title`: titulo.
- `status`: `OPEN`, `DONE`/`ARCHIVED` (futuro).
- `source_inbox_item_id`: referencia ao inbox item de origem.
- `created_at` / `updated_at`.

Relacionamentos:
- `shopping_lists.user_id` -> `users.id`.
- `shopping_lists.source_inbox_item_id` -> `inbox_items.id` (opcional).

### `shopping_items`
Finalidade: itens dentro de uma lista de compras.

Campos:
- `id`: identificador do item.
- `user_id`: dono.
- `list_id`: lista pai.
- `title`: nome do item.
- `quantity`: quantidade (texto livre, ex.: "2kg").
- `checked`: marcado como comprado.
- `sort_order`: ordenacao manual.
- `created_at` / `updated_at`.

Relacionamentos:
- `shopping_items.user_id` -> `users.id`.
- `shopping_items.list_id` -> `shopping_lists.id`.

## Indices principais (resumo)
- `users`: `(email) unique`
- `flags`: `(user_id, sort_order)`
- `subflags`: `(user_id, flag_id, sort_order)`
- `context_rules`: `(user_id, keyword)`
- `inbox_items`: `(user_id, status, created_at DESC)`
- `ai_suggestions`: `(inbox_item_id, created_at DESC)`
- `tasks`: `(user_id, status, due_at)`
- `reminders`: `(user_id, status, remind_at)`
- `events`: `(user_id, start_at)`
- `shopping_lists`: `(user_id, status)`
- `shopping_items`: `(list_id, checked, sort_order)`
