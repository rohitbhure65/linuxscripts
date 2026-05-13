#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# gitui — Interactive Git Terminal UI
#
# INSTALL:
#   cp .gitui.sh ~/.gitui.sh
#   echo 'source ~/.gitui.sh' >> ~/.bashrc
#   source ~/.bashrc
#
# USAGE:
#   gitui          → Full interactive TUI (graph + staging + commit)
#   gg             → Alias for gitui
#   glog           → Just show git graph
#   gstage         → Just open staging manager
#
# REQUIREMENTS:
#   git (obviously)
# ─────────────────────────────────────────────────────────────────

# =================================================================
# COLORS & SYMBOLS
# =================================================================

_gc() {
  R='\033[0;31m';   LR='\033[1;31m'
  G='\033[0;32m';   LG='\033[1;32m'
  Y='\033[1;33m';   LY='\033[0;33m'
  B='\033[0;34m';   LB='\033[1;34m'
  M='\033[0;35m';   LM='\033[1;35m'
  C='\033[0;36m';   LC='\033[1;36m'
  W='\033[1;37m';   DIM='\033[2m'
  BOLD='\033[1m';   RESET='\033[0m'
  ULINE='\033[4m';  BLINK='\033[5m'
  BG_D='\033[48;5;235m'   # Dark bg for highlights
  BG_G='\033[48;5;22m'    # Green bg (staged)
  BG_R='\033[48;5;52m'    # Red bg (unstaged)
}

# =================================================================
# GUARD: must be inside a git repo
# =================================================================

_check_git() {
  if ! git rev-parse --git-dir &>/dev/null 2>&1; then
    _gc
    echo -e "${LR}  ✗ Not inside a git repository.${RESET}"
    echo -e "${DIM}  Run this from inside a git project folder.${RESET}"
    return 1
  fi
  return 0
}

# =================================================================
# GIT GRAPH  — Vertical, colored, with branch labels + commit info
# =================================================================

