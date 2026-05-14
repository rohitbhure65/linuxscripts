#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Flutter Project Scaffolder - Entry Point
# ═══════════════════════════════════════════════════════════════

# ── Paths ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
OUT_DIR="${SCRIPT_DIR}/.fsetup.d"

# ── Load Utils ──────────────────────────────────────────────
source "${LIB_DIR}/utils/logger.sh"
source "${LIB_DIR}/utils/file_ops.sh"
source "${LIB_DIR}/utils/string_utils.sh"

# ── Load Config ─────────────────────────────────────────────
source "${LIB_DIR}/config/defaults.sh"
source "${LIB_DIR}/config/prompts.sh"

# ── Load Generators ────────────────────────────────────────
source "${LIB_DIR}/generators/core/index.sh"
source "${LIB_DIR}/generators/features/index.sh"

# ── Usage ─────────────────────────────────────────────────
usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -n, --name NAME        Project name (default: my_app)
  -i, --id ID            App ID (default: com.example.myapp)
  -c, --config FILE      Load config from FILE
  -o, --output DIR       Output directory (default: .fsetup.d)
  -y, --yes              Non-interactive mode
  -h, --help             Show this help

Examples:
  $(basename "$0") -n my_app -i com.mydomain.myapp
  $(basename "$0") --config config.yaml
  $(basename "$0") -y  # Non-interactive with defaults
EOF
}

# ── Parse Args ───────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--name)
        PROJECT_NAME="$2"
        shift 2
        ;;
      -i|--id)
        APP_ID="$2"
        shift 2
        ;;
      -c|--config)
        load_config "$2"
        shift 2
        ;;
      -o|--output)
        OUT_DIR="$2"
        shift 2
        ;;
      -y|--yes)
        NON_INTERACTIVE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

# ── Load Config File ───────────────────────────────────────
load_config() {
  local config_file="$1"
  if [[ -f "$config_file" ]]; then
    log_info "Loading config: $config_file"
    source "$config_file"
  else
    log_warn "Config file not found: $config_file"
  fi
}

# ── Main ─────────────────────────────────────────────────
main() {
  parse_args "$@"
  
  # Non-interactive mode
  if [[ "$NON_INTERACTIVE" == "1" ]]; then
    export_defaults
  else
    run_prompts
  fi
  
  # Setup output directory
  ensure_dir "$OUT_DIR" || exit 1
  ensure_dir "${OUT_DIR}/lib/core/constants"
  ensure_dir "${OUT_DIR}/lib/core/errors"
  ensure_dir "${OUT_DIR}/lib/core/network/api"
  ensure_dir "${OUT_DIR}/lib/core/network/connectivity"
  ensure_dir "${OUT_DIR}/lib/core/cache"
  ensure_dir "${OUT_DIR}/lib/core/services"
  ensure_dir "${OUT_DIR}/lib/core/theme"
  ensure_dir "${OUT_DIR}/lib/features/auth/data"
  ensure_dir "${OUT_DIR}/lib/features/auth/presentation"
  ensure_dir "${OUT_DIR}/lib/features/profile/data"
  ensure_dir "${OUT_DIR}/lib/features/profile/presentation"
  ensure_dir "${OUT_DIR}/lib/features/settings/data"
  ensure_dir "${OUT_DIR}/lib/features/settings/presentation"
  
  log_step "Generating project: ${PROJECT_NAME}"
  log_step "Output: ${OUT_DIR}"
  
  # Generate layers
  generate_core
  generate_features
  
  log_success "Done! Project generated at: ${OUT_DIR}"
  log_info "Next steps:"
  log_info "  cd ${OUT_DIR}"
  log_info "  flutter pub get"
  log_info "  code ."
}

# ── Run ─────────────────────────────────────────────────
main "$@"