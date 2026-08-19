#!/usr/bin/env bash
# Key + migrate after php-fpm and postgres are up.
#
# Available env: ROOT, PROJECT_DIR, PROJECT_NAME, BUILD_FLAG
# CWD: projects/<name>/
set -euo pipefail

: "${PROJECT_NAME:?}"
: "${ROOT:?}"

SERVICE="${PROJECT_NAME}"
COMPOSE=(docker compose)
SIBLING="$(cd "$ROOT/.." && pwd)/$PROJECT_NAME"
ENV_FILE="$SIBLING/.env"

echo "[$PROJECT_NAME] Waiting for postgres..."
for _ in $(seq 1 30); do
  if docker exec cryptomation_postgres pg_isready -U "${POSTGRES_USER:-cryptomation}" -d "${POSTGRES_DB:-cryptomation}" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if [[ -f "$ENV_FILE" ]]; then
  APP_KEY_VAL="$(grep -E '^APP_KEY=' "$ENV_FILE" | cut -d= -f2- || true)"
  if [[ -z "$APP_KEY_VAL" ]]; then
    echo "[$PROJECT_NAME] Generating APP_KEY..."
    "${COMPOSE[@]}" exec -T "$SERVICE" php artisan key:generate --no-interaction --ansi
  fi
else
  echo "[$PROJECT_NAME] Warning: Laravel .env missing at $ENV_FILE"
fi

echo "[$PROJECT_NAME] Ensuring storage is writable..."
"${COMPOSE[@]}" exec -T "$SERVICE" sh -c 'mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache && chmod -R ug+rwx storage bootstrap/cache'

echo "[$PROJECT_NAME] Running migrations..."
"${COMPOSE[@]}" exec -T "$SERVICE" php artisan migrate --force --no-interaction --ansi

echo "[$PROJECT_NAME] Laravel ready."