_draw_graph() {
  _gc
  _check_git || return 1

  # ANSI COLORS (FIXED)
  local RESET=$'\033[0m'
  local BOLD=$'\033[1m'
  local DIM=$'\033[2m'

  local LC=$'\033[1;36m'
  local LM=$'\033[1;35m'
  local LY=$'\033[1;33m'
  local LG=$'\033[1;32m'
  local LR=$'\033[1;31m'
  local LB=$'\033[1;34m'

  local C=$'\033[0;36m'
  local M=$'\033[0;35m'
  local Y=$'\033[0;33m'
  local G=$'\033[0;32m'
  local W=$'\033[1;37m'

  local CURRENT_BRANCH
  CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD detached")

  local REPO_NAME
  REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")

  echo ""
  echo -e "${BOLD}${LC}╔══════════════════════════════════════════════════════════════╗${RESET}"

  local HEADER_TEXT="║   🌿 Git Graph — ${W}${REPO_NAME}${LC}"
  local PADDING=$((58 - ${#REPO_NAME}))
  [[ $PADDING -lt 0 ]] && PADDING=0

  printf "%b%*s║${RESET}\n" "$HEADER_TEXT" "$PADDING" ""

  echo -e "${BOLD}${LC}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "${DIM}Current branch:${RESET} ${LG}${BOLD}● ${CURRENT_BRANCH}${RESET}"
  echo ""

  echo -e "${BOLD}${DIM}── Git Log Graph ──────────────────────────────────────────────${RESET}"
  echo ""

  # Branch colors
  local COLORS=("$LC" "$LM" "$LY" "$LG" "$LR" "$LB" "$C" "$M" "$Y" "$G")
  local NCOLORS=${#COLORS[@]}

  # FIXED: use $'' quoting for \x1F
  local RAW_GRAPH
  RAW_GRAPH=$(git log \
    --graph \
    --pretty=format:$'COMMIT_START%h\x1F%D\x1F%s\x1F%an\x1F%cr' \
    --abbrev-commit \
    --all 2>/dev/null)

  if [[ -z "$RAW_GRAPH" ]]; then
    echo -e "${DIM}No commits yet.${RESET}"
    echo ""
    return 0
  fi

  local COL_IDX=0

  while IFS= read -r LINE; do

    if [[ "$LINE" == *"COMMIT_START"* ]]; then

      local GRAPH_PART="${LINE%%COMMIT_START*}"
      local DATA_PART="${LINE#*COMMIT_START}"

      local HASH
      local REFS
      local MSG
      local AUTHOR
      local WHEN

      HASH=$(echo "$DATA_PART" | cut -d$'\x1F' -f1)
      REFS=$(echo "$DATA_PART" | cut -d$'\x1F' -f2)
      MSG=$(echo "$DATA_PART" | cut -d$'\x1F' -f3)
      AUTHOR=$(echo "$DATA_PART" | cut -d$'\x1F' -f4)
      WHEN=$(echo "$DATA_PART" | cut -d$'\x1F' -f5)

      # Trim spaces
      HASH="$(echo "$HASH" | xargs)"
      REFS="$(echo "$REFS" | xargs)"
      MSG="$(echo "$MSG" | xargs)"
      AUTHOR="$(echo "$AUTHOR" | xargs)"
      WHEN="$(echo "$WHEN" | xargs)"

      # Short commit message
      local MSG_SHORT="$MSG"
      [[ ${#MSG_SHORT} -gt 45 ]] && MSG_SHORT="${MSG_SHORT:0:45}…"

      # Short author
      local AUTHOR_SHORT="${AUTHOR:0:12}"

      # Branch refs coloring
      local REFS_COLORED=""

      if [[ -n "$REFS" ]]; then

        local OLD_IFS="$IFS"
        IFS=',' read -ra REF_LIST <<< "$REFS"
        IFS="$OLD_IFS"

        for REF in "${REF_LIST[@]}"; do

          REF="$(echo "$REF" | xargs)"

          if [[ "$REF" == "HEAD -> "* ]]; then

            local BNAME="${REF#HEAD -> }"
            REFS_COLORED+="${BOLD}${LG}[HEAD→${BNAME}]${RESET} "

          elif [[ "$REF" == "tag: "* ]]; then

            REFS_COLORED+="${BOLD}${LY}[🏷 ${REF#tag: }]${RESET} "

          elif [[ "$REF" == origin/* ]]; then

            REFS_COLORED+="${DIM}${C}[${REF}]${RESET} "

          elif [[ -n "$REF" ]]; then

            REFS_COLORED+="${DIM}${LM}[${REF}]${RESET} "

          fi
        done
      fi

      # Graph color
      local GRAPH_COL="${COLORS[$((COL_IDX % NCOLORS))]}"
      local GRAPH_COLORED="$GRAPH_PART"

      GRAPH_COLORED="${GRAPH_COLORED//\*/${GRAPH_COL}◉${RESET}}"
      GRAPH_COLORED="${GRAPH_COLORED//|/${GRAPH_COL}│${RESET}}"
      GRAPH_COLORED="${GRAPH_COLORED//\\/${GRAPH_COL}╲${RESET}}"
      GRAPH_COLORED="${GRAPH_COLORED//\//${GRAPH_COL}╱${RESET}}"
      GRAPH_COLORED="${GRAPH_COLORED//-/${GRAPH_COL}─${RESET}}"

      COL_IDX=$((COL_IDX + 1))

      local IS_HEAD=""

      if [[ "$REFS" == *"HEAD -> "* ]]; then
        IS_HEAD=" ${LG}◀ YOU ARE HERE${RESET}"
      fi

      printf "%b  ${BOLD}${Y}%s${RESET}  %b${W}%s${RESET} ${DIM}%s • %s${RESET}%b\n" \
        "$GRAPH_COLORED" \
        "${HASH:0:7}" \
        "$REFS_COLORED" \
        "$MSG_SHORT" \
        "$AUTHOR_SHORT" \
        "$WHEN" \
        "$IS_HEAD"

    else

      if [[ -n "${LINE// }" ]]; then

        local GRAPH_COLORED="$LINE"

        GRAPH_COLORED="${GRAPH_COLORED//|/${LC}│${RESET}}"
        GRAPH_COLORED="${GRAPH_COLORED//\\/${LM}╲${RESET}}"
        GRAPH_COLORED="${GRAPH_COLORED//\//${LY}╱${RESET}}"
        GRAPH_COLORED="${GRAPH_COLORED//-/${LC}─${RESET}}"

        printf "%b\n" "$GRAPH_COLORED"
      fi
    fi

  done <<< "$RAW_GRAPH"

  echo ""
  echo -e "${DIM}Showing last commits across all branches.${RESET}"
  echo ""

  # Branch table
  echo -e "${BOLD}${DIM}── All Branches ───────────────────────────────────────────────${RESET}"
  echo ""

  printf "${BOLD}${W}%-3s %-28s %-10s %-22s %s${RESET}\n" \
    "" "BRANCH" "COMMIT" "LAST COMMIT" "LAST ACTIVE"

  echo -e "${DIM}───────────────────────────────────────────────────────────────${RESET}"

  while IFS= read -r BRANCH; do

    [[ -z "$BRANCH" ]] && continue
    [[ "$BRANCH" == "HEAD"* ]] && continue

    local IS_CUR=" "
    local COLOR="$DIM"

    if [[ "$BRANCH" == "$CURRENT_BRANCH" ]]; then
      IS_CUR="${LG}●${RESET}"
      COLOR="$LG"
    fi

    local BHASH
    local BMSG
    local BWHEN

    BHASH=$(git log -1 --pretty=format:'%h' "$BRANCH" 2>/dev/null)
    BMSG=$(git log -1 --pretty=format:'%s' "$BRANCH" 2>/dev/null)
    BWHEN=$(git log -1 --pretty=format:'%cr' "$BRANCH" 2>/dev/null)

    [[ -z "$BHASH" ]] && BHASH="???????"
    [[ -z "$BMSG" ]] && BMSG="No commits"
    [[ -z "$BWHEN" ]] && BWHEN="Unknown"

    [[ ${#BMSG} -gt 22 ]] && BMSG="${BMSG:0:22}…"

    local DISPLAY_BRANCH="${BRANCH#remotes/}"

    printf "%b ${COLOR}%-28s${RESET} ${Y}%-10s${RESET} ${DIM}%-22s %-10s${RESET}\n" \
      "$IS_CUR" \
      "${DISPLAY_BRANCH:0:28}" \
      "$BHASH" \
      "$BMSG" \
      "$BWHEN"

  done < <(git branch -a 2>/dev/null | sed 's/^[* ]*//' | sort -u)

  echo ""
}

# =================================================================
# STAGING MANAGER — Interactive file selection
# =================================================================

_staging_manager() {
  _gc
  _check_git || return 1

  local CURRENT_BRANCH
  CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD detached")

  while true; do
    clear
    echo ""
    echo -e "${BOLD}${LC}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${LC}  ║   📦  Staging Manager — branch: ${LG}${CURRENT_BRANCH}${LC}$(printf '%*s' $((29 - ${#CURRENT_BRANCH})) '')║${RESET}"
    echo -e "${BOLD}${LC}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Get all changed files with their status
    local STATUS_OUTPUT
    STATUS_OUTPUT=$(git status --porcelain 2>/dev/null)

    if [[ -z "$STATUS_OUTPUT" ]]; then
      echo -e "  ${LG}  ✓ Working tree is clean. Nothing to stage.${RESET}"
      echo ""
      return 0
    fi

    # Parse files into arrays
    local -a STAGED_FILES=()
    local -a STAGED_STATUS=()
    local -a UNSTAGED_FILES=()
    local -a UNSTAGED_STATUS=()
    local -a UNTRACKED_FILES=()

    while IFS= read -r LINE; do
      [[ -z "$LINE" ]] && continue
      local XY="${LINE:0:2}"
      local X="${LINE:0:1}"
      local Y="${LINE:1:1}"
      local FILE="${LINE:3}"

      # Handle renamed files (A -> B format in porcelain)
      if [[ "$FILE" == *" -> "* ]]; then
        FILE="${FILE##* -> }"
      fi

      # Staged changes (index)
      if [[ "$X" != " " && "$X" != "?" ]]; then
        STAGED_FILES+=("$FILE")
        case "$X" in
          A) STAGED_STATUS+=("ADDED")     ;;
          M) STAGED_STATUS+=("MODIFIED")  ;;
          D) STAGED_STATUS+=("DELETED")   ;;
          R) STAGED_STATUS+=("RENAMED")   ;;
          C) STAGED_STATUS+=("COPIED")    ;;
          *) STAGED_STATUS+=("$X")        ;;
        esac
      fi

      # Unstaged changes (worktree)
      if [[ "$Y" == "M" || "$Y" == "D" ]]; then
        UNSTAGED_FILES+=("$FILE")
        case "$Y" in
          M) UNSTAGED_STATUS+=("MODIFIED") ;;
          D) UNSTAGED_STATUS+=("DELETED")  ;;
          *) UNSTAGED_STATUS+=("$Y")       ;;
        esac
      fi

      # Untracked
      if [[ "$XY" == "??" ]]; then
        UNTRACKED_FILES+=("$FILE")
      fi

    done <<< "$STATUS_OUTPUT"

    # ── STAGED section ────────────────────────────────────────────
    echo -e "  ${BOLD}${LG}  ✅ STAGED  ${DIM}(will be included in next commit)${RESET}"
    echo -e "  ${DIM}  ──────────────────────────────────────────────────────────${RESET}"

    if [[ ${#STAGED_FILES[@]} -eq 0 ]]; then
      echo -e "  ${DIM}     (nothing staged)${RESET}"
    else
      for i in "${!STAGED_FILES[@]}"; do
        local IDX=$((i + 1))
        local STAT="${STAGED_STATUS[$i]}"
        local FILE="${STAGED_FILES[$i]}"
        local STAT_COL

        case "$STAT" in
          ADDED)    STAT_COL="${LG}" ;;
          MODIFIED) STAT_COL="${Y}"  ;;
          DELETED)  STAT_COL="${LR}" ;;
          RENAMED)  STAT_COL="${C}"  ;;
          *)        STAT_COL="${W}"  ;;
        esac

        printf "  ${LG}  [S%-2s]${RESET}  ${STAT_COL}%-10s${RESET}  %s\n" "$IDX" "$STAT" "$FILE"
      done
    fi

    echo ""

    # ── UNSTAGED section ──────────────────────────────────────────
    echo -e "  ${BOLD}${LR}  ⬜ UNSTAGED  ${DIM}(tracked files with changes, not staged)${RESET}"
    echo -e "  ${DIM}  ──────────────────────────────────────────────────────────${RESET}"

    if [[ ${#UNSTAGED_FILES[@]} -eq 0 ]]; then
      echo -e "  ${DIM}     (nothing unstaged)${RESET}"
    else
      for i in "${!UNSTAGED_FILES[@]}"; do
        local IDX=$((i + 1))
        local STAT="${UNSTAGED_STATUS[$i]}"
        local FILE="${UNSTAGED_FILES[$i]}"
        local STAT_COL

        case "$STAT" in
          MODIFIED) STAT_COL="${Y}"  ;;
          DELETED)  STAT_COL="${LR}" ;;
          *)        STAT_COL="${W}"  ;;
        esac

        printf "  ${LR}  [U%-2s]${RESET}  ${STAT_COL}%-10s${RESET}  %s\n" "$IDX" "$STAT" "$FILE"
      done
    fi

    echo ""

    # ── UNTRACKED section ─────────────────────────────────────────
    echo -e "  ${BOLD}${DIM}  ❓ UNTRACKED  ${DIM}(new files, not tracked by git)${RESET}"
    echo -e "  ${DIM}  ──────────────────────────────────────────────────────────${RESET}"

    if [[ ${#UNTRACKED_FILES[@]} -eq 0 ]]; then
      echo -e "  ${DIM}     (no untracked files)${RESET}"
    else
      for i in "${!UNTRACKED_FILES[@]}"; do
        local IDX=$((i + 1))
        printf "  ${DIM}  [N%-2s]  %-10s  %s${RESET}\n" "$IDX" "NEW" "${UNTRACKED_FILES[$i]}"
      done
    fi

    echo ""

    # ── Actions ───────────────────────────────────────────────────
    echo -e "  ${BOLD}${Y}  ━━ ACTIONS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${LG}  a)${RESET}  Stage a specific file     ${DIM}-- git add <file>${RESET}"
    echo -e "  ${LG}  A)${RESET}  Stage ALL changes         ${DIM}-- git add -A${RESET}"
    echo -e "  ${LR}  u)${RESET}  Unstage a specific file   ${DIM}-- git restore --staged <file>${RESET}"
    echo -e "  ${LR}  U)${RESET}  Unstage ALL               ${DIM}-- git restore --staged .${RESET}"
    echo -e "  ${C}   d)${RESET}  Diff a file               ${DIM}-- git diff <file>${RESET}"
    echo -e "  ${C}   D)${RESET}  Diff staged file          ${DIM}-- git diff --staged <file>${RESET}"
    echo -e "  ${LM}  c)${RESET}  ${BOLD}Commit staged files${RESET}       ${DIM}-- git commit -m \"...\"${RESET}"
    echo -e "  ${LM}  C)${RESET}  ${BOLD}Commit with editor${RESET}        ${DIM}-- git commit${RESET}"
    echo -e "  ${Y}   r)${RESET}  Refresh / reload view"
    echo -e "  ${R}   q)${RESET}  Back to main menu"
    echo ""
    read -rp "  Choose action: " ACTION
    echo ""

    case "$ACTION" in

      a)
        # Stage specific file — show numbered list
        echo -e "${Y}  Which file to stage?${RESET}"
        echo ""

        # Combine unstaged + untracked into one numbered list
        local -a ALL_STAGEABLE=()
        local -a ALL_STAGEABLE_STAT=()

        for f in "${UNSTAGED_FILES[@]}";  do ALL_STAGEABLE+=("$f"); ALL_STAGEABLE_STAT+=("MODIFIED/DELETED"); done
        for f in "${UNTRACKED_FILES[@]}"; do ALL_STAGEABLE+=("$f"); ALL_STAGEABLE_STAT+=("UNTRACKED"); done

        if [[ ${#ALL_STAGEABLE[@]} -eq 0 ]]; then
          echo -e "  ${DIM}Nothing to stage.${RESET}"
        else
          for i in "${!ALL_STAGEABLE[@]}"; do
            printf "  ${Y}  %2s)${RESET}  %s  ${DIM}(%s)${RESET}\n" "$((i+1))" "${ALL_STAGEABLE[$i]}" "${ALL_STAGEABLE_STAT[$i]}"
          done
          echo ""
          read -rp "  Enter number (or filename directly): " PICK
          if [[ "$PICK" =~ ^[0-9]+$ ]]; then
            local IDX=$((PICK - 1))
            if [[ $IDX -ge 0 && $IDX -lt ${#ALL_STAGEABLE[@]} ]]; then
              git add "${ALL_STAGEABLE[$IDX]}"
              echo -e "${LG}  ✓ Staged: ${ALL_STAGEABLE[$IDX]}${RESET}"
            else
              echo -e "${LR}  ✗ Invalid number.${RESET}"
            fi
          elif [[ -n "$PICK" ]]; then
            git add "$PICK"
            echo -e "${LG}  ✓ Staged: $PICK${RESET}"
          fi
        fi
        sleep 1
        ;;

      A)
        git add -A
        echo -e "${LG}  ✓ All changes staged.${RESET}"
        sleep 1
        ;;

      u)
        echo -e "${Y}  Which file to unstage?${RESET}"
        echo ""

        if [[ ${#STAGED_FILES[@]} -eq 0 ]]; then
          echo -e "  ${DIM}Nothing staged.${RESET}"
          sleep 1
        else
          for i in "${!STAGED_FILES[@]}"; do
            printf "  ${Y}  %2s)${RESET}  %s\n" "$((i+1))" "${STAGED_FILES[$i]}"
          done
          echo ""
          read -rp "  Enter number (or filename directly): " PICK
          if [[ "$PICK" =~ ^[0-9]+$ ]]; then
            local IDX=$((PICK - 1))
            if [[ $IDX -ge 0 && $IDX -lt ${#STAGED_FILES[@]} ]]; then
              git restore --staged "${STAGED_FILES[$IDX]}"
              echo -e "${LR}  ✓ Unstaged: ${STAGED_FILES[$IDX]}${RESET}"
            else
              echo -e "${LR}  ✗ Invalid number.${RESET}"
            fi
          elif [[ -n "$PICK" ]]; then
            git restore --staged "$PICK"
            echo -e "${LR}  ✓ Unstaged: $PICK${RESET}"
          fi
          sleep 1
        fi
        ;;

      U)
        git restore --staged . 2>/dev/null
        echo -e "${LR}  ✓ All files unstaged.${RESET}"
        sleep 1
        ;;

      d)
        echo -e "${Y}  Which file to diff (unstaged)?${RESET}"
        echo ""
        for i in "${!UNSTAGED_FILES[@]}"; do
          printf "  ${Y}  %2s)${RESET}  %s\n" "$((i+1))" "${UNSTAGED_FILES[$i]}"
        done
        echo ""
        read -rp "  Enter number or filename: " PICK
        local DFILE=""
        if [[ "$PICK" =~ ^[0-9]+$ ]]; then
          local IDX=$((PICK - 1))
          [[ $IDX -ge 0 && $IDX -lt ${#UNSTAGED_FILES[@]} ]] && DFILE="${UNSTAGED_FILES[$IDX]}"
        else
          DFILE="$PICK"
        fi
        if [[ -n "$DFILE" ]]; then
          echo ""
          git diff --color "$DFILE" 2>/dev/null | head -80
          echo ""
          read -rp "  Press Enter to continue..." _P
        fi
        ;;

      D)
        echo -e "${Y}  Which staged file to diff?${RESET}"
        echo ""
        for i in "${!STAGED_FILES[@]}"; do
          printf "  ${Y}  %2s)${RESET}  %s\n" "$((i+1))" "${STAGED_FILES[$i]}"
        done
        echo ""
        read -rp "  Enter number or filename: " PICK
        local DFILE=""
        if [[ "$PICK" =~ ^[0-9]+$ ]]; then
          local IDX=$((PICK - 1))
          [[ $IDX -ge 0 && $IDX -lt ${#STAGED_FILES[@]} ]] && DFILE="${STAGED_FILES[$IDX]}"
        else
          DFILE="$PICK"
        fi
        if [[ -n "$DFILE" ]]; then
          echo ""
          git diff --cached --color "$DFILE" 2>/dev/null | head -80
          echo ""
          read -rp "  Press Enter to continue..." _P
        fi
        ;;

      c)
        # Inline commit with message
        if [[ ${#STAGED_FILES[@]} -eq 0 ]]; then
          echo -e "${LR}  ✗ Nothing staged. Stage files first (option a or A).${RESET}"
          sleep 2
        else
          echo -e "${BOLD}${LM}  ── Commit ────────────────────────────────────────────${RESET}"
          echo ""
          echo -e "  ${DIM}Staged files:${RESET}"
          for f in "${STAGED_FILES[@]}"; do
            echo -e "    ${LG}✓ $f${RESET}"
          done
          echo ""

          # Suggest conventional commit types
          echo -e "  ${DIM}Commit type shortcuts (press Enter to skip):${RESET}"
          echo -e "  ${C}  feat${RESET}  fix  ${LR}hotfix${RESET}  ${Y}refactor${RESET}  docs  test  chore  style  perf"
          echo ""
          read -rp "  Type (optional): " CTYPE
          read -rp "  Commit message : " CMSG

          if [[ -z "$CMSG" ]]; then
            echo -e "${LR}  ✗ Commit message cannot be empty.${RESET}"
            sleep 2
          else
            local FULL_MSG="$CMSG"
            [[ -n "$CTYPE" ]] && FULL_MSG="${CTYPE}: ${CMSG}"

            echo ""
            echo -e "${DIM}  Running: git commit -m \"${FULL_MSG}\"${RESET}"
            echo ""
            git commit -m "$FULL_MSG"
            echo ""
            echo -e "${LG}  ✓ Committed!${RESET}"
            sleep 2
          fi
        fi
        ;;

      C)
        # Commit via editor (git's default editor)
        if [[ ${#STAGED_FILES[@]} -eq 0 ]]; then
          echo -e "${LR}  ✗ Nothing staged. Stage files first.${RESET}"
          sleep 2
        else
          git commit
        fi
        ;;

      r) continue ;;

      q|Q|"")
        return 0
        ;;

      *)
        echo -e "${LR}  ✗ Invalid option.${RESET}"
        sleep 1
        ;;
    esac

  done
}

# =================================================================
# BRANCH MANAGER
# =================================================================

_branch_manager() {
  _gc
  _check_git || return 1

  local CURRENT_BRANCH
  CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD detached")

  echo ""
  echo -e "${BOLD}${LC}  ── Branch Manager ─────────────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${DIM}Current: ${LG}${BOLD}${CURRENT_BRANCH}${RESET}"
  echo ""
  echo -e "  ${BOLD}${Y}  1)${RESET}  Switch to existing branch"
  echo -e "  ${BOLD}${LG}  2)${RESET}  Create new branch"
  echo -e "  ${BOLD}${LG}  3)${RESET}  Create + switch to new branch"
  echo -e "  ${BOLD}${LR}  4)${RESET}  Delete a branch"
  echo -e "  ${BOLD}${C}   5)${RESET}  Merge branch into current"
  echo -e "  ${BOLD}${M}   6)${RESET}  Push current branch to origin"
  echo -e "  ${BOLD}${M}   7)${RESET}  Pull current branch from origin"
  echo -e "  ${DIM}   0)${RESET}  Back"
  echo ""
  read -rp "  Choose [0-7]: " BOPT
  echo ""

  case "$BOPT" in
    1)
      echo -e "${Y}  Available branches:${RESET}"
      git branch -a
      echo ""
      read -rp "  Branch name to switch to: " BNAME
      [[ -z "$BNAME" ]] && return
      git checkout "$BNAME" && echo -e "${LG}  ✓ Switched to ${BNAME}.${RESET}"
      ;;
    2)
      read -rp "  New branch name: " BNAME
      [[ -z "$BNAME" ]] && return
      git branch "$BNAME" && echo -e "${LG}  ✓ Branch '${BNAME}' created (not switched).${RESET}"
      ;;
    3)
      read -rp "  New branch name: " BNAME
      [[ -z "$BNAME" ]] && return
      git checkout -b "$BNAME" && echo -e "${LG}  ✓ Created + switched to '${BNAME}'.${RESET}"
      ;;
    4)
      echo -e "${Y}  Local branches:${RESET}"
      git branch
      echo ""
      read -rp "  Branch to delete: " BNAME
      [[ -z "$BNAME" ]] && return
      echo -e "${LR}  ⚠  Delete branch '${BNAME}'? Type 'yes' to confirm:${RESET}"
      read -rp "  > " CONF
      [[ "$CONF" != "yes" ]] && echo -e "${DIM}  Aborted.${RESET}" && return
      git branch -d "$BNAME" || git branch -D "$BNAME"
      echo -e "${LG}  ✓ Branch '${BNAME}' deleted.${RESET}"
      ;;
    5)
      echo -e "${Y}  Available branches:${RESET}"
      git branch -a
      echo ""
      read -rp "  Branch to merge into ${CURRENT_BRANCH}: " BNAME
      [[ -z "$BNAME" ]] && return
      git merge "$BNAME" && echo -e "${LG}  ✓ Merged '${BNAME}' into '${CURRENT_BRANCH}'.${RESET}"
      ;;
    6)
      git push origin "$CURRENT_BRANCH" \
        && echo -e "${LG}  ✓ Pushed '${CURRENT_BRANCH}' to origin.${RESET}" \
        || echo -e "${LR}  ✗ Push failed. Maybe try: git push -u origin ${CURRENT_BRANCH}${RESET}"
      ;;
    7)
      git pull origin "$CURRENT_BRANCH" \
        && echo -e "${LG}  ✓ Pulled latest for '${CURRENT_BRANCH}'.${RESET}"
      ;;
    0|"") return ;;
    *) echo -e "${LR}  ✗ Invalid.${RESET}" ;;
  esac
}

# =================================================================
# STASH MANAGER
# =================================================================

_stash_manager() {
  _gc
  _check_git || return 1

  echo ""
  echo -e "${BOLD}${LC}  ── Stash Manager ───────────────────────────────────────────────${RESET}"
  echo ""

  local STASH_LIST
  STASH_LIST=$(git stash list 2>/dev/null)

  if [[ -z "$STASH_LIST" ]]; then
    echo -e "  ${DIM}  No stashes found.${RESET}"
  else
    echo -e "  ${Y}  Current stashes:${RESET}"
    while IFS= read -r SLINE; do
      echo -e "    ${C}${SLINE}${RESET}"
    done <<< "$STASH_LIST"
  fi

  echo ""
  echo -e "  ${LG}  1)${RESET}  Stash current changes      ${DIM}-- git stash push${RESET}"
  echo -e "  ${LG}  2)${RESET}  Stash with message         ${DIM}-- git stash push -m \"...\"${RESET}"
  echo -e "  ${LG}  3)${RESET}  Apply latest stash         ${DIM}-- git stash pop${RESET}"
  echo -e "  ${LG}  4)${RESET}  Apply specific stash       ${DIM}-- git stash apply stash@{N}${RESET}"
  echo -e "  ${LR}  5)${RESET}  Drop a stash               ${DIM}-- git stash drop stash@{N}${RESET}"
  echo -e "  ${LR}  6)${RESET}  Clear all stashes ⚠        ${DIM}-- git stash clear${RESET}"
  echo -e "  ${DIM}  0)${RESET}  Back"
  echo ""
  read -rp "  Choose [0-6]: " SOPT

  case "$SOPT" in
    1)
      git stash push && echo -e "${LG}  ✓ Changes stashed.${RESET}"
      ;;
    2)
      read -rp "  Stash message: " SMSG
      [[ -z "$SMSG" ]] && return
      git stash push -m "$SMSG" && echo -e "${LG}  ✓ Stashed: $SMSG${RESET}"
      ;;
    3)
      git stash pop && echo -e "${LG}  ✓ Latest stash applied & removed.${RESET}"
      ;;
    4)
      read -rp "  Stash index (e.g. 0 for stash@{0}): " SIDX
      git stash apply "stash@{$SIDX}" && echo -e "${LG}  ✓ Applied stash@{$SIDX}.${RESET}"
      ;;
    5)
      read -rp "  Stash index to drop: " SIDX
      git stash drop "stash@{$SIDX}" && echo -e "${LR}  ✓ Dropped stash@{$SIDX}.${RESET}"
      ;;
    6)
      echo -e "${LR}  ⚠  This deletes ALL stashes. Type 'yes' to confirm:${RESET}"
      read -rp "  > " CONF
      [[ "$CONF" != "yes" ]] && echo -e "${DIM}  Aborted.${RESET}" && return
      git stash clear && echo -e "${LR}  ✓ All stashes cleared.${RESET}"
      ;;
    0|"") return ;;
  esac
}

