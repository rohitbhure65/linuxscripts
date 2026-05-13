#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# todo — Developer Todo CLI
#
# INSTALL:
#   cp .todo.sh ~/.todo.sh
#   echo 'source ~/.todo.sh' >> ~/.bashrc
#   source ~/.bashrc
#
# USAGE:
#   todo                  → Interactive TUI menu
#   todo add              → Quick add a task
#   todo ls               → List all pending tasks
#   todo done <id>        → Mark task done
#   todo help             → Show all commands
#
# STORAGE:
#   ~/.todo/todos.tsv     → Active tasks
#   ~/.todo/done.tsv      → Archived/completed tasks
#
# FORMAT (TSV columns):
#   ID | CREATED | DUE | PRIORITY | PROJECT | TAGS | TITLE
# ─────────────────────────────────────────────────────────────────

# =================================================================
# CONFIG & STORAGE SETUP
# =================================================================

TODO_DIR="$HOME/.todo"
TODO_FILE="$TODO_DIR/todos.tsv"
DONE_FILE="$TODO_DIR/done.tsv"

_todo_init() {
  mkdir -p "$TODO_DIR"
  [[ ! -f "$TODO_FILE" ]] && touch "$TODO_FILE"
  [[ ! -f "$DONE_FILE" ]] && touch "$DONE_FILE"
}

_todo_init


# =================================================================
# COLORS
# =================================================================

_todo_colors() {
  RED='\033[0;31m'
  LRED='\033[1;31m'
  GREEN='\033[0;32m'
  LGREEN='\033[1;32m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  LCYAN='\033[1;36m'
  MAGENTA='\033[0;35m'
  LMAGENTA='\033[1;35m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  DIM='\033[2m'
  WHITE='\033[1;37m'
  RESET='\033[0m'

  # Priority colors
  P_HIGH="${LRED}"
  P_MED="${YELLOW}"
  P_LOW="${GREEN}"
  P_NONE="${DIM}"
}


# =================================================================
# ID GENERATOR
# =================================================================

_next_id() {
  local MAX=0
  local ID
  while IFS=$'\t' read -r ID _REST; do
    [[ "$ID" =~ ^[0-9]+$ ]] && (( ID > MAX )) && MAX=$ID
  done < "$TODO_FILE"
  while IFS=$'\t' read -r ID _REST; do
    [[ "$ID" =~ ^[0-9]+$ ]] && (( ID > MAX )) && MAX=$ID
  done < "$DONE_FILE"
  echo $(( MAX + 1 ))
}


# =================================================================
# PRIORITY HELPERS
# =================================================================

_priority_label() {
  case "$1" in
    1) echo "HIGH" ;;
    2) echo "MED"  ;;
    3) echo "LOW"  ;;
    *) echo "-"    ;;
  esac
}

_priority_color() {
  _todo_colors
  case "$1" in
    1) echo "$P_HIGH"   ;;
    2) echo "$P_MED"    ;;
    3) echo "$P_LOW"    ;;
    *) echo "$P_NONE"   ;;
  esac
}

_priority_icon() {
  case "$1" in
    1) echo "🔴" ;;
    2) echo "🟡" ;;
    3) echo "🟢" ;;
    *) echo "⚪" ;;
  esac
}

_due_status() {
  local DUE="$1"
  [[ -z "$DUE" || "$DUE" == "-" ]] && echo "" && return

  local TODAY
  TODAY=$(date +%Y-%m-%d)
  local TOMORROW
  TOMORROW=$(date -d "tomorrow" +%Y-%m-%d 2>/dev/null || date -v+1d +%Y-%m-%d)

  if [[ "$DUE" < "$TODAY" ]]; then
    echo "OVERDUE"
  elif [[ "$DUE" == "$TODAY" ]]; then
    echo "TODAY"
  elif [[ "$DUE" == "$TOMORROW" ]]; then
    echo "TOMORROW"
  else
    echo "$DUE"
  fi
}

