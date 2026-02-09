# Inbota Backend (Go + Gin)

API do MVP usando Go e Gin para as rotas.

## Requisitos
- Go 1.25+

## Configuracao
Copie os exemplos de env e preencha as credenciais:
- Arquivo base: `backend/.env.example`
- Variaveis chave:
  - `DATABASE_URL`
  - `JWT_SECRET`

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

## Hot reload (Docker)
Com o `docker compose up`, a API usa `air` e recarrega ao salvar arquivos Go.

## Endpoints basicos
- `GET /healthz`
- `GET /readyz`
- `GET /swagger-ui/index.html`

## Swagger (gerar docs)
```bash
cd backend
swag init -g cmd/api/main.go -o ./docs
```

## Observacoes
- O roteamento usa Gin (`github.com/gin-gonic/gin`).
- Em `APP_ENV=prod`, o Gin roda em `ReleaseMode`.
- Se for a primeira vez rodando, pode ser necessario baixar deps: `go mod download`.
