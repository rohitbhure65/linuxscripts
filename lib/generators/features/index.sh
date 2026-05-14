#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Features Layer - All feature generators
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/generators/features/auth.sh"
source "${LIB_DIR}/generators/features/profile.sh"
source "${LIB_DIR}/generators/features/settings.sh"

# ── Generate All Features ───────────────────────────────
generate_features() {
  log_step "Generating features layer..."
  
  generate_auth
  generate_profile
  generate_settings
  
  log_success "Features layer complete"
}