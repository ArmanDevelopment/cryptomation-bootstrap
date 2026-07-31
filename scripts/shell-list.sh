#!/usr/bin/env bash
# List compose services you can join with make shell / scripts/shell.sh
# Usage: ./scripts/shell-list.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE=(docker compose -f "$ROOT/docker-compose.yml")

echo "[shell] Joinable (running) services:"
if ! mapfile -t services < <("${COMPOSE[@]}" ps --status running --services 2>/dev/null); then
  echo "  (compose unavailable)"
  exit 1
fi

if [[ ${#services[@]} -eq 0 ]]; then
  echo "  (none running — try: make start)"
  exit 0
fi

for s in "${services[@]}"; do
  echo "  $s"
done

echo ""
echo "Join with:  make shell service=<name>"
echo "Example:    make shell service=${services[0]}"
