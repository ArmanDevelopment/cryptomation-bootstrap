#!/usr/bin/env bash
# Install PHP deps before long-running php-fpm (runs in project dir scope).
# Uses `docker compose run` so composer install does not need the app container up.
# Skips install when vendor exists and composer.json + composer.lock hash match.
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

echo "[$PROJECT_NAME] Checking composer deps (compose run)..."

"${COMPOSE[@]}" "${run_args[@]}" --entrypoint sh "$SERVICE" -c '
  set -e
  HASH=$( (md5sum composer.json composer.lock 2>/dev/null || true) | md5sum | awk "{print \$1}" )
  STAMP="vendor/.deps-hash"

  if [ -d vendor ] && [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$HASH" ]; then
    echo "deps unchanged (hash=$HASH) — skip composer install"
    exit 0
  fi

  echo "deps changed or missing — composer install"
  composer install --no-interaction --prefer-dist --no-ansi
  mkdir -p vendor
  echo "$HASH" > "$STAMP"
  echo "deps stamp written ($HASH)"
'

echo "[$PROJECT_NAME] composer deps ready."
