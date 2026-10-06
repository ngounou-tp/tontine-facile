#!/bin/bash
# Tests d'intégration du client Dart (repositories Supabase) contre une
# vraie API PostgREST, sur un PostgreSQL 16 jetable avec les migrations.
# Couvre requêtes, jointures, fonctions SQL et RLS ; pas le temps réel ni
# le stockage de fichiers (doublés dans les tests).
#
#   supabase/tests/run_api_local.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PGBIN="${PGBIN:-/usr/lib/postgresql/16/bin}"
POSTGREST="${POSTGREST_BIN:-$(command -v postgrest || echo /opt/postgrest/postgrest)}"
WORK="$(mktemp -d)"
PGPORT="${PGPORT_TEST:-54330}"
API_PORT="${API_PORT_TEST:-54331}"
JWT_SECRET="secret-de-test-pour-postgrest-au-moins-32-caracteres"
RUN_AS=()
if [ "$(id -u)" = "0" ]; then
  chown postgres "$WORK"
  RUN_AS=(runuser -u postgres --)
fi

cleanup() {
  [ -n "${API_PID:-}" ] && kill "$API_PID" 2>/dev/null || true
  "${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$WORK/data" -m immediate stop >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

"${RUN_AS[@]}" "$PGBIN/initdb" -D "$WORK/data" -U postgres -A trust >/dev/null
"${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$WORK/data" -o "-p $PGPORT -k $WORK -c listen_addresses=127.0.0.1" \
  -l "$WORK/log" -w start >/dev/null

PSQL=("${RUN_AS[@]}" psql -h "$WORK" -p "$PGPORT" -U postgres -v ON_ERROR_STOP=1 -q)
"${PSQL[@]}" -d postgres -c "create database app"
"${PSQL[@]}" -d app -f "$ROOT/supabase/tests/bootstrap/supabase_shim.sql" 2>/dev/null
for migration in "$ROOT"/supabase/migrations/*.sql; do
  "${PSQL[@]}" -d app -f "$migration" 2>/dev/null
done
"${PSQL[@]}" -d app <<'SQL'
create role authenticator login noinherit;
grant anon, authenticated, service_role to authenticator;
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'adele@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bruno@example.com'),
  ('33333333-3333-3333-3333-333333333333', 'chantal@example.com'),
  ('44444444-4444-4444-4444-444444444444', 'dora@example.com');
SQL

cat > "$WORK/postgrest.conf" <<CONF
db-uri = "postgres://authenticator@127.0.0.1:$PGPORT/app"
db-schemas = "public"
db-anon-role = "anon"
jwt-secret = "$JWT_SECRET"
server-host = "127.0.0.1"
server-port = $API_PORT
CONF
"$POSTGREST" "$WORK/postgrest.conf" >"$WORK/postgrest.log" 2>&1 &
API_PID=$!
for _ in $(seq 1 50); do
  curl -s -o /dev/null "http://127.0.0.1:$API_PORT/" && break
  sleep 0.2
done

cd "$ROOT"
POSTGREST_URL="http://127.0.0.1:$API_PORT" POSTGREST_JWT_SECRET="$JWT_SECRET" \
  flutter test test/integration --concurrency=1 "$@" || { cat "$WORK/postgrest.log"; exit 1; }
