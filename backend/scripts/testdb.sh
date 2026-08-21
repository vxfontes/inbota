#!/usr/bin/env bash
#
# testdb.sh — Postgres descartavel pros testes de integracao do backend.
#
# NAO usa docker-compose.yml. O compose e arquivo versionado e o servico `db`
# esta comentado la de proposito; descomentar sujaria a working tree. Aqui e
# `docker run` puro, container nomeado, porta alta, banco proprio.
#
# NUNCA aponta pra producao:
#   - banco chamado organiq_test (o teste recusa qualquer outro nome);
#   - so escuta em 127.0.0.1;
#   - a DSN sai numa variavel PROPRIA, ORGANIQ_TEST_DATABASE_URL, que nao tem
#     fallback pra DATABASE_URL do lado do Go.
#
# Uso:
#   backend/scripts/testdb.sh up      # sobe + aplica db/ + imprime o export
#   backend/scripts/testdb.sh dsn     # so imprime o export
#   backend/scripts/testdb.sh status  # estado do container
#   backend/scripts/testdb.sh reset   # derruba, sobe de novo e reaplica
#   backend/scripts/testdb.sh down    # derruba e remove
#
set -euo pipefail

CONTAINER=organiq-test-db
IMAGE=postgres:16-alpine
HOST_PORT=55432
DB_NAME=organiq_test
DB_USER=organiq
DB_PASS=organiq_test_pw          # descartavel, local, sem valor fora daqui
PSQL_ARGS=(--username "$DB_USER" --dbname "$DB_NAME" --set ON_ERROR_STOP=1 --quiet)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DB_DIR="$REPO_ROOT/db"

DSN="postgres://${DB_USER}:${DB_PASS}@127.0.0.1:${HOST_PORT}/${DB_NAME}?sslmode=disable"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

require_docker() {
  command -v docker >/dev/null 2>&1 || die "docker nao esta no PATH."
  docker info >/dev/null 2>&1 || die "daemon do Docker nao esta respondendo (abra o OrbStack e tente de novo)."
}

psql_run() { docker exec -i "$CONTAINER" psql "${PSQL_ARGS[@]}" "$@"; }

# ---------------------------------------------------------------------------
# Ordem de aplicacao do db/
#
# Duas armadilhas conhecidas deste repo, tratadas explicitamente aqui:
#
#   1. `x.x.x` e template, nao versao. Por ordenacao alfabetica ele cairia no
#      fim do replay e seria aplicado. Fica de fora por nome.
#
#   2. As versoes 0.0.1..0.2.0 escrevem em `inbota.*` e da 0.3.0 em diante em
#      `organiq.*`. Nao existe script de rename entre as duas — o rename foi
#      feito fora do versionamento. Replay ingenuo quebra na 0.3.0 com
#      `schema "organiq" does not exist`. Aqui o rename e feito na mao, na
#      fronteira, e isso esta anotado porque e divida do db/, nao feature.
#
# functions/ e views/ tambem nao sao referenciados por \i em lugar nenhum, entao
# sao aplicados explicitamente depois do script_pre.sql da versao.
# ---------------------------------------------------------------------------

RENAME_AFTER="0.2.0"

versions() {
  find "$DB_DIR" -mindepth 1 -maxdepth 1 -type d ! -name 'x.x.x' -exec basename {} \; | sort -V
}

apply_sql_file() {
  local f="$1"
  [ -f "$f" ] || return 0
  log "aplicando ${f#$REPO_ROOT/}"
  if ! psql_run < "$f"; then
    die "falhou em ${f#$REPO_ROOT/}. Nao vou seguir com o banco meio aplicado."
  fi
}

apply_dir() {
  local d="$1"
  [ -d "$d" ] || return 0
  local f
  while IFS= read -r f; do
    apply_sql_file "$f"
  done < <(find "$d" -maxdepth 1 -name '*.sql' | sort)
}

do_rename() {
  local has_inbota has_organiq
  has_inbota=$(psql_run -tAc "select 1 from information_schema.schemata where schema_name='inbota'" || true)
  has_organiq=$(psql_run -tAc "select 1 from information_schema.schemata where schema_name='organiq'" || true)

  if [ "${has_inbota//[[:space:]]/}" = "1" ] && [ "${has_organiq//[[:space:]]/}" != "1" ]; then
    warn "renomeando schema inbota -> organiq (divida do db/: o rename real nunca foi versionado)"
    psql_run -c 'ALTER SCHEMA inbota RENAME TO organiq;' >/dev/null
  fi
}

apply_schema() {
  local v
  for v in $(versions); do
    log "versao $v"
    apply_sql_file "$DB_DIR/$v/script_pre.sql"
    apply_dir      "$DB_DIR/$v/functions"
    apply_dir      "$DB_DIR/$v/views"
    apply_sql_file "$DB_DIR/$v/script_pos.sql"

    if [ "$v" = "$RENAME_AFTER" ]; then
      do_rename
    fi
  done

  psql_run -c "ALTER DATABASE ${DB_NAME} SET search_path TO organiq, public;" >/dev/null
  log "schema aplicado; search_path do banco fixado em organiq,public"
}

# ---------------------------------------------------------------------------

cmd_up() {
  require_docker

  if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
      warn "container $CONTAINER ja esta de pe. Use 'reset' se quiser do zero."
      cmd_dsn
      return 0
    fi
    log "container existe parado; subindo"
    docker start "$CONTAINER" >/dev/null
  else
    log "subindo $CONTAINER ($IMAGE) em 127.0.0.1:$HOST_PORT"
    docker run --rm -d \
      --name "$CONTAINER" \
      -e POSTGRES_DB="$DB_NAME" \
      -e POSTGRES_USER="$DB_USER" \
      -e POSTGRES_PASSWORD="$DB_PASS" \
      -p "127.0.0.1:${HOST_PORT}:5432" \
      "$IMAGE" >/dev/null
  fi

  log "esperando o Postgres aceitar conexao"
  local i
  for i in $(seq 1 60); do
    if docker exec "$CONTAINER" pg_isready -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
      break
    fi
    [ "$i" -eq 60 ] && die "Postgres nao ficou pronto em 60s."
    sleep 1
  done

  apply_schema
  cmd_dsn
}

cmd_down() {
  require_docker
  if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    log "removendo $CONTAINER"
    docker rm -f "$CONTAINER" >/dev/null
  else
    warn "container $CONTAINER nao existe."
  fi
}

cmd_reset() { cmd_down; cmd_up; }

cmd_status() {
  require_docker
  docker ps -a --filter "name=^${CONTAINER}$" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

cmd_dsn() {
  echo
  echo "export ORGANIQ_TEST_DATABASE_URL='${DSN}'"
  echo
  echo "  go test -tags integration ./internal/app/usecase/ -run 'TestInbox|TestTxBound' -v"
  echo
}

case "${1:-up}" in
  up)     cmd_up ;;
  down)   cmd_down ;;
  reset)  cmd_reset ;;
  status) cmd_status ;;
  dsn)    cmd_dsn ;;
  *)      die "uso: $(basename "$0") {up|down|reset|status|dsn}" ;;
esac
