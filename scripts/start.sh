#!/usr/bin/env bash
# Start bootstrap (includes all projects) + reload nginx
# Usage: ./scripts/start.sh [--build]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_FLAG="${1:-}"

# Bootstrap .env
if [[ ! -f "$ROOT/.env" ]]; then
  cp "$ROOT/.env.example" "$ROOT/.env"
  echo "[bootstrap] Created .env from .env.example — edit if needed."
fi

# Project .env files (services reference env_file: .env relative to each project)
for project_dir in "$ROOT/projects"/*/; do
  name="$(basename "$project_dir")"
  [[ -f "$project_dir/docker-compose.yml" ]] || continue

  if [[ ! -f "$project_dir/.env" && -f "$project_dir/.env.example" ]]; then
    cp "$project_dir/.env.example" "$project_dir/.env"
    echo "[$name] Created .env from .env.example — edit if needed."
  fi
done

echo "[bootstrap] Starting shared infra + included projects..."
docker compose -f "$ROOT/docker-compose.yml" up -d $BUILD_FLAG

echo "[nginx] Reloading..."
docker exec cryptomation_nginx nginx -s reload

# shellcheck disable=SC1091
set -a
source "$ROOT/.env"
set +a
PORT="${NGINX_HTTP_PORT:-80}"
HOST="${NGINX_SERVER_NAME:-cryptomation.local}"
if [[ "$PORT" == "80" ]]; then
  URL="http://${HOST}/"
else
  URL="http://${HOST}:${PORT}/"
fi

echo ""
echo "All services up."
echo ""
echo "1) Map the domain (once) — requires sudo:"
echo "     grep -q '${HOST}' /etc/hosts || echo '127.0.0.1  ${HOST}' | sudo tee -a /etc/hosts"
echo "2) Open:  $URL"
echo "   (NGINX_HTTP_PORT=${PORT}, NGINX_SERVER_NAME=${HOST})"