_due_color() {
  _todo_colors
  case "$1" in
    "OVERDUE")  echo "$LRED"    ;;
    "TODAY")    echo "$YELLOW"  ;;
    "TOMORROW") echo "$CYAN"    ;;
    "")         echo "$DIM"     ;;
    *)          echo "$DIM"     ;;
  esac
}


# =================================================================
# DISPLAY: Single task row
# =================================================================

_print_task_row() {
  # Args: ID CREATED DUE PRIORITY PROJECT TAGS TITLE
  local ID="$1" CREATED="$2" DUE="$3" PRI="$4" PROJECT="$5" TAGS="$6" TITLE="$7"
  _todo_colors

  local PCOL
  PCOL=$(_priority_color "$PRI")
  local PICON
  PICON=$(_priority_icon "$PRI")
  local PLABEL
  PLABEL=$(_priority_label "$PRI")

  local DUE_STATUS
  DUE_STATUS=$(_due_status "$DUE")
  local DCOL
  DCOL=$(_due_color "$DUE_STATUS")

  local DUE_DISPLAY="${DUE_STATUS:-  -  }"
  local PROJ_DISPLAY="${PROJECT:--}"
  local TAGS_DISPLAY="${TAGS:--}"

  printf "  ${DIM}%4s${RESET}  ${PCOL}%-4s${RESET}  ${DCOL}%-10s${RESET}  ${CYAN}%-12s${RESET}  ${MAGENTA}%-16s${RESET}  ${WHITE}%s${RESET}\n" \
    "#$ID" "$PLABEL" "$DUE_DISPLAY" "$PROJ_DISPLAY" "$TAGS_DISPLAY" "$TITLE"
}

_print_task_header() {
  _todo_colors
  echo ""
  printf "  ${BOLD}${DIM}%4s  %-4s  %-10s  %-12s  %-16s  %s${RESET}\n" \
    "ID" "PRI" "DUE" "PROJECT" "TAGS" "TITLE"
  echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────────${RESET}"
}


# =================================================================
# LIST TASKS
# =================================================================

_list_tasks() {
  local FILTER_PROJ="$1"
  local FILTER_TAG="$2"
  local FILTER_PRI="$3"

  _todo_colors

  local COUNT=0

  _print_task_header

  while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
    [[ -z "$ID" ]] && continue

    # Filters
    [[ -n "$FILTER_PROJ" && "$PROJECT" != "$FILTER_PROJ" ]] && continue
    [[ -n "$FILTER_TAG"  && "$TAGS" != *"$FILTER_TAG"*   ]] && continue
    [[ -n "$FILTER_PRI"  && "$PRI"  != "$FILTER_PRI"     ]] && continue

    _print_task_row "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE"
    ((COUNT++))
  done < "$TODO_FILE"

  echo ""
  if [[ $COUNT -eq 0 ]]; then
    echo -e "  ${DIM}No tasks found.${RESET}"
  else
    echo -e "  ${DIM}$COUNT task(s)${RESET}"
  fi
  echo ""
}


# =================================================================
# ADD TASK  (interactive)
# =================================================================