# =================================================================
# QUICK STATUS BAR
# =================================================================

_git_status_bar() {
  _gc
  _check_git || return

  local BRANCH
  BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")

  local STAGED UNSTAGED UNTRACKED
  STAGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  UNSTAGED=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  local AHEAD BEHIND
  AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
  BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

  echo -e "  ${DIM}Branch: ${LG}${BOLD}${BRANCH}${RESET}  ${DIM}│  ${LG}▲ Staged: ${STAGED}${RESET}  ${DIM}│  ${Y}≠ Unstaged: ${UNSTAGED}${RESET}  ${DIM}│  ${DIM}? Untracked: ${UNTRACKED}${RESET}  ${DIM}│  ↑${AHEAD} ↓${BEHIND}${RESET}"
}

# =================================================================
# MAIN MENU
# =================================================================

gitui() {
  _gc

  if ! _check_git; then
    return 1
  fi

  while true; do
    clear
    echo ""
    echo -e "${BOLD}${LC}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${LC}║   🌿  gitui — Git Interactive UI                             ║${RESET}"
    echo -e "${BOLD}${LC}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    _git_status_bar
    echo ""
    echo -e "${BOLD}${Y}  ━━ GRAPH & LOG ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${LG} 1)${RESET}  🌿  Git graph + branch overview"
    echo -e "  ${LG} 2)${RESET}  📋  Last commits (current branch)"
    echo -e "  ${LG} 3)${RESET}  🔍  Inspect a specific commit"
    echo ""
    echo -e "${BOLD}${Y}  ━━ STAGING & COMMIT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${LG} 4)${RESET}  📦  ${BOLD}Staging manager${RESET}  ${DIM}(stage / unstage / diff / commit)${RESET}"
    echo -e "  ${LG} 5)${RESET}  ⚡  Quick commit all staged"
    echo -e "  ${LG} 6)${RESET}  🔄  Amend last commit"
    echo ""
    echo -e "${BOLD}${Y}  ━━ BRANCHES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${LG} 7)${RESET}  🌿  Branch manager"
    echo -e "  ${LG} 8)${RESET}  📥  Pull latest (current branch)"
    echo -e "  ${LG} 9)${RESET}  📤  Push current branch"
    echo ""
    echo -e "${BOLD}${Y}  ━━ STASH ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${LG}10)${RESET}  📂  Stash manager"
    echo ""
    echo -e "${BOLD}${Y}  ━━ MISC ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${C} 11)${RESET}  🔎  Search commits by message"
    echo -e "  ${C} 12)${RESET}  👤  Show contributors"
    echo ""
    echo -e "  ${LR}  0)${RESET}  🚪  Exit"
    echo ""
    read -rp "  Choose option [0-12]: " CHOICE
    echo ""

    case "$CHOICE" in
      1)
        _draw_graph
        read -rp "  Press Enter to return..." _P
        ;;
      2)
     echo -e "${BOLD}${LC}──  Commits (Current Branch) ───────────────────────────${RESET}"
