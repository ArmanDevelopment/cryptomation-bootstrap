#!/usr/bin/env bash
# Project setup before long-running containers (runs in project dir scope).
# Uses `docker compose run` so deps install without needing the app container up.
# Skips install when node_modules exists and package.json + lockfile hash match.
#
# Available env: ROOT, PROJECT_DIR, PROJECT_NAME, BUILD_FLAG
# CWD: projects/<name>/
set -euo pipefail

: "${PROJECT_NAME:?}"

SERVICE="${PROJECT_NAME}"
COMPOSE=(docker compose)
[[ -f docker-compose.yml ]] || {
  echo "[$PROJECT_NAME] ERROR: docker-compose.yml not found in $(pwd)"
  exit 1
}

run_args=(run --rm --no-deps)
[[ -n "${BUILD_FLAG:-}" ]] && run_args+=("${BUILD_FLAG}")

echo "[$PROJECT_NAME] Checking npm deps (compose run)..."

# Hash package.json + package-lock.json; stamp lives in the node_modules volume.
# --no-fund/--no-audit: silence funding + audit noise on routine installs.
"${COMPOSE[@]}" "${run_args[@]}" --entrypoint sh "$SERVICE" -c '
  set -e
  HASH=$( (md5sum package.json package-lock.json 2>/dev/null || true) | md5sum | awk "{print \$1}" )
  STAMP="node_modules/.deps-hash"

  if [ -d node_modules ] && [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$HASH" ]; then
    echo "deps unchanged (hash=$HASH) — skip npm install"
    exit 0
  fi

  echo "deps changed or missing — npm install"
  npm install --no-fund --no-audit
  mkdir -p node_modules
  echo "$HASH" > "$STAMP"
  echo "deps stamp written ($HASH)"
'

echo "[$PROJECT_NAME] npm deps ready."