_add_task_interactive() {
  _todo_colors

  echo -e "${BOLD}${CYAN}  ── Add New Task ────────────────────────────────${RESET}"
  echo ""

  # Title
  read -rp "  📝 Title (required): " TITLE
  [[ -z "$TITLE" ]] && echo -e "${RED}  ✗ Title cannot be empty.${RESET}" && return 1

  # Priority
  echo ""
  echo -e "  🎯 Priority:"
  echo -e "     ${LRED}1)${RESET} HIGH   ${YELLOW}2)${RESET} MED   ${GREEN}3)${RESET} LOW   ${DIM}4)${RESET} None"
  read -rp "  Choose [1-4, default=4]: " PRI_INPUT
  case "$PRI_INPUT" in
    1) PRI=1 ;; 2) PRI=2 ;; 3) PRI=3 ;; *) PRI="-" ;;
  esac

  # Due date
  echo ""
  read -rp "  📅 Due date (YYYY-MM-DD, or blank): " DUE_INPUT
  if [[ -n "$DUE_INPUT" ]]; then
    # Validate format
    if ! date -d "$DUE_INPUT" &>/dev/null 2>&1; then
      echo -e "${YELLOW}  ⚠  Invalid date format. Skipping due date.${RESET}"
      DUE="-"
    else
      DUE="$DUE_INPUT"
    fi
  else
    DUE="-"
  fi

  # Project
  echo ""
  echo -e "  ${DIM}Existing projects:${RESET}"
  awk -F'\t' '{print $5}' "$TODO_FILE" | sort -u | grep -v "^-$" | grep -v "^$" | \
    while read -r P; do echo -e "     ${CYAN}$P${RESET}"; done
  read -rp "  📁 Project (or blank): " PROJECT_INPUT
  PROJECT="${PROJECT_INPUT:-"-"}"

  # Tags
  echo ""
  read -rp "  🏷  Tags (space-separated, e.g. bug feature, or blank): " TAGS_INPUT
  if [[ -n "$TAGS_INPUT" ]]; then
    # Normalize: prefix with # if not already
    TAGS=$(echo "$TAGS_INPUT" | tr ' ' '\n' | \
      awk '{if(substr($0,1,1)!="#") print "#"$0; else print $0}' | \
      tr '\n' ' ' | sed 's/ $//')
  else
    TAGS="-"
  fi

  # Save
  local ID
  ID=$(_next_id)
  local CREATED
  CREATED=$(date +%Y-%m-%d)

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE" >> "$TODO_FILE"

  echo ""
  echo -e "${GREEN}  ✓ Task #${ID} added: ${WHITE}${TITLE}${RESET}"
}


# =================================================================
# MARK DONE
# =================================================================

_mark_done() {
  _todo_colors

  _list_tasks
  read -rp "  Enter task ID to mark done (or blank to cancel): " DONE_ID
  [[ -z "$DONE_ID" ]] && echo -e "${DIM}  Cancelled.${RESET}" && return

  local FOUND=0
  local TEMP_FILE
  TEMP_FILE=$(mktemp)

  while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
    if [[ "$ID" == "$DONE_ID" ]]; then
      FOUND=1
      local COMPLETED
      COMPLETED=$(date +%Y-%m-%d)
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE" "$COMPLETED" >> "$DONE_FILE"
      echo -e "${GREEN}  ✓ Task #${ID} marked done: ${WHITE}${TITLE}${RESET}"
    else
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE" >> "$TEMP_FILE"
    fi
  done < "$TODO_FILE"

  mv "$TEMP_FILE" "$TODO_FILE"
  [[ $FOUND -eq 0 ]] && echo -e "${RED}  ✗ Task #${DONE_ID} not found.${RESET}"
}


# =================================================================
# EDIT TASK
# =================================================================

