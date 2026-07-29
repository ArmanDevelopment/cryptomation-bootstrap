#!/usr/bin/env bash
# Bootstrap setup before docker compose up.
# Invoked by scripts/start.sh (also runs each projects/*/scripts/before-start.sh).
#
# Available env: ROOT, BUILD_FLAG
set -euo pipefail

: "${ROOT:?ROOT must be set by start.sh}"

# shellcheck source=scripts/_utils/sync.sh
source "$ROOT/scripts/_utils/sync.sh"

cryptomation_sync_all "$ROOT"
