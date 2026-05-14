#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Logger - Colored output for scaffolder
# ═══════════════════════════════════════════════════════════════

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Log Functions ───────────────────────────────────────────
log_info() {
  echo -e "${CYAN}ℹ${RESET} $*"
}

log_success() {
  echo -e "${GREEN}✓${RESET} $*"
}

log_warn() {
  echo -e "${YELLOW}⚠${RESET} $*"
}

log_error() {
  echo -e "${RED}✗${RESET} $*" >&2
}

log_step() {
  echo -e "${BLUE}▸${RESET} $*"
}

log_bold() {
  echo -e "${BOLD}$*${RESET}"
}

log_dim() {
  echo -e "${DIM}$*${RESET}"
}

# ── Progress ────────────────────────────────────────────────
log_progress() {
  local current=$1
  local total=$2
  local width=40
  local percent=$((current * 100 / total))
  local filled=$((width * current / total))
  local empty=$((width - filled))
  
  printf "\r${CYAN}["
  printf "%${filled}s" | tr ' ' '█'
  printf "%${empty}s" | tr ' ' '░'
  printf "] ${percent}%%${RESET}"
  
  [[ $current -eq $total ]] && echo ""
}

# ── Debug (only if DEBUG=1) ────────────────────────────────
DEBUG="${DEBUG:-0}"
log_debug() {
  [[ "$DEBUG" == "1" ]] && echo -e "${DIM}DEBUG:${RESET} $*"
}