_edit_task() {
  _todo_colors

  _list_tasks
  read -rp "  Enter task ID to edit (or blank to cancel): " EDIT_ID
  [[ -z "$EDIT_ID" ]] && echo -e "${DIM}  Cancelled.${RESET}" && return

  local FOUND=0
  local OLD_TITLE OLD_DUE OLD_PRI OLD_PROJECT OLD_TAGS OLD_CREATED

  while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
    if [[ "$ID" == "$EDIT_ID" ]]; then
      FOUND=1
      OLD_TITLE="$TITLE"
      OLD_CREATED="$CREATED"
      OLD_DUE="$DUE"
      OLD_PRI="$PRI"
      OLD_PROJECT="$PROJECT"
      OLD_TAGS="$TAGS"
      break
    fi
  done < "$TODO_FILE"

  if [[ $FOUND -eq 0 ]]; then
    echo -e "${RED}  ✗ Task #${EDIT_ID} not found.${RESET}"
    return 1
  fi

  echo ""
  echo -e "${BOLD}${CYAN}  ── Edit Task #${EDIT_ID} ──────────────────────────────${RESET}"
  echo -e "  ${DIM}Press Enter to keep current value.${RESET}"
  echo ""

  read -rp "  📝 Title [${OLD_TITLE}]: " NEW_TITLE
  NEW_TITLE="${NEW_TITLE:-$OLD_TITLE}"

  echo -e "  🎯 Priority [current: $(_priority_label "$OLD_PRI")]:"
  echo -e "     ${LRED}1)${RESET} HIGH   ${YELLOW}2)${RESET} MED   ${GREEN}3)${RESET} LOW   ${DIM}4)${RESET} None   (Enter = keep)"
  read -rp "  Choose: " NEW_PRI_INPUT
  case "$NEW_PRI_INPUT" in
    1) NEW_PRI=1 ;; 2) NEW_PRI=2 ;; 3) NEW_PRI=3 ;; 4) NEW_PRI="-" ;;
    *) NEW_PRI="$OLD_PRI" ;;
  esac

  read -rp "  📅 Due date [${OLD_DUE}]: " NEW_DUE
  if [[ -n "$NEW_DUE" ]]; then
    if ! date -d "$NEW_DUE" &>/dev/null 2>&1; then
      echo -e "${YELLOW}  ⚠  Invalid date. Keeping old value.${RESET}"
      NEW_DUE="$OLD_DUE"
    fi
  else
    NEW_DUE="$OLD_DUE"
  fi

  read -rp "  📁 Project [${OLD_PROJECT}]: " NEW_PROJECT
  NEW_PROJECT="${NEW_PROJECT:-$OLD_PROJECT}"

  read -rp "  🏷  Tags [${OLD_TAGS}]: " NEW_TAGS_INPUT
  if [[ -n "$NEW_TAGS_INPUT" ]]; then
    NEW_TAGS=$(echo "$NEW_TAGS_INPUT" | tr ' ' '\n' | \
      awk '{if(substr($0,1,1)!="#") print "#"$0; else print $0}' | \
      tr '\n' ' ' | sed 's/ $//')
  else
    NEW_TAGS="$OLD_TAGS"
  fi

  # Rewrite file
  local TEMP_FILE
  TEMP_FILE=$(mktemp)
  while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
    if [[ "$ID" == "$EDIT_ID" ]]; then
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$ID" "$OLD_CREATED" "$NEW_DUE" "$NEW_PRI" "$NEW_PROJECT" "$NEW_TAGS" "$NEW_TITLE" >> "$TEMP_FILE"
    else
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE" >> "$TEMP_FILE"
    fi
  done < "$TODO_FILE"

  mv "$TEMP_FILE" "$TODO_FILE"
  echo -e "${GREEN}  ✓ Task #${EDIT_ID} updated.${RESET}"
}


# =================================================================
# DELETE TASK
# =================================================================

_delete_task() {
  _todo_colors

  _list_tasks
  read -rp "  Enter task ID to delete (or blank to cancel): " DEL_ID
  [[ -z "$DEL_ID" ]] && echo -e "${DIM}  Cancelled.${RESET}" && return

  echo -e "${RED}  ⚠  This will permanently delete task #${DEL_ID}. Type 'yes' to confirm:${RESET}"
  read -rp "  > " CONFIRM
  [[ "$CONFIRM" != "yes" ]] && echo -e "${DIM}  Aborted.${RESET}" && return

  local FOUND=0
  local TEMP_FILE
  TEMP_FILE=$(mktemp)

  while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
    if [[ "$ID" == "$DEL_ID" ]]; then
      FOUND=1
      echo -e "${GREEN}  ✓ Task #${ID} deleted: ${WHITE}${TITLE}${RESET}"
    else
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE" >> "$TEMP_FILE"
    fi
  done < "$TODO_FILE"

  mv "$TEMP_FILE" "$TODO_FILE"
  [[ $FOUND -eq 0 ]] && echo -e "${RED}  ✗ Task #${DEL_ID} not found.${RESET}"
}


