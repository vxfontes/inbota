# Inbota Backend (Go + Gin)

API do MVP usando Go e Gin para as rotas.

## Requisitos
- Go 1.25+

## Configuracao
Copie os exemplos de env e preencha as credenciais:
- Arquivo base: `backend/.env.example`
- Variaveis chave:
  - `FIREBASE_PROJECT_ID`
  - `GOOGLE_APPLICATION_CREDENTIALS` (path para o JSON do service account)
  - `FIRESTORE_EMULATOR_HOST` (opcional)

## Rodar local
```bash
cd backend
go run ./cmd/api
```

## Rodar com Docker (API + Postgres)
Dentro de `backend/`:
```bash
docker compose up --build
```

## Endpoints basicos
- `GET /healthz`
- `GET /readyz`

## Observacoes
- O roteamento usa Gin (`github.com/gin-gonic/gin`).
- Em `APP_ENV=prod`, o Gin roda em `ReleaseMode`.
- Se for a primeira vez rodando, pode ser necessario baixar deps: `go mod download`.
