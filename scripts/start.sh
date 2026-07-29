#!/usr/bin/env bash
# Start bootstrap (includes all projects) + run before/after setup hooks
# Usage: ./scripts/start.sh [--build]
#
# Order:
#   1) bootstrap before-start   (env + nginx sync)
#   2) project before-start    (compose run — e.g. npm install)
#   3) docker compose up
#   4) after-start             (bootstrap + projects)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_FLAG="${1:-}"
export ROOT BUILD_FLAG

# shellcheck source=scripts/_utils/hooks.sh
source "$ROOT/scripts/_utils/hooks.sh"

echo "[bootstrap] before-start..."
cryptomation_run_hooks before-start "$ROOT" bootstrap

echo "[bootstrap] project before-start..."
cryptomation_run_hooks before-start "$ROOT" projects

echo "[bootstrap] Starting shared infra + included projects..."
docker compose -f "$ROOT/docker-compose.yml" up -d $BUILD_FLAG

echo "[bootstrap] after-start..."
cryptomation_run_hooks after-start "$ROOT"
