#!/usr/bin/env bash
# Hook runners — bootstrap + per-project scripts/<hook>.sh if present.
# Source after ROOT is set (via sync.sh or start.sh).

cryptomation_run_script_if_exists() {
  local script="$1"
  local label="${2:-}"
  local workdir="${3:-}"

  [[ -f "$script" ]] || return 0
  [[ -r "$script" ]] || return 0

  if [[ -n "$label" ]]; then
    echo "[$label] Running $(basename "$(dirname "$script")")/$(basename "$script")..."
  fi

  if [[ -n "$workdir" ]]; then
    (cd "$workdir" && bash "$script")
  else
    bash "$script"
  fi
}

cryptomation_run_bootstrap_hook() {
  local hook="${1:?}"
  local root="${2:-$ROOT}"

  export ROOT="$root"
  export BUILD_FLAG="${BUILD_FLAG:-}"
  cryptomation_run_script_if_exists "$root/scripts/${hook}.sh" "bootstrap" "$root"
}

cryptomation_run_project_hooks() {
  local hook="${1:?}"
  local root="${2:-$ROOT}"
  local project_dir name

  export ROOT="$root"
  export BUILD_FLAG="${BUILD_FLAG:-}"

  for project_dir in "$root/projects"/*/; do
    [[ -d "$project_dir" ]] || continue
    name="$(basename "$project_dir")"
    [[ -f "$project_dir/docker-compose.yml" ]] || continue

    export PROJECT_DIR="${project_dir%/}"
    export PROJECT_NAME="$name"

    # Run in project directory so `docker compose` uses that project's compose file
    cryptomation_run_script_if_exists "$project_dir/scripts/${hook}.sh" "$name" "$PROJECT_DIR"
  done

  unset PROJECT_DIR PROJECT_NAME
}

# Run bootstrap then project hooks (legacy/all-in-one).
# Optional 3rd arg: all|bootstrap|projects (default all)
cryptomation_run_hooks() {
  local hook="${1:?hook name required (before-start|after-start)}"
  local root="${2:-$ROOT}"
  local scope="${3:-all}"

  case "$scope" in
    bootstrap) cryptomation_run_bootstrap_hook "$hook" "$root" ;;
    projects) cryptomation_run_project_hooks "$hook" "$root" ;;
    all)
      cryptomation_run_bootstrap_hook "$hook" "$root"
      cryptomation_run_project_hooks "$hook" "$root"
      ;;
    *)
      echo "Unknown hook scope: $scope (use all|bootstrap|projects)" >&2
      return 1
      ;;
  esac
}
