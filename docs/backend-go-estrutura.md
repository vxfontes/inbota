# Estrutura do Backend (Guia detalhado)

Este guia explica o que existe no backend e por que existe. A ideia e facilitar a navegacao do codigo para quem nao conhece Go.

## Mapa rapido do repositorio
- `cmd/`: pontos de entrada (executaveis). Cada subpasta vira um binario separado.
- `internal/`: codigo interno do produto. O Go bloqueia importacao de `internal/` por modulos externos.
- `Dockerfile`: imagem da API para rodar em container.
- `docker-compose.yml`: sobe API e Postgres localmente.
- `go.mod` / `go.sum`: dependencias e versoes do modulo Go.
- `.env.example`: modelo de variaveis de ambiente.
- `docs/api.md`: contrato detalhado da API.

## Como o codigo se organiza (camadas)
- `handler` (HTTP): recebe request, valida input e retorna resposta.
- `usecase`: orquestra regra de negocio e fluxo entre servicos/repos.
- `service`: integracoes e logica que nao e persistencia.
- `repository`: interfaces de persistencia.
- `infra`: implementacoes concretas (ex.: Postgres, Groq).

## Arquivos e pastas principais (com finalidade)

### `cmd/api/main.go`
Responsabilidade: inicializar o servidor HTTP.
O que acontece aqui:
- Carrega configuracao via env (`config.Load()`).
- Cria o logger principal.
- Configura o Gin e seus middlewares.
- Sobe o servidor HTTP e trata shutdown gracioso.
Quando mexer aqui:
- Para alterar porta, timeouts ou modo de execucao.
- Para adicionar mais servidores (ex.: worker separado).

### `internal/config/config.go`
Responsabilidade: centralizar configuracao.
O que faz:
- Le variaveis de ambiente.
- Aplica valores padrao.
- Converte tipos (int, duration).
Quando mexer aqui:
- Para adicionar nova variavel de ambiente.
- Para alterar defaults.

### `internal/observability/logger.go`
Responsabilidade: criar logger estruturado.
O que faz:
- Configura `slog` para registrar logs em JSON.
- Define nivel (`debug`, `info`, `warn`, `error`).
Quando mexer aqui:
- Para mudar formato de logs.
- Para adicionar campos padrao em todo log.

### `internal/http/router.go`
Responsabilidade: definir rotas e middleware.
O que faz:
- Registra middlewares (request id, logging).
- Registra endpoints basicos (`/healthz`, `/readyz`).
 - Registra as rotas protegidas de API (`/v1/*`) com auth JWT.
Quando mexer aqui:
- Sempre que adicionar novas rotas.
- Para ligar/desligar middlewares globais.

### `internal/http/handler/health.go`
Responsabilidade: responder healthchecks.
O que faz:
- Retorna JSON com `status` e `time`.
Quando mexer aqui:
- Se quiser incluir checks reais (ex.: ping no banco).

### `internal/http/handler/*`
Responsabilidade: endpoints da API.
O que existe hoje:
- `auth.go`: signup/login (JWT local).
- `me.go`: retorna perfil do usuario logado.
- `flags.go` / `subflags.go`: CRUD de contextos.
- `context_rules.go`: CRUD de regras keyword -> contexto.
- `inbox.go`: CRUD do inbox e acoes (reprocess/confirm/dismiss).
- `tasks.go`, `reminders.go`, `events.go`: CRUD basico das entidades finais.
- `shopping.go`: CRUD de listas e itens de compras.
Nota:
- Handlers de listagem fazem fetch em lote para evitar N+1 (ex.: inbox/tasks/reminders/events/shopping lists).

### `internal/http/dto/dto.go`
Responsabilidade: contratos HTTP (request/response).
O que faz:
- Define o shape dos objetos que a API retorna.
- Padroniza os tipos usados no Swagger.

### `internal/http/middleware/request_id.go`
Responsabilidade: rastreabilidade de requests.
O que faz:
- Garante um `requestId` em cada request.
- Escreve o mesmo ID na resposta.
Quando mexer aqui:
- Se mudar o nome do header.
- Se quiser integrar com um trace id externo.

