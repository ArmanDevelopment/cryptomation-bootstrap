#!/usr/bin/env bash
# Stop bootstrap stack (infra + included projects) + optional before/after hooks
# Usage: ./scripts/stop.sh [--volumes|-v]
#
# Order:
#   1) before-stop   (bootstrap + projects, if scripts exist)
#   2) docker compose down
#   3) after-stop    (bootstrap + projects, if scripts exist)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOWN_FLAG="${1:-}"
export ROOT

# shellcheck source=scripts/_utils/hooks.sh
source "$ROOT/scripts/_utils/hooks.sh"

case "$DOWN_FLAG" in
  "" ) ;;
  --volumes|-v) DOWN_FLAG="--volumes" ;;
  *)
    echo "Usage: $0 [--volumes|-v]"
    exit 1
    ;;
esac

echo "[bootstrap] before-stop..."
cryptomation_run_hooks before-stop "$ROOT"

echo "[bootstrap] Stopping shared infra + included projects..."
docker compose -f "$ROOT/docker-compose.yml" down ${DOWN_FLAG}

echo "[bootstrap] after-stop..."
cryptomation_run_hooks after-stop "$ROOT"

echo "[bootstrap] Stopped."
