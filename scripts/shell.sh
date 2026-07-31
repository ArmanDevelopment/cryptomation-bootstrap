#!/usr/bin/env bash
# Open an interactive shell in a running compose service
# Usage:
#   ./scripts/shell.sh [service] [shell]
#   make shell
#   make shell service=cryptomation-frontend
#   make shell service=nginx shell_bin=sh
#
# Defaults: service=cryptomation-frontend, shell=bash (falls back to sh)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE="${1:-cryptomation-frontend}"
SHELL_BIN="${2:-bash}"
COMPOSE=(docker compose -f "$ROOT/docker-compose.yml")

if ! "${COMPOSE[@]}" ps --status running --services 2>/dev/null | grep -qx "$SERVICE"; then
  echo "[shell] Service '$SERVICE' is not running. Try: make status / make start"
  exit 1
fi

if "${COMPOSE[@]}" exec -T "$SERVICE" "$SHELL_BIN" -c 'exit 0' >/dev/null 2>&1; then
  exec "${COMPOSE[@]}" exec "$SERVICE" "$SHELL_BIN"
fi

if [[ "$SHELL_BIN" != "sh" ]]; then
  echo "[shell] '$SHELL_BIN' not available in $SERVICE — using sh"
fi
exec "${COMPOSE[@]}" exec "$SERVICE" sh