echo ""

git log \
  --pretty=format:$'COMMIT_START%h\x1F%cr\x1F%s\x1F%an' \
  --abbrev-commit 2>/dev/null | \
while IFS= read -r LINE; do

  [[ "$LINE" != *"COMMIT_START"* ]] && continue

  DATA="${LINE#*COMMIT_START}"

  HASH=$(echo "$DATA" | cut -d$'\x1F' -f1)
  WHEN=$(echo "$DATA" | cut -d$'\x1F' -f2)
  MSG=$(echo "$DATA" | cut -d$'\x1F' -f3)
  AUTHOR=$(echo "$DATA" | cut -d$'\x1F' -f4)

  HASH="$(echo "$HASH" | xargs)"
  WHEN="$(echo "$WHEN" | xargs)"
  MSG="$(echo "$MSG" | xargs)"
  AUTHOR="$(echo "$AUTHOR" | xargs)"

  # truncate long message
  MSG_SHORT="$MSG"
  [[ ${#MSG_SHORT} -gt 55 ]] && MSG_SHORT="${MSG_SHORT:0:55}…"

  printf "  ${LG}◉${RESET} ${BOLD}${Y}%-8s${RESET} ${DIM}%-12s${RESET} ${W}%-58s${RESET} ${DIM}<%s>${RESET}\n" \
    "$HASH" \
    "$WHEN" \
    "$MSG_SHORT" \
    "$AUTHOR"

done

echo ""
read -rp "Press Enter to return..." _P
;;
      3)
        read -rp "  Commit hash (or partial): " CHASH
        [[ -z "$CHASH" ]] && continue
        echo ""
        git show --stat --color "$CHASH" 2>/dev/null | head -60
        echo ""
        read -rp "  Press Enter to return..." _P
        ;;
      4)
        _staging_manager
        ;;
      5)
        _gc
        local STAGED
        STAGED=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$STAGED" -eq 0 ]]; then
          echo -e "${LR}  ✗ Nothing staged. Use option 4 (Staging manager) first.${RESET}"
        else
          read -rp "  Commit message: " CMSG
          [[ -z "$CMSG" ]] && echo -e "${LR}  ✗ Empty message.${RESET}" && sleep 1 && continue
          git commit -m "$CMSG" && echo -e "${LG}  ✓ Committed!${RESET}"
        fi
        sleep 1
        ;;
      6)
        echo -e "${Y}  Last commit:${RESET}"
        git log -1 --pretty=format:"  %h  %s  (%cr)" 2>/dev/null
        echo ""
        echo ""
        echo -e "  ${LR}  ⚠  Amending rewrites history. Only do this if not pushed yet.${RESET}"
        read -rp "  New commit message (Enter = keep old): " AMSG
        if [[ -z "$AMSG" ]]; then
          git commit --amend --no-edit && echo -e "${LG}  ✓ Amended (message kept).${RESET}"
        else
          git commit --amend -m "$AMSG" && echo -e "${LG}  ✓ Amended with new message.${RESET}"
        fi
        sleep 1
        ;;
      7)
        _branch_manager
        read -rp "  Press Enter to return..." _P
        ;;
      8)
        local CB
        CB=$(git symbolic-ref --short HEAD 2>/dev/null)
        echo -e "${Y}  Pulling ${CB} from origin...${RESET}"
        git pull origin "$CB"
        read -rp "  Press Enter to return..." _P
        ;;
      9)
        local CB
        CB=$(git symbolic-ref --short HEAD 2>/dev/null)
        echo -e "${Y}  Pushing ${CB} to origin...${RESET}"
        git push origin "$CB" || git push -u origin "$CB"
        read -rp "  Press Enter to return..." _P
        ;;
      10)
        _stash_manager
        read -rp "  Press Enter to return..." _P
        ;;
      11)
        read -rp "  Search keyword in commit messages: " KW
        [[ -z "$KW" ]] && continue
        echo ""
        git log --all --pretty=format:"  ${Y}%h${RESET}  ${DIM}%cr${RESET}  ${W}%s${RESET}  ${DIM}<%an>${RESET}" \
          --color --grep="$KW" 2>/dev/null
        echo ""
        echo ""
        read -rp "  Press Enter to return..." _P
        ;;
      12)
        echo ""
        echo -e "${BOLD}${LC}  ── Contributors ──${RESET}"
        echo ""
        git shortlog -sn --all 2>/dev/null | \
          while IFS= read -r LINE; do
            echo -e "  ${C}${LINE}${RESET}"
          done
        echo ""
        read -rp "  Press Enter to return..." _P
        ;;
      0)
        echo -e "${LC}  Goodbye! 🌿${RESET}"
        echo ""
        return 0
        ;;
      *)
        echo -e "${LR}  ✗ Invalid option.${RESET}"
        sleep 1
        ;;
    esac

  done
}

# =================================================================
# ALIASES
# =================================================================

alias gg='gitui'
alias glog='_check_git && _draw_graph'
alias gstage='_check_git && _staging_manager'
alias gst='git status'
alias gaa='git add -A'