# =================================================================
# VIEW DONE HISTORY
# =================================================================

_view_done() {
  _todo_colors

  local COUNT=0
  echo ""
  printf "  ${BOLD}${DIM}%4s  %-4s  %-10s  %-12s  %-16s  %-30s  %s${RESET}\n" \
    "ID" "PRI" "DUE" "PROJECT" "TAGS" "TITLE" "COMPLETED"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────────────────────────${RESET}"

  while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE COMPLETED; do
    [[ -z "$ID" ]] && continue
    local PCOL
    PCOL=$(_priority_color "$PRI")
    local PLABEL
    PLABEL=$(_priority_label "$PRI")
    printf "  ${DIM}%4s${RESET}  ${PCOL}%-4s${RESET}  ${DIM}%-10s  %-12s  %-16s${RESET}  ${DIM}%-30s${RESET}  ${GREEN}%s${RESET}\n" \
      "#$ID" "$PLABEL" "${DUE:--}" "${PROJECT:--}" "${TAGS:--}" "$TITLE" "${COMPLETED:--}"
    ((COUNT++))
  done < "$DONE_FILE"

  echo ""
  [[ $COUNT -eq 0 ]] && echo -e "  ${DIM}No completed tasks yet.${RESET}"
  echo -e "  ${DIM}$COUNT completed task(s)${RESET}"
  echo ""
}


# =================================================================
# FILTER / SEARCH
# =================================================================

_filter_menu() {
  _todo_colors

  echo ""
  echo -e "${BOLD}${CYAN}  ── Filter Tasks ────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${YELLOW}1)${RESET} By Project"
  echo -e "  ${YELLOW}2)${RESET} By Tag"
  echo -e "  ${YELLOW}3)${RESET} By Priority"
  echo -e "  ${YELLOW}4)${RESET} Overdue only"
  echo -e "  ${YELLOW}5)${RESET} Due today"
  echo -e "  ${YELLOW}6)${RESET} Search by keyword"
  echo ""
  read -rp "  Choose [1-6]: " FOPT

  case "$FOPT" in
    1)
      echo ""
      echo -e "  ${DIM}Available projects:${RESET}"
      awk -F'\t' '{print $5}' "$TODO_FILE" | sort -u | grep -v "^-$" | grep -v "^$" | \
        while read -r P; do echo -e "     ${CYAN}$P${RESET}"; done
      echo ""
      read -rp "  Project name: " FP
      _list_tasks "$FP" "" ""
      ;;
    2)
      read -rp "  Tag (e.g. bug or #bug): " FT
      FT="${FT/#\#/}"
      _list_tasks "" "#$FT" ""
      ;;
    3)
      echo -e "  ${LRED}1)${RESET} HIGH  ${YELLOW}2)${RESET} MED  ${GREEN}3)${RESET} LOW"
      read -rp "  Priority [1-3]: " FPR
      _list_tasks "" "" "$FPR"
      ;;
    4)
      _todo_colors
      local TODAY
      TODAY=$(date +%Y-%m-%d)
      local COUNT=0
      _print_task_header
      while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
        [[ -z "$ID" || -z "$DUE" || "$DUE" == "-" ]] && continue
        [[ "$DUE" < "$TODAY" ]] && _print_task_row "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE" && ((COUNT++))
      done < "$TODO_FILE"
      echo ""
      echo -e "  ${DIM}$COUNT overdue task(s)${RESET}"
      echo ""
      ;;
    5)
      local TODAY
      TODAY=$(date +%Y-%m-%d)
      local COUNT=0
      _print_task_header
      while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
        [[ -z "$ID" || "$DUE" != "$TODAY" ]] && continue
        _print_task_row "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE" && ((COUNT++))
      done < "$TODO_FILE"
      echo ""
      echo -e "  ${DIM}$COUNT task(s) due today${RESET}"
      echo ""
      ;;
    6)
      read -rp "  Search keyword: " KW
      [[ -z "$KW" ]] && return
      local COUNT=0
      _print_task_header
      while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
        [[ -z "$ID" ]] && continue
        if [[ "$TITLE" == *"$KW"* || "$TAGS" == *"$KW"* || "$PROJECT" == *"$KW"* ]]; then
          _print_task_row "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE"
          ((COUNT++))
        fi
      done < "$TODO_FILE"
      echo ""
      echo -e "  ${DIM}$COUNT result(s) for '${KW}'${RESET}"
      echo ""
      ;;
    *) echo -e "${RED}  ✗ Invalid option.${RESET}" ;;
  esac
}


