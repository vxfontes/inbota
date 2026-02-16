# Inbota

<img src="app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" alt="Inbota App Icon" width="180" />

Inbox com IA para transformar entradas brutas em itens organizados de produtividade.

O Inbota recebe texto (e, no roadmap, compartilhamentos e imagens), gera sugestoes com IA e permite revisao antes de confirmar o item final como tarefa, lembrete, evento ou lista de compras.

## Status

Projeto em desenvolvimento (MVP).

Funcional hoje:
- Monorepo com `app` (Flutter), `backend` (Go + Gin), `db` (scripts SQL) e `docs`.
- Autenticacao JWT (`signup`, `login`, `me`).
- CRUD de contextos (`flags` e `subflags`) e regras de contexto por palavra-chave.
- Fluxo de Inbox (`criar`, `reprocessar`, `confirmar`) com sugestao de IA.
- Entidades finais: tarefas, lembretes, eventos e compras.
- Documentacao de API e Swagger.

## Visao do produto

Objetivo do MVP:
- Centralizar tudo que chega para o usuario em um Inbox unico.
- Classificar automaticamente com IA em tipos acionaveis.
- Permitir revisao humana antes de criar a entidade final.
- Organizar por contexto de vida/trabalho via flags e subflags.

## Arquitetura do repositorio

```text
inbota/
├── app/      # App Flutter
├── backend/  # API Go (Gin)
├── db/       # Scripts e versoes de schema
└── docs/     # Guias tecnicos e produto
```

## Stack

- App: Flutter 3.35.x + Dart
- Backend: Go 1.25.x + Gin
- Banco: PostgreSQL 18
- IA: provedor compativel com endpoint de chat completions (ex.: Groq)

## Como rodar local

### 1) Backend

Requisitos:
- Go 1.25+
- Docker (opcional, para banco/API com compose)

Passos:

```bash
cd backend
cp .env.example .env
```

Edite `backend/.env` com os valores minimos:
- `DATABASE_URL`
- `JWT_SECRET`
- `AI_PROVIDER`
- `AI_API_KEY`
- `AI_BASE_URL`
- `AI_MODEL`

Rodar sem Docker:

```bash
cd backend
go run ./cmd/api
```

Rodar com Docker (API + Postgres):

```bash
cd backend
docker compose up --build
```

Endpoints uteis:
- `GET /healthz`
- `GET /readyz`
- `GET /swagger-ui/index.html`

### 2) App Flutter

Requisitos:
- Flutter 3.35.x

Passos:

1. Ajuste a URL da API em `app/lib/shared/services/http/app_service.dart`.
2. Rode:

```bash
cd app
flutter pub get
flutter run
```

## Fluxo principal (MVP)

1. Usuario faz `signup` ou `login`.
2. Cria um item bruto no Inbox (`POST /v1/inbox-items`).
3. Reprocessa com IA quando necessario (`POST /v1/inbox-items/{id}/reprocess`).
4. Revisa e confirma para criar entidade final (`POST /v1/inbox-items/{id}/confirm`).
5. Consulta a entidade nas abas/listas de tarefas, lembretes, eventos ou compras.

## Documentacao

- API detalhada: `docs/api.md`
- Estrutura backend: `docs/backend-go-estrutura.md`
- Schema do banco: `docs/db-schema-v0.0.1.md`

## Roadmap resumido

- Melhorar pipeline automatico de processamento do Inbox.
- Evoluir entrada por compartilhamento e OCR.
- Expandir notificacoes e automacoes por contexto.
- Hardening de observabilidade, testes e UX.
