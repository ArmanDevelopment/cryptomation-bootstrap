#!/usr/bin/env bash
# Shared helpers for cryptomation-bootstrap scripts.
# Source from other scripts after ROOT is set, or run directly.

# Resolve bootstrap root when this file is sourced or executed.
_cryptomation_utils_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${ROOT:=$(cd "${_cryptomation_utils_dir}/../.." && pwd)}"

# shellcheck source=scripts/_utils/env-prompt.sh
source "${_cryptomation_utils_dir}/env-prompt.sh"

# Copy sibling app .env.example into projects/*/.env.example (e.g. Laravel).
# Does not touch .env — run before prompting so keys are current.
cryptomation_sync_project_env_examples() {
  local root="${1:-$ROOT}"
  local project_dir name sibling sibling_example example

  for project_dir in "$root/projects"/*/; do
    [[ -d "$project_dir" ]] || continue
    name="$(basename "$project_dir")"
    [[ -f "$project_dir/docker-compose.yml" ]] || continue

    sibling="$(cd "$root/.." && pwd)/$name"
    sibling_example="$sibling/.env.example"
    example="${project_dir%/}/.env.example"

    if [[ -f "$sibling_example" ]]; then
      cp "$sibling_example" "$example"
      echo "[$name] Synced .env.example ← ../$name/.env.example"
    fi
  done
}

# Create missing .env from .env.example (never clobber). Interactive runs
# prompt first via cryptomation_prompt_env; this is the non-interactive fallback.
cryptomation_ensure_env_files() {
  local root="${1:-$ROOT}"
  local project_dir name sibling example target

  if [[ ! -f "$root/.env" && -f "$root/.env.example" ]]; then
    cp "$root/.env.example" "$root/.env"
    echo "[bootstrap] Created .env from .env.example — edit if needed."
  fi

  for project_dir in "$root/projects"/*/; do
    [[ -d "$project_dir" ]] || continue
    name="$(basename "$project_dir")"
    [[ -f "$project_dir/docker-compose.yml" ]] || continue

    example="${project_dir%/}/.env.example"
    target="${project_dir%/}/.env"
    sibling="$(cd "$root/.." && pwd)/$name"

    if [[ ! -f "$target" && -f "$example" ]]; then
      cp "$example" "$target"
      echo "[$name] Created .env from .env.example"
    fi

    # Laravel (and similar) read the sibling repo .env, not the bootstrap copy.
    if [[ -d "$sibling" && ! -f "$sibling/.env" && -f "$target" ]]; then
      cp "$target" "$sibling/.env"
      echo "[$name] Created ../$name/.env from projects/$name/.env"
    fi
  done
}

cryptomation_sync_env() {
  local root="${1:-$ROOT}"
  cryptomation_sync_project_env_examples "$root"
  cryptomation_ensure_env_files "$root"
}

# Copy shared gateway + optional extra project server blocks → nginx/templates/.
cryptomation_sync_nginx_templates() {
  local root="${1:-$ROOT}"
  local dest="$root/nginx/templates"
  local project_dir name nginx_dir src synced=0

  mkdir -p "$dest"
  rm -f "$dest"/*.conf.template

  if [[ -f "$root/nginx/gateway.conf.template" ]]; then
    cp "$root/nginx/gateway.conf.template" "$dest/default.conf.template"
    echo "[nginx] Synced templates/default.conf.template ← nginx/gateway.conf.template"
    synced=$((synced + 1))
  fi

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
    echo "[nginx] Warning: no nginx templates found (gateway or projects/*/nginx/)"
  fi
}

# Copy projects/*/nginx/locations/* → nginx/locations/ (included by the gateway vhost).
cryptomation_sync_nginx_locations() {
  local root="${1:-$ROOT}"
  local dest="$root/nginx/locations"
  local project_dir name loc_dir src base dest_name synced=0

  mkdir -p "$dest"
  rm -f "$dest"/*.conf

  for project_dir in "$root/projects"/*/; do
    [[ -d "$project_dir" ]] || continue
    name="$(basename "$project_dir")"
    loc_dir="$project_dir/nginx/locations"
    [[ -d "$loc_dir" ]] || continue

    for src in "$loc_dir"/*.conf "$loc_dir"/*.conf.template; do
      [[ -f "$src" ]] || continue
      base="$(basename "$src")"
      dest_name="${base%.template}"
      cp "$src" "$dest/${name}-${dest_name}"
      echo "[nginx] Synced locations/${name}-${dest_name} ← projects/${name}/nginx/locations/"
      synced=$((synced + 1))
    done
  done

  if [[ "$synced" -eq 0 ]]; then
    echo "[nginx] Warning: no location snippets found under projects/*/nginx/locations/"
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

# Run all pre-start syncs (env prompt + env + nginx + shared network + shell helpers).
cryptomation_sync_all() {
  local root="${1:-$ROOT}"
  cryptomation_prompt_env "$root"
  cryptomation_ensure_env_files "$root"
  cryptomation_sync_nginx_templates "$root"
  cryptomation_sync_nginx_locations "$root"
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
    locations|nginx-locations) cryptomation_sync_nginx_locations ;;
    network) cryptomation_ensure_network ;;
    shell|shell-helpers) cryptomation_sync_project_shell_helpers ;;
    all) cryptomation_sync_all ;;
    *)
      echo "Usage: $0 [all|prompt|env|nginx|locations|network|shell]"
      exit 1
      ;;
  esac
fi