# =================================================================
# STATS / SUMMARY
# =================================================================

_show_stats() {
  _todo_colors

  local TOTAL=0 HIGH=0 MED=0 LOW=0 NONE_PRI=0
  local OVERDUE=0 DUE_TODAY=0
  local TODAY
  TODAY=$(date +%Y-%m-%d)
  local DONE_COUNT=0

  while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
    [[ -z "$ID" ]] && continue
    ((TOTAL++))
    case "$PRI" in
      1) ((HIGH++))  ;;
      2) ((MED++))   ;;
      3) ((LOW++))   ;;
      *) ((NONE_PRI++)) ;;
    esac
    [[ -n "$DUE" && "$DUE" != "-" && "$DUE" < "$TODAY" ]] && ((OVERDUE++))
    [[ "$DUE" == "$TODAY" ]] && ((DUE_TODAY++))
  done < "$TODO_FILE"

  DONE_COUNT=$(grep -c . "$DONE_FILE" 2>/dev/null || echo 0)

  echo ""
  echo -e "${BOLD}${CYAN}  ── Task Summary ────────────────────────────────${RESET}"
  echo ""
  printf "  ${WHITE}%-20s${RESET} ${BOLD}%s${RESET}\n"   "Total pending:"   "$TOTAL"
  printf "  ${WHITE}%-20s${RESET} ${GREEN}%s${RESET}\n"  "Completed:"       "$DONE_COUNT"
  echo ""
  printf "  ${LRED}%-20s${RESET} %s\n"    "🔴 HIGH priority:"  "$HIGH"
  printf "  ${YELLOW}%-20s${RESET} %s\n"  "🟡 MED priority:"   "$MED"
  printf "  ${GREEN}%-20s${RESET} %s\n"   "🟢 LOW priority:"   "$LOW"
  printf "  ${DIM}%-20s${RESET} %s\n"     "⚪ No priority:"    "$NONE_PRI"
  echo ""
  printf "  ${LRED}%-20s${RESET} %s\n"    "⚠  Overdue:"       "$OVERDUE"
  printf "  ${YELLOW}%-20s${RESET} %s\n"  "📅 Due today:"      "$DUE_TODAY"
  echo ""

  # Projects breakdown
  echo -e "  ${BOLD}Projects:${RESET}"
  awk -F'\t' '{print $5}' "$TODO_FILE" | sort | uniq -c | sort -rn | \
    while read -r CNT PROJ; do
      [[ "$PROJ" == "-" || -z "$PROJ" ]] && continue
      printf "    ${CYAN}%-18s${RESET} ${DIM}%s task(s)${RESET}\n" "$PROJ" "$CNT"
    done

  echo ""
  # Tags breakdown
  echo -e "  ${BOLD}Tags:${RESET}"
  awk -F'\t' '{print $6}' "$TODO_FILE" | tr ' ' '\n' | sort | uniq -c | sort -rn | \
    while read -r CNT TAG; do
      [[ "$TAG" == "-" || -z "$TAG" ]] && continue
      printf "    ${MAGENTA}%-18s${RESET} ${DIM}%s task(s)${RESET}\n" "$TAG" "$CNT"
    done
  echo ""
}


