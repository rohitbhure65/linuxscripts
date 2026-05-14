#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Core Layer - All core generators
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/generators/core/constants.sh"
source "${LIB_DIR}/generators/core/errors.sh"
source "${LIB_DIR}/generators/core/network.sh"
source "${LIB_DIR}/generators/core/cache.sh"
source "${LIB_DIR}/generators/core/services.sh"
source "${LIB_DIR}/generators/core/theme.sh"

# ── Generate All Core ─────────────────────────────────────
generate_core() {
  log_step "Generating core layer..."
  
  generate_constants
  generate_errors
  generate_network
  generate_cache
  generate_services
  generate_theme
  
  log_success "Core layer complete"
}