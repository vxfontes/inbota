# API Inbota (MVP)

Guia detalhado da API HTTP do Inbota. Este documento complementa o Swagger.

**Base URL**
- Local: `http://localhost:8080`

**Auth**
- Header obrigatorio nas rotas protegidas: `Authorization: Bearer <token>`
- Para ambiente MVP com JWT local:
  - `POST /v1/auth/signup`
  - `POST /v1/auth/login`
- `GET /v1/me` retorna o perfil do usuario do token.

**Request Id**
- Header de resposta: `X-Request-Id` (configuravel)
- Envie o header em chamadas para rastrear requisições.

**Erros**
- Formato:
```json
{"error":"codigo","requestId":"<id>"}
```
- Codigos comuns:
  - `missing_required_fields`
  - `invalid_status`
  - `invalid_source`
  - `invalid_type`
  - `invalid_payload`
  - `invalid_time_range`
  - `invalid_cursor`
  - `not_found`
  - `dependency_missing`
  - `invalid_auth_header`
  - `invalid_token`
  - `unauthorized`
  - `internal_error`

**Paginacao**
- Query params: `limit`, `cursor`
- Response: `nextCursor`

**Observacao sobre cores**
- `flag.color` vem do proprio flag.
- `subflag.color` usa a cor do flag pai (subflag nao tem cor propria no schema).

## Modelos (JSON)

**FlagObject**
```json
{"id":"uuid","name":"string","color":"#AABBCC"}
```

**SubflagObject**
```json
{"id":"uuid","name":"string","color":"#AABBCC"}
```

**InboxItemObject**
```json
{
  "id":"uuid",
  "source":"manual|share|ocr",
  "rawText":"string",
  "rawMediaUrl":"string|null",
  "status":"NEW|PROCESSING|SUGGESTED|NEEDS_REVIEW|CONFIRMED|DISMISSED",
  "lastError":"string|null",
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

**AiSuggestionResponse**
```json
{
  "id":"uuid",
  "type":"task|reminder|event|shopping|note",
  "title":"string",
  "confidence":0.0,
  "flag":{"id":"uuid","name":"string","color":"#AABBCC"},
  "subflag":{"id":"uuid","name":"string","color":"#AABBCC"},
  "needsReview":true,
  "payload":{},
  "createdAt":"RFC3339"
}
```

**InboxItemResponse**
```json
{
  "id":"uuid",
  "source":"manual|share|ocr",
  "rawText":"string",
  "rawMediaUrl":"string|null",
  "status":"NEW|PROCESSING|SUGGESTED|NEEDS_REVIEW|CONFIRMED|DISMISSED",
  "lastError":"string|null",
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339",
  "suggestion": { ...AiSuggestionResponse }
}
```

**TaskResponse**
```json
{
  "id":"uuid",
  "title":"string",
  "description":"string|null",
  "status":"OPEN|DONE",
  "dueAt":"RFC3339|null",
  "sourceInboxItem": { ...InboxItemObject },
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

**ReminderResponse**
```json
{
  "id":"uuid",
  "title":"string",
  "status":"OPEN|DONE",
  "remindAt":"RFC3339|null",
  "sourceInboxItem": { ...InboxItemObject },
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

**EventResponse**
```json
{
  "id":"uuid",
  "title":"string",
  "startAt":"RFC3339|null",
  "endAt":"RFC3339|null",
  "allDay":false,
  "location":"string|null",
  "sourceInboxItem": { ...InboxItemObject },
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

**ShoppingListObject**
```json
{"id":"uuid","title":"string","status":"OPEN|DONE|ARCHIVED"}
```

**ShoppingListResponse**
```json
{
  "id":"uuid",
  "title":"string",
  "status":"OPEN|DONE|ARCHIVED",
  "sourceInboxItem": { ...InboxItemObject },
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

**ShoppingItemResponse**
```json
{
  "id":"uuid",
  "list": { ...ShoppingListObject },
  "title":"string",
  "quantity":"string|null",
  "checked":false,
  "sortOrder":0,
  "createdAt":"RFC3339",
  "updatedAt":"RFC3339"
}
```

## Endpoints

**Health**
- `GET /healthz`
- `GET /readyz`

**Auth (JWT local)**
- `POST /v1/auth/signup`
  - Body: `email`, `password`, `displayName`, `locale`, `timezone`
  - Response: `AuthResponse` (token + user)
- `POST /v1/auth/login`
  - Body: `email`, `password`
  - Response: `AuthResponse`

**Me**
- `GET /v1/me`
  - Header: `Authorization: Bearer <token>`
  - Response: `AuthResponse` (sem token)

**Flags**
- `GET /v1/flags`
- `POST /v1/flags` (name required, color optional, sortOrder optional)
- `PATCH /v1/flags/{id}` (name/color/sortOrder)
- `DELETE /v1/flags/{id}`

**Subflags**
- `GET /v1/flags/{id}/subflags`
- `POST /v1/flags/{id}/subflags` (name required, sortOrder optional)
- `PATCH /v1/subflags/{id}` (name/sortOrder)
- `DELETE /v1/subflags/{id}`

**Context Rules**
- `GET /v1/context-rules`
- `POST /v1/context-rules` (keyword, flagId required, subflagId optional)
- `PATCH /v1/context-rules/{id}` (keyword/flagId/subflagId)
- `DELETE /v1/context-rules/{id}`

**Inbox**
- `GET /v1/inbox-items` (filters: `status`, `source`)
- `POST /v1/inbox-items` (rawText required, source optional)
- `GET /v1/inbox-items/{id}`
- `POST /v1/inbox-items/{id}/reprocess`
- `POST /v1/inbox-items/{id}/confirm`
- `POST /v1/inbox-items/{id}/dismiss`

**Entidades finais**
- `GET/POST/PATCH /v1/tasks`
- `GET/POST/PATCH /v1/reminders`
- `GET/POST/PATCH /v1/events`
- `GET/POST/PATCH /v1/shopping-lists`
- `GET/POST /v1/shopping-lists/{id}/items`
- `PATCH /v1/shopping-items/{id}`

## Confirm Inbox Payload (AI)

O endpoint `POST /v1/inbox-items/{id}/confirm` exige:
```json
{
  "type":"task|reminder|event|shopping",
  "title":"string",
  "flagId":"uuid|null",
  "subflagId":"uuid|null",
  "payload": { ... }
}
```

Payload por tipo:
- `task`: `{"dueAt":"RFC3339|null"}`
- `reminder`: `{"at":"RFC3339"}`
- `event`: `{"start":"RFC3339","end":"RFC3339|null","allDay":true}`
- `shopping`: `{"items":[{"title":"string","quantity":"string|null"}]}`

Validacoes:
- `reminder.at` obrigatorio.
- `event.end` nao pode ser menor que `event.start`.
- `shopping.items` nao pode ser vazio.

## Swagger

Gerar a doc:
```bash
cd backend
swag init -g cmd/api/main.go --parseInternal -o ./docs
```

Rodando via Docker, reinicie a API:
```bash
docker compose restart api
```

No Swagger UI use:
- `Authorize` -> `Bearer <token>`