# =================================================================
# CLEAR DONE ARCHIVE
# =================================================================

_clear_archive() {
  _todo_colors
  local COUNT
  COUNT=$(grep -c . "$DONE_FILE" 2>/dev/null || echo 0)
  echo -e "${RED}  ⚠  This will permanently delete all ${COUNT} completed tasks. Type 'yes' to confirm:${RESET}"
  read -rp "  > " CONFIRM
  if [[ "$CONFIRM" == "yes" ]]; then
    > "$DONE_FILE"
    echo -e "${GREEN}  ✓ Archive cleared.${RESET}"
  else
    echo -e "${DIM}  Aborted.${RESET}"
  fi
}


# =================================================================
# QUICK STATUS BAR  (shown at menu top)
# =================================================================

_quick_status() {
  _todo_colors

  local TOTAL=0 OVERDUE=0 DUE_TODAY=0 HIGH=0
  local TODAY
  TODAY=$(date +%Y-%m-%d)

  while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
    [[ -z "$ID" ]] && continue
    ((TOTAL++))
    [[ "$PRI" == "1" ]] && ((HIGH++))
    [[ -n "$DUE" && "$DUE" != "-" && "$DUE" < "$TODAY" ]] && ((OVERDUE++))
    [[ "$DUE" == "$TODAY" ]] && ((DUE_TODAY++))
  done < "$TODO_FILE"

  echo -e "  ${DIM}Pending: ${WHITE}${TOTAL}${RESET}  ${DIM}|  🔴 High: ${LRED}${HIGH}${RESET}  ${DIM}|  ⚠  Overdue: ${LRED}${OVERDUE}${RESET}  ${DIM}|  📅 Today: ${YELLOW}${DUE_TODAY}${RESET}"
}


# =================================================================
# MAIN TUI MENU
# =================================================================

todo() {
  _todo_colors
  _todo_init

  # Handle quick CLI commands (non-interactive)
  case "$1" in
    add)   _add_task_interactive; return ;;
    ls)    _list_tasks;           return ;;
    done)  _mark_done;            return ;;
    stats) _show_stats;           return ;;
    help)  _todo_help;            return ;;
  esac

  while true; do
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║              ✅  todo — Developer Task Manager               ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    _quick_status
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ TASKS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN} 1)${RESET} 📋  List all pending tasks"
    echo -e "  ${GREEN} 2)${RESET} ➕  Add new task"
    echo -e "  ${GREEN} 3)${RESET} ✅  Mark task as done"
    echo -e "  ${GREEN} 4)${RESET} ✏️   Edit task"
    echo -e "  ${RED}  5)${RESET} 🗑   Delete task"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ FILTER & SEARCH ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN} 6)${RESET} 🔍  Filter / Search tasks"
    echo -e "  ${LRED} 7)${RESET} ⚠️   Show overdue tasks"
    echo -e "  ${YELLOW} 8)${RESET} 📅  Show tasks due today"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ HISTORY & STATS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN} 9)${RESET} 📜  View completed tasks (archive)"
    echo -e "  ${GREEN}10)${RESET} 📊  Stats & summary"
    echo -e "  ${RED} 11)${RESET} 🧹  Clear completed archive ⚠"
    echo ""
    echo -e "  ${RED}  0)${RESET} 🚪  Exit"
    echo ""
    read -rp "  Choose option [0-11]: " CHOICE
    echo ""

    case "$CHOICE" in
      1)  _list_tasks ;;
      2)  _add_task_interactive ;;
      3)  _mark_done ;;
      4)  _edit_task ;;
      5)  _delete_task ;;
      6)  _filter_menu ;;
      7)
        _todo_colors
        local TODAY
        TODAY=$(date +%Y-%m-%d)
        local COUNT=0
        echo -e "${BOLD}${LRED}  ⚠  Overdue Tasks:${RESET}"
        _print_task_header
        while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
          [[ -z "$ID" || -z "$DUE" || "$DUE" == "-" ]] && continue
          [[ "$DUE" < "$TODAY" ]] && _print_task_row "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE" && ((COUNT++))
        done < "$TODO_FILE"
        echo ""
        echo -e "  ${DIM}$COUNT overdue task(s)${RESET}"
        echo ""
        ;;
      8)
        _todo_colors
        local TODAY
        TODAY=$(date +%Y-%m-%d)
        local COUNT=0
        echo -e "${BOLD}${YELLOW}  📅 Tasks Due Today:${RESET}"
        _print_task_header
        while IFS=$'\t' read -r ID CREATED DUE PRI PROJECT TAGS TITLE; do
          [[ -z "$ID" || "$DUE" != "$TODAY" ]] && continue
          _print_task_row "$ID" "$CREATED" "$DUE" "$PRI" "$PROJECT" "$TAGS" "$TITLE" && ((COUNT++))
        done < "$TODO_FILE"
        echo ""
        echo -e "  ${DIM}$COUNT task(s) due today${RESET}"
        echo ""
        ;;
      9)  _view_done ;;
      10) _show_stats ;;
      11) _clear_archive ;;
      0)
        echo -e "${CYAN}  See you! ✅${RESET}"
        echo ""
        return 0
        ;;
      *) echo -e "${RED}  ✗ Invalid option. Choose 0-11.${RESET}" ;;
    esac

    echo ""
    read -rp "  Press Enter to return to menu..." _PAUSE
  done
}


