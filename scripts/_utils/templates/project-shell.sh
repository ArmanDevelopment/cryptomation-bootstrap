#!/usr/bin/env bash
# Synced from cryptomation-bootstrap (scripts/_utils/templates/project-shell.sh).
# Do not edit here — change the bootstrap template and re-run sync / make start.
#
# Usage (from this project root):
#   ./shell
#   ./shell cryptomation-frontend
#   ./shell nginx sh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_SERVICE="$(basename "$PROJECT_ROOT")"
SERVICE="${1:-$DEFAULT_SERVICE}"
SHELL_BIN="${2:-bash}"

BOOTSTRAP="$(cd "$PROJECT_ROOT/../cryptomation-bootstrap" && pwd)"
if [[ ! -f "$BOOTSTRAP/Makefile" ]]; then
  echo "[shell] cryptomation-bootstrap not found next to this project: $BOOTSTRAP" >&2
  exit 1
fi

cd "$BOOTSTRAP"
exec make shell service="$SERVICE" shell_bin="$SHELL_BIN"
