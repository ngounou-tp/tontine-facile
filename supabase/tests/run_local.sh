#!/bin/bash
# Exécute les migrations et les tests pgTAP sur un PostgreSQL 16 jetable,
# sans Docker ni projet Supabase (voir bootstrap/supabase_shim.sql).
#
#   supabase/tests/run_local.sh
#
# Avec la CLI Supabase et Docker, `supabase test db` reste l'équivalent
# officiel.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PGBIN="${PGBIN:-/usr/lib/postgresql/16/bin}"
WORK="$(mktemp -d)"
PORT="${PGPORT_TEST:-54329}"
RUN_AS=()
if [ "$(id -u)" = "0" ]; then
  chown postgres "$WORK"
  RUN_AS=(runuser -u postgres --)
fi

cleanup() {
  "${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$WORK/data" -m immediate stop >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

"${RUN_AS[@]}" "$PGBIN/initdb" -D "$WORK/data" -U postgres -A trust >/dev/null
"${RUN_AS[@]}" "$PGBIN/pg_ctl" -D "$WORK/data" -o "-p $PORT -k $WORK -c listen_addresses=''" \
  -l "$WORK/log" -w start >/dev/null

PSQL=("${RUN_AS[@]}" psql -h "$WORK" -p "$PORT" -U postgres -v ON_ERROR_STOP=1 -q)
"${PSQL[@]}" -d postgres -c "create database app"
"${PSQL[@]}" -d app -f "$ROOT/supabase/tests/bootstrap/supabase_shim.sql"
for migration in "$ROOT"/supabase/migrations/*.sql; do
  "${PSQL[@]}" -d app -f "$migration"
done
"${PSQL[@]}" -d app -c "create extension if not exists pgtap"
"${PSQL[@]}" -d app -f "$ROOT/supabase/tests/bootstrap/test_helpers.sql"

"${RUN_AS[@]}" pg_prove -h "$WORK" -p "$PORT" -U postgres -d app \
  "$ROOT"/supabase/tests/database/*.sql