# =================================================================
# QUICK CLI ALIASES
# =================================================================

alias t='todo'
alias tls='todo ls'
alias tadd='todo add'
alias tdone='todo done'
alias tstats='todo stats'


# =================================================================
# HELP
# =================================================================

_todo_help() {
  _todo_colors
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║              ✅  todo — Quick Reference                      ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  printf "  ${BOLD}${WHITE}%-20s %s${RESET}\n" "COMMAND" "WHAT IT DOES"
  echo -e "  ${DIM}──────────────────────────────────────────────${RESET}"
  printf "  ${CYAN}%-20s${RESET} %s\n" "todo"        "Launch interactive TUI menu"
  printf "  ${CYAN}%-20s${RESET} %s\n" "todo add"    "Quick add a new task"
  printf "  ${CYAN}%-20s${RESET} %s\n" "todo ls"     "List all pending tasks"
  printf "  ${CYAN}%-20s${RESET} %s\n" "todo done"   "Mark a task done (asks for ID)"
  printf "  ${CYAN}%-20s${RESET} %s\n" "todo stats"  "Show summary & stats"
  printf "  ${CYAN}%-20s${RESET} %s\n" "todo help"   "Show this help"
  echo ""
  printf "  ${BOLD}${WHITE}%-20s %s${RESET}\n" "ALIAS" "SHORTCUT FOR"
  echo -e "  ${DIM}──────────────────────────────────────────────${RESET}"
  printf "  ${GREEN}%-20s${RESET} %s\n" "t"       "todo (full menu)"
  printf "  ${GREEN}%-20s${RESET} %s\n" "tls"     "todo ls"
  printf "  ${GREEN}%-20s${RESET} %s\n" "tadd"    "todo add"
  printf "  ${GREEN}%-20s${RESET} %s\n" "tdone"   "todo done"
  printf "  ${GREEN}%-20s${RESET} %s\n" "tstats"  "todo stats"
  echo ""
  echo -e "  ${BOLD}Storage:${RESET}  ${DIM}~/.todo/todos.tsv  (active)${RESET}"
  echo -e "            ${DIM}~/.todo/done.tsv   (archive)${RESET}"
  echo ""
}
