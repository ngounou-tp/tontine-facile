#!/bin/bash
# Prépare une session cloud Claude Code : Flutter (analyze/test) et
# PostgreSQL 16 + pgTAP (tests SQL du backend Supabase, voir supabase/tests).
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_DIR=/opt/flutter
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
echo "export PATH=\"$FLUTTER_DIR/bin:\$PATH\"" >> "${CLAUDE_ENV_FILE:-/dev/null}"
flutter --disable-analytics >/dev/null 2>&1 || true
flutter --version >/dev/null

cd "$CLAUDE_PROJECT_DIR"
flutter pub get

if ! dpkg -s postgresql-16-pgtap >/dev/null 2>&1; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq postgresql-16 postgresql-16-pgtap libtap-parser-sourcehandler-pgtap-perl >/dev/null
fi
echo 'export PATH="/usr/lib/postgresql/16/bin:$PATH"' >> "${CLAUDE_ENV_FILE:-/dev/null}"
