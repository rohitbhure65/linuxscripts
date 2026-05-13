#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# syncscripts — Copy all bashrc-sourced scripts to current directory
#
# INSTALL:
#   cp syncscripts.sh ~/syncscripts.sh
#   chmod +x ~/syncscripts.sh
#   echo 'alias syncscripts="bash ~/syncscripts.sh"' >> ~/.bashrc
#   source ~/.bashrc
#
# USAGE:
#   syncscripts        → Copy all scripts to current directory
#   syncscripts /path  → Copy all scripts to specified path
# ─────────────────────────────────────────────────────────────────

syncscripts(){


# Colors
R='\033[0;31m'; LR='\033[1;31m'
G='\033[0;32m'; LG='\033[1;32m'
Y='\033[1;33m'
C='\033[0;36m'; LC='\033[1;36m'
W='\033[1;37m'; DIM='\033[2m'
BOLD='\033[1m'; RESET='\033[0m'

BASHRC="$HOME/.bashrc"
DEST="${1:-$(pwd)}"

echo ""
echo -e "${BOLD}${LC}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${LC}║   📦  syncscripts — Bashrc Script Exporter                   ║${RESET}"
echo -e "${BOLD}${LC}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${DIM}Reading:     ${W}${BASHRC}${RESET}"
echo -e "  ${DIM}Copying to:  ${W}${DEST}${RESET}"
echo ""

# ── Guard: bashrc must exist ──────────────────────────────────────
if [[ ! -f "$BASHRC" ]]; then
  echo -e "  ${LR}✗ ~/.bashrc not found.${RESET}"
  exit 1
fi

# ── Guard: destination must exist ────────────────────────────────
if [[ ! -d "$DEST" ]]; then
  echo -e "  ${Y}⚠  Destination does not exist. Creating: ${DEST}${RESET}"
  mkdir -p "$DEST" || { echo -e "  ${LR}✗ Could not create destination.${RESET}"; exit 1; }
fi

# ── Collect all sourced files from .bashrc ────────────────────────
declare -a FILES_TO_COPY=()

# Extract lines like: source ~/.*.sh  OR  . ~/.*.sh
while IFS= read -r LINE; do
  # Skip comments
  [[ "$LINE" =~ ^[[:space:]]*# ]] && continue

  # Match: source ~/something  OR  . ~/something
  if [[ "$LINE" =~ ^[[:space:]]*(source|\.)[[:space:]]+(.+) ]]; then
    RAW_PATH="${BASH_REMATCH[2]}"

    # Strip inline comments
    RAW_PATH="${RAW_PATH%%#*}"
    RAW_PATH="${RAW_PATH%"${RAW_PATH##*[![:space:]]}"}"  # trim trailing space

    # Expand ~ to $HOME
    EXPANDED="${RAW_PATH/#\~/$HOME}"

    if [[ -f "$EXPANDED" ]]; then
      FILES_TO_COPY+=("$EXPANDED")
    else
      echo -e "  ${Y}⚠  Sourced file not found, skipping: ${RAW_PATH}${RESET}"
    fi
  fi
done < "$BASHRC"

# ── Always include .bashrc itself ─────────────────────────────────
FILES_TO_COPY+=("$BASHRC")

# ── Remove duplicates ─────────────────────────────────────────────
declare -a UNIQUE_FILES=()
declare -A SEEN=()
for F in "${FILES_TO_COPY[@]}"; do
  if [[ -z "${SEEN[$F]}" ]]; then
    SEEN[$F]=1
    UNIQUE_FILES+=("$F")
  fi
done

# ── Copy files ────────────────────────────────────────────────────
echo -e "  ${BOLD}${Y}Files to copy:${RESET}"
echo -e "  ${DIM}──────────────────────────────────────────────────────────${RESET}"

COPIED=0
FAILED=0

for FPATH in "${UNIQUE_FILES[@]}"; do
  FNAME=$(basename "$FPATH")
  FDEST="$DEST/$FNAME"

  if cp "$FPATH" "$FDEST" 2>/dev/null; then
    echo -e "  ${LG}✓${RESET}  ${W}${FNAME}${RESET}  ${DIM}← ${FPATH}${RESET}"
    ((COPIED++))
  else
    echo -e "  ${LR}✗${RESET}  ${W}${FNAME}${RESET}  ${DIM}← ${FPATH}${RESET}  ${LR}(copy failed)${RESET}"
    ((FAILED++))
  fi
done

echo ""
echo -e "  ${DIM}──────────────────────────────────────────────────────────${RESET}"
echo -e "  ${LG}✓ Copied: ${COPIED}${RESET}  ${LR}✗ Failed: ${FAILED}${RESET}"
echo ""
echo -e "  ${DIM}All files saved to: ${W}${DEST}${RESET}"
echo ""
}
