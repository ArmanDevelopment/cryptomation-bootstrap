#!/usr/bin/env bash
# Project setup after start (optional — runs only if this file exists).
#
# Available env: ROOT, PROJECT_DIR, PROJECT_NAME, BUILD_FLAG
set -euo pipefail

: "${PROJECT_NAME:?}"
# Add project-specific post-start steps here, e.g. migrate, seed, health checks.