### `internal/http/middleware/logging.go`
Responsabilidade: log por request.
O que faz:
- Loga metodo, path, status, bytes e duracao.
Quando mexer aqui:
- Para adicionar campos (ex.: userId).
- Para filtrar caminhos ruidosos.

### `internal/app/usecase/`
Responsabilidade: casos de uso da aplicacao.
O que vai morar aqui:
- `CreateInboxItem`, `ConfirmInboxItem`, etc.
Quando mexer aqui:
- Sempre que uma regra de negocio nova surgir.

O que existe hoje:
- `inbox.go`: fluxo do inbox (create/list/get/reprocess/confirm/dismiss).
- `context.go`: flags, subflags e context rules.
- `tasks.go`, `reminders.go`, `events.go`, `shopping.go`: CRUD minimo.
- `errors.go` e `validation.go`: erros e parse de status/tipos.
 - `TxRunner` e `TxRepositories` (em `internal/app/repository/tx.go`) para operacoes atomicas.

### `internal/app/service/`
Responsabilidade: logica que nao e banco.
O que vai morar aqui:
- `PromptBuilder`, `AiClient`, validadores.
Quando mexer aqui:
- Ao integrar a Groq ou criar regras de IA.

### `internal/app/repository/`
Responsabilidade: contratos de persistencia.
O que vai morar aqui:
- Interfaces como `InboxRepository`, `UserRepository`.
Quando mexer aqui:
- Quando um usecase precisa salvar/buscar algo novo.
Observacoes recentes:
- Alguns repositorios expõem `GetByIDs` para fetch em lote.
- `TxRunner` agrupa repos por transacao:
  - Interface definida em `internal/app/repository/tx.go`.
  - Expondo `WithTx(ctx, fn)` para executar um bloco dentro de `BEGIN/COMMIT`.
  - Se `fn` retorna erro, faz `ROLLBACK`.
  - `TxRepositories` e um bundle com repositorios ja ligados a `*sql.Tx`.

### `internal/infra/postgres/`
Responsabilidade: implementacao concreta dos repositorios.
O que vai morar aqui:
- Queries SQL.
- Mapeamento entre structs e tabelas.
- `tx.go`: runner de transacoes e factories `New*RepositoryTx`.
Quando mexer aqui:
- Ao criar novas tabelas.
- Ao otimizar queries.
Detalhe do `tx.go`:
- Cria uma transacao com `BeginTx`.
- Monta repositorios “Tx” (ex.: `NewInboxRepositoryTx`, `NewTaskRepositoryTx`).
- Executa a funcao callback e decide entre `Commit` ou `Rollback`.
Onde e usado hoje:
- `InboxUsecase.ReprocessInboxItem` (cria sugestao + atualiza inbox).
- `InboxUsecase.ConfirmInboxItem` (cria entidade final + confirma inbox).

### `internal/infra/ai/`
Responsabilidade: integracao com IA.
O que vai morar aqui:
- Cliente Groq.
- Config de timeouts e retries.
Quando mexer aqui:
- Se trocar de provider ou ajustar o prompt.

## Conceitos de Go que aparecem aqui
- `package`: agrupamento de arquivos Go. Tudo dentro do pacote compartilha tipos e funcoes.
- `func`: funcao. `main` e o ponto de entrada do executavel.
- `struct`: tipo composto (parecido com classes, mas sem heranca).
- `interface`: contrato de metodos (muito usado para repositorios).
- `go.mod`: define o modulo e dependencias.
- `internal/`: pasta especial que protege o codigo de imports externos.

## Fluxo basico ao rodar a API
1. `main.go` carrega a configuracao e cria o logger.
2. `router.go` cria o Gin com middlewares e rotas.
3. O servidor HTTP sobe e atende requests.

## Onde colocar coisas novas (regra rapida)
- Nova rota: `internal/http/router.go` + handler em `internal/http/handler/`.
- Nova regra de negocio: `internal/app/usecase/`.
- Nova integracao externa: `internal/app/service/` ou `internal/infra/*`.
- Nova tabela/consulta: `internal/infra/postgres/` + interface em `internal/app/repository/`.
