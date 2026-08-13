# Organiq — Instructions for Claude

Inbox com IA que transforma entradas brutas em tarefas, lembretes, eventos e listas de compras.

## Stack

- **App**: Flutter 3.35.x + Dart (`app/`)
- **Backend**: Go 1.25.x + Gin (`backend/`)
- **DB**: PostgreSQL via Supabase (`db/`)
- **MCP**: Node 18+ / TypeScript (`mcp/`)
- **IA**: Groq (OpenAI-compatible)
- **Deploy API**: Render
- **Auth**: JWT

## Monorepo

```
organiq/
├── app/       # Flutter — Clean Arch (modules/presentation/shared)
├── backend/   # Go + Gin — cmd/{api,seed,backfill_notifications}, internal/{app,config,http,infra,observability,scheduler}
├── db/        # SQL migrations/schema
├── mcp/       # MCP server expondo API Organiq como tools (stdio)
└── docs/      # api.md, db-schema-v0.0.1.md, backend-go-estrutura.md, app-estrutura.md, superpowers/
```

## Domínio

Fluxo core: `signup/login` → cria item bruto no Inbox → IA sugere classificação → usuário confirma → vira entidade final (`task`, `reminder`, `event`, `shopping`). Organização via `flags` + `subflags` e regras por palavra-chave.

## Comandos

### Backend
```bash
cd backend
cp .env.example .env            # setar DATABASE_URL, JWT_SECRET, AI_*
go run ./cmd/api                # API local
go run ./cmd/seed               # seed dados
go run ./cmd/backfill_notifications
docker compose up --build       # API + Postgres com hot reload (air)
swag init -g cmd/api/main.go --parseInternal -o ./docs   # regen Swagger
```

Endpoints: `GET /healthz`, `GET /readyz`, `GET /swagger-ui/index.html`, `GET /v1/agenda`.

### App
```bash
cd app
flutter pub get
flutter run
```

Firebase: `app/android/app/google-services.json`, `app/ios/Runner/GoogleService-Info.plist`, `app/lib/firebase_options.dart` (todos gitignored).
API URL: `app/lib/shared/services/http/app_service.dart`.

### MCP
```bash
cd mcp
npm install && npm run build
npm run dev                     # sem build (tsx)
```

27 tools: auth, inbox, tasks, reminders, events, shopping, agenda. Env: `ORGANIQ_BASE_URL` + (`ORGANIQ_TOKEN` | `ORGANIQ_EMAIL`+`ORGANIQ_PASSWORD`).

## Convenções

- Commit msgs seguem padrão `[branch] - descrição` ou `feat(scope):`/`fix(scope):`/`docs(scope):`.
- Backend: Gin em `ReleaseMode` quando `APP_ENV=prod`.
- App: estrutura modular (`modules/`, `presentation/`, `shared/`).
- DB schema versionado em `db/`.
- Nada de secrets commitados — usar `.env` e arquivos gitignored.

## Assigned Role — Luka (Orchestrator)

Este projeto tem role Maestri em `.maestri/roles/28355d74-8ece-4827-a283-8564ab89a0a6/` atribuindo o agente **luka** como orquestrador responsável por planejamento e execução.

### Routing do Time (usar proativamente)

| Situação | Agente |
|----------|--------|
| Task complexa multi-especialidade | **time:luka** |
| PRD / MVP / scope / backlog | **time:ally** |
| Ideação aberta, divergir antes de decidir | **time:storm** |
| Decisão arquitetural / contratos de serviço | **time:dinah** |
| Backend Go/Gin, APIs, auth, workers | **time:marcus** |
| Mobile Flutter (`app/`) | **time:dylan** |
| DB Postgres/Supabase, schema, queries, migrations | **time:brad** |
| Infra, Docker, Render, CI/CD, deploy | **time:rafael** |
| IA / LLM / Groq / pipeline Inbox | **time:normani** |
| Pesquisa técnica / comparar libs | **time:tyler** |
| Bug / regressão / comportamento inesperado | **time:lauren** |
| Code review após mudanças | **time:ludmilla** |
| Full-stack end-to-end (app + backend + db) | **time:sofia** |

Regras:
1. Feature complexa → **luka** orquestra.
2. 2+ subtasks independentes → **luka** dispara sub-agents em paralelo.
3. Código modificado na sessão → **ludmilla** no fim.
4. Bug reportado → **lauren** antes de tentar fix.
5. Requisito ambíguo → **ally** antes de implementar.
6. Decisão de stack/arquitetura → **dinah** (+ **tyler** se benchmark).

## Coding Rules

1. Descrever approach antes de escrever código. Esperar aprovação.
2. Requisito ambíguo → perguntar antes de codar.
3. Após código pronto → listar edge cases + sugerir testes.
4. Task que altera >3 arquivos → parar e quebrar antes.
5. Ao ser corrigido → refletir + planejar para não repetir.

## Infra de produção

- **Groq** — classificação do Inbox (`AI_*` env vars).
- **Supabase** — Postgres gerenciado.
- **Render** — host da API Go.
- **cron-job.org** — keep-alive pingando `/healthz` a cada 15min.

## Docs principais

- `docs/api.md` — contrato REST
- `docs/backend-go-estrutura.md` — layout Go
- `docs/app-estrutura.md` — layout Flutter
- `docs/db-schema-v0.0.1.md` — schema atual
- `docs/oq_components.md` — componentes UI
- `docs/todo-features.md` — roadmap
- `docs/superpowers/` — planos e specs
