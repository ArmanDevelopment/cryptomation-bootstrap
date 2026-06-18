#!/usr/bin/env bash
# Start bootstrap infra + all projects + reload nginx
# Usage: ./scripts/start.sh [--build]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_FLAG="${1:-}"

# Bootstrap .env
if [[ ! -f "$ROOT/.env" ]]; then
  cp "$ROOT/.env.example" "$ROOT/.env"
  echo "[bootstrap] Created .env from .env.example — edit if needed."
fi

echo "[bootstrap] Starting shared infra..."
docker compose -f "$ROOT/docker-compose.yml" up -d

echo "[bootstrap] Waiting for cryptomation_shared network..."
until docker network inspect cryptomation_shared >/dev/null 2>&1; do sleep 1; done

# Start each project
for project_dir in "$ROOT/projects"/*/; do
  name="$(basename "$project_dir")"
  compose="$project_dir/docker-compose.yml"
  [[ -f "$compose" ]] || continue

  if [[ ! -f "$project_dir/.env" && -f "$project_dir/.env.example" ]]; then
    cp "$project_dir/.env.example" "$project_dir/.env"
    echo "[$name] Created .env from .env.example — edit if needed."
  fi

  echo "[$name] Starting..."
  docker compose -f "$compose" up -d $BUILD_FLAG
done

echo "[nginx] Reloading..."
docker exec cryptomation_nginx nginx -s reload

echo ""
echo "All services up. Add to /etc/hosts if needed:"
echo "  127.0.0.1  cryptomation.local"
