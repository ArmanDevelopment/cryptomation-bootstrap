#!/usr/bin/env bash
# Show status of bootstrap stack containers
# Usage: ./scripts/status.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[bootstrap] Container status:"
docker compose -f "$ROOT/docker-compose.yml" ps -a
