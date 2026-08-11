#!/usr/bin/env bash
# Shared helpers for cryptomation-bootstrap scripts.
# Source from other scripts after ROOT is set, or run directly.

# Resolve bootstrap root when this file is sourced or executed.
_cryptomation_utils_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ROOT:=$(cd "${_cryptomation_utils_dir}/../.." && pwd)}"

# shellcheck source=scripts/_utils/env-prompt.sh
source "${_cryptomation_utils_dir}/env-prompt.sh"

# Ensure bootstrap .env and each project's .env exist (from *.example).
cryptomation_sync_env() {
  local root="${1:-$ROOT}"

  if [[ ! -f "$root/.env" && -f "$root/.env.example" ]]; then
    cp "$root/.env.example" "$root/.env"
    echo "[bootstrap] Created .env from .env.example — edit if needed."
  fi

  local project_dir name
  for project_dir in "$root/projects"/*/; do
    [[ -d "$project_dir" ]] || continue
    name="$(basename "$project_dir")"
    [[ -f "$project_dir/docker-compose.yml" ]] || continue

    if [[ ! -f "$project_dir/.env" && -f "$project_dir/.env.example" ]]; then
      cp "$project_dir/.env.example" "$project_dir/.env"
      echo "[$name] Created .env from .env.example — edit if needed."
    fi
  done
}

# Copy projects/*/nginx configs → nginx/templates/ (gitignored).
cryptomation_sync_nginx_templates() {
  local root="${1:-$ROOT}"
  local dest="$root/nginx/templates"
  local project_dir name nginx_dir src synced=0

  mkdir -p "$dest"
  rm -f "$dest"/*.conf.template

  for project_dir in "$root/projects"/*/; do
    [[ -d "$project_dir" ]] || continue
    name="$(basename "$project_dir")"
    nginx_dir="$project_dir/nginx"

    src=""
    if [[ -f "$nginx_dir/${name}.conf.template" ]]; then
      src="$nginx_dir/${name}.conf.template"
    elif [[ -f "$nginx_dir/default.conf.template" ]]; then
      src="$nginx_dir/default.conf.template"
    elif [[ -f "$nginx_dir/default.conf" ]]; then
      src="$nginx_dir/default.conf"
    else
      continue
    fi

    cp "$src" "$dest/${name}.conf.template"
    echo "[nginx] Synced templates/${name}.conf.template ← projects/${name}/nginx/"
    synced=$((synced + 1))
  done

  if [[ "$synced" -eq 0 ]]; then
    echo "[nginx] Warning: no project nginx templates found under projects/*/nginx/"
  fi
}

# Ensure shared Docker network exists (compose marks it external).
# Recreate if it still has compose project labels from an old project name —
# those labels trigger noisy warnings even when we intend the network to be shared.
cryptomation_ensure_network() {
  local name="${1:-cryptomation_shared}"
  local project_label=""

  if docker network inspect "$name" >/dev/null 2>&1; then
    project_label="$(docker network inspect -f '{{index .Labels "com.docker.compose.project"}}' "$name" 2>/dev/null || true)"
    if [[ -z "$project_label" ]]; then
      return 0
    fi
    # In use by running containers? keep it — external:true still works.
    if docker network inspect -f '{{len .Containers}}' "$name" 2>/dev/null | grep -vq '^0$'; then
      return 0
    fi
    echo "[bootstrap] Recreating network $name (was owned by compose project: ${project_label})"
    docker network rm "$name" >/dev/null
  fi

  docker network create --driver bridge "$name" >/dev/null
  echo "[bootstrap] Created docker network: $name"
}

# Ensure a named volume exists (optional; for external volumes).
cryptomation_ensure_volume() {
  local name="${1:?volume name required}"

  if docker volume inspect "$name" >/dev/null 2>&1; then
    return 0
  fi

  docker volume create "$name" >/dev/null
  echo "[bootstrap] Created docker volume: $name"
}

# Copy a fast ./shell helper into sibling app repos (e.g. ../cryptomation-frontend).
# Invokes bootstrap: make shell service=<name>
cryptomation_sync_project_shell_helpers() {
  local root="${1:-$ROOT}"
  local template="$root/scripts/_utils/templates/project-shell.sh"
  local project_dir name sibling dest synced=0

  if [[ ! -f "$template" ]]; then
    echo "[shell] Warning: template missing: $template"
    return 0
  fi

  for project_dir in "$root/projects"/*/; do
    [[ -d "$project_dir" ]] || continue
    name="$(basename "$project_dir")"
    [[ -f "$project_dir/docker-compose.yml" ]] || continue

    sibling="$(cd "$root/.." && pwd)/$name"
    [[ -d "$sibling" ]] || continue

    dest="$sibling/shell"
    cp "$template" "$dest"
    chmod +x "$dest"
    echo "[shell] Synced $name/shell → make shell service=…"
    synced=$((synced + 1))
  done

  if [[ "$synced" -eq 0 ]]; then
    echo "[shell] No sibling app dirs found to sync ./shell into (expected ../<project-name>/)"
  fi
}

# Run all pre-start syncs (env prompt + env + nginx templates + shared network + shell helpers).
cryptomation_sync_all() {
  local root="${1:-$ROOT}"
  cryptomation_prompt_env "$root"
  cryptomation_sync_env "$root"
  cryptomation_sync_nginx_templates "$root"
  cryptomation_ensure_network cryptomation_shared
  cryptomation_sync_project_shell_helpers "$root"
}

# Allow: ./scripts/_utils/sync.sh  or bash scripts/_utils/*.sh patterns via this entry
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  case "${1:-all}" in
    prompt|env-prompt) cryptomation_prompt_env ;;
    env) cryptomation_sync_env ;;
    nginx|nginx-templates) cryptomation_sync_nginx_templates ;;
    network) cryptomation_ensure_network ;;
    shell|shell-helpers) cryptomation_sync_project_shell_helpers ;;
    all) cryptomation_sync_all ;;
    *)
      echo "Usage: $0 [all|prompt|env|nginx|network|shell]"
      exit 1
      ;;
  esac
fi
