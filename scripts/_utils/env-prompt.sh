#!/usr/bin/env bash
# Interactive .env creation from .env.example (key-by-key CLI prompts).
# Source from sync.sh or other scripts after ROOT is set.

# Prompt for one directory: if .env.example exists and .env does not,
# ask for each KEY (default = value from .env.example), then write .env.
# No-ops when already configured or when stdin/stdout is not a TTY
# (non-interactive runs fall through to cryptomation_sync_env cp).
cryptomation_prompt_env_file() {
  local dir="${1:?directory required}"
  local label="${2:-bootstrap}"
  local example="${dir%/}/.env.example"
  local target="${dir%/}/.env"

  [[ -f "$example" ]] || return 0
  [[ -f "$target" ]] && return 0

  if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
    return 0
  fi

  echo "[$label] .env missing — set values from .env.example (Enter = default):"

  local tmp line key default value
  tmp="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" RETURN

  # Read .env.example on FD 3 so interactive `read` keeps using stdin/TTY.
  exec 3<"$example"
  while IFS= read -r line <&3 || [[ -n "$line" ]]; do
    # Preserve blank lines and comments as-is
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
      printf '%s\n' "$line" >>"$tmp"
      continue
    fi

    # KEY=VALUE (optional leading whitespace / export)
    if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      key="${BASH_REMATCH[2]}"
      default="${BASH_REMATCH[3]}"
      value=""
      # -e allows arrow/backspace editing where the terminal supports it
      read -rep "  $key [$default]: " value || true
      if [[ -z "$value" ]]; then
        value="$default"
      fi
      printf '%s=%s\n' "$key" "$value" >>"$tmp"
      continue
    fi

    printf '%s\n' "$line" >>"$tmp"
  done
  exec 3<&-

  mv "$tmp" "$target"
  trap - RETURN
  echo "[$label] Created .env"
}

# Prompt bootstrap root + each projects/*/ that has docker-compose.yml.
cryptomation_prompt_env() {
  local root="${1:-$ROOT}"
  local project_dir name

  cryptomation_prompt_env_file "$root" "bootstrap"

  for project_dir in "$root/projects"/*/; do
    [[ -d "$project_dir" ]] || continue
    name="$(basename "$project_dir")"
    [[ -f "$project_dir/docker-compose.yml" ]] || continue
    cryptomation_prompt_env_file "$project_dir" "$name"
  done
}
