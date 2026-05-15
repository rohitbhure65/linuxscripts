#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# pgtools — Full PostgreSQL Interactive Toolkit
#
# INSTALL:
#   cp .pgtools.sh ~/.pgtools.sh
#   echo 'source ~/.pgtools.sh' >> ~/.bashrc
#   source ~/.bashrc
#
# USAGE:
#   pgtools   → Auto-starts PostgreSQL, opens menu, stops on exit
#
# BEHAVIOR:
#   • PostgreSQL auto-starts when you run `pgtools`
#   • PostgreSQL auto-stops + disables when you exit via option 0
#   • If terminal is force-closed, EXIT trap also stops PostgreSQL
# ─────────────────────────────────────────────────────────────────


# =================================================================
# INTERNAL: PostgreSQL lifecycle helpers
# =================================================================

_pg_start() {
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local CYAN='\033[0;36m'
  local DIM='\033[2m'
  local RESET='\033[0m'

  # Already running? Skip.
  if pg_isready -q 2>/dev/null; then
    echo -e "${GREEN}  ✓ PostgreSQL is already running.${RESET}"
    return 0
  fi

  echo -e "${CYAN}  🐘 Starting PostgreSQL service...${RESET}"
  sudo systemctl enable postgresql 2>/dev/null
  sudo systemctl start  postgresql 2>/dev/null

  echo -e "${DIM}  Waiting for PostgreSQL to be ready...${RESET}"
  local TRIES=0
  until pg_isready -q 2>/dev/null; do
    if [[ $TRIES -ge 15 ]]; then
      echo -e "${RED}  ✗ PostgreSQL did not become ready after 30 seconds.${RESET}"
      echo -e "${RED}    Please start it manually: sudo systemctl start postgresql${RESET}"
      return 1
    fi
    printf "${DIM}.${RESET}"
    sleep 2
    ((TRIES++))
  done
  echo ""
  echo -e "${GREEN}  ✓ PostgreSQL is ready.${RESET}"
  return 0
}

_pg_stop() {
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local RESET='\033[0m'

  echo ""
  echo -e "${YELLOW}  🐘 Stopping PostgreSQL service...${RESET}"
  sudo systemctl stop    postgresql 2>/dev/null
  sudo systemctl disable postgresql 2>/dev/null
  echo -e "${GREEN}  ✓ PostgreSQL stopped & disabled.${RESET}"
}


# =================================================================
# pgtools — Interactive Menu
# =================================================================
pgtools() {

  # ── Colors ──────────────────────────────────────────────────────
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local MAGENTA='\033[0;35m'
  local BLUE='\033[0;34m'
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local RESET='\033[0m'

  # ── Auto-start PostgreSQL ────────────────────────────────────────
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║          🐘  pgtools — PostgreSQL Toolkit                ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  _pg_start || return 1

  # ── EXIT trap: stop PostgreSQL if terminal is force-closed ───────
  # (clean exit via option 0 also calls _pg_stop explicitly)
  trap '_pg_stop' EXIT

  # ── One-time login ───────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}${CYAN}── Login ─────────────────────────────────────────────────${RESET}"
  read -rp "  PostgreSQL username [postgres]: " PG_USER
  PG_USER="${PG_USER:-postgres}"
  read -rsp "  Password (hidden): " PG_PASS; echo ""
  echo ""

  # Verify credentials
  local _test
  _test=$(PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -c "SELECT 1;" 2>&1)
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}  ✗ Login failed. Check username/password.${RESET}"
    echo -e "${DIM}  ${_test}${RESET}"
    trap - EXIT
    _pg_stop
    return 1
  fi
  echo -e "${GREEN}  ✓ Connected as '${BOLD}${PG_USER}${RESET}${GREEN}'${RESET}"
  echo ""

  # ── Helpers: use stored credentials everywhere ───────────────────
  _pg_run() {
    PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -c "$1" 2>&1
  }

  _pg_run_db() {
    local db="$1"; shift
    PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -d "$db" -c "$1" 2>&1
  }

  _pg_run_db_user() {
    local db="$1"; local user="$2"; shift 2
    PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -d "$db" -U "$user" -c "$1" 2>&1
  }

  # ════════════════════════════════════════════════════════════════
  # SMART PICKERS — Auto-fetch + Numbered Selection
  # ════════════════════════════════════════════════════════════════

  _pick_database() {
    echo -e "${BOLD}${CYAN}  📦 Fetching databases...${RESET}"
    local raw
    raw=$(PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -Atc \
      "SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname;" 2>&1)

    if [[ $? -ne 0 || -z "$raw" ]]; then
      echo -e "${RED}  ✗ Could not fetch databases.${RESET}"
      return 1
    fi

    local dbs=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && dbs+=("$line")
    done <<< "$raw"

    if [[ ${#dbs[@]} -eq 0 ]]; then
      echo -e "${RED}  ✗ No databases found.${RESET}"
      return 1
    fi

    echo ""
    echo -e "${BOLD}${YELLOW}  Select Database:${RESET}"
    local i=1
    for db in "${dbs[@]}"; do
      echo -e "  ${GREEN}${i})${RESET} ${db}"
      ((i++))
    done
    echo ""
    read -rp "  Choose [1-${#dbs[@]}]: " DB_CHOICE

    if ! [[ "$DB_CHOICE" =~ ^[0-9]+$ ]] || \
       [[ "$DB_CHOICE" -lt 1 || "$DB_CHOICE" -gt ${#dbs[@]} ]]; then
      echo -e "${RED}  ✗ Invalid choice.${RESET}"
      return 1
    fi

    SEL_DB="${dbs[$((DB_CHOICE - 1))]}"
    echo -e "  ${GREEN}✓ Selected: ${BOLD}${SEL_DB}${RESET}"
    echo ""
  }

  _pick_table() {
    if [[ -z "$SEL_DB" ]]; then
      echo -e "${RED}  ✗ No database selected.${RESET}"
      return 1
    fi

    echo -e "${BOLD}${CYAN}  📋 Fetching tables in '${SEL_DB}'...${RESET}"
    local raw
    raw=$(PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -d "$SEL_DB" -Atc \
      "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;" 2>&1)

    if [[ $? -ne 0 || -z "$raw" ]]; then
      echo -e "${RED}  ✗ Could not fetch tables (or database '${SEL_DB}' has no public tables).${RESET}"
      return 1
    fi

    local tbls=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && tbls+=("$line")
    done <<< "$raw"

    if [[ ${#tbls[@]} -eq 0 ]]; then
      echo -e "${RED}  ✗ No tables found in '${SEL_DB}'.${RESET}"
      return 1
    fi

    echo ""
    echo -e "${BOLD}${YELLOW}  Select Table:${RESET}"
    local i=1
    for tbl in "${tbls[@]}"; do
      echo -e "  ${GREEN}${i})${RESET} ${tbl}"
      ((i++))
    done
    echo ""
    read -rp "  Choose [1-${#tbls[@]}]: " TBL_CHOICE

    if ! [[ "$TBL_CHOICE" =~ ^[0-9]+$ ]] || \
       [[ "$TBL_CHOICE" -lt 1 || "$TBL_CHOICE" -gt ${#tbls[@]} ]]; then
      echo -e "${RED}  ✗ Invalid choice.${RESET}"
      return 1
    fi

    SEL_TABLE="${tbls[$((TBL_CHOICE - 1))]}"
    echo -e "  ${GREEN}✓ Selected: ${BOLD}${SEL_TABLE}${RESET}"
    echo ""
  }

  _pick_user() {
    echo -e "${BOLD}${CYAN}  👥 Fetching roles/users...${RESET}"
    local raw
    raw=$(PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -Atc \
      "SELECT rolname FROM pg_roles WHERE rolcanlogin = true ORDER BY rolname;" 2>&1)

    if [[ $? -ne 0 || -z "$raw" ]]; then
      echo -e "${RED}  ✗ Could not fetch users.${RESET}"
      return 1
    fi

    local users=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && users+=("$line")
    done <<< "$raw"

    if [[ ${#users[@]} -eq 0 ]]; then
      echo -e "${RED}  ✗ No login-capable roles found.${RESET}"
      return 1
    fi

    echo ""
    echo -e "${BOLD}${YELLOW}  Select User/Role:${RESET}"
    local i=1
    for usr in "${users[@]}"; do
      echo -e "  ${GREEN}${i})${RESET} ${usr}"
      ((i++))
    done
    echo ""
    read -rp "  Choose [1-${#users[@]}]: " USR_CHOICE

    if ! [[ "$USR_CHOICE" =~ ^[0-9]+$ ]] || \
       [[ "$USR_CHOICE" -lt 1 || "$USR_CHOICE" -gt ${#users[@]} ]]; then
      echo -e "${RED}  ✗ Invalid choice.${RESET}"
      return 1
    fi

    SEL_USER="${users[$((USR_CHOICE - 1))]}"
    echo -e "  ${GREEN}✓ Selected: ${BOLD}${SEL_USER}${RESET}"
    echo ""
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION A: DATABASE SETUP
  # ════════════════════════════════════════════════════════════════
  _pgsetup() {
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║     🐘 PostgreSQL Interactive Setup Tool     ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${BOLD}${CYAN}── Step 1: Database Role (Username) ──────────────────${RESET}"
    echo -e "${YELLOW}  Role/username to create?${RESET} (e.g. myapp_user, devuser)"
    read -rp "  > " DB_USER
    [[ -z "$DB_USER" ]] && echo -e "${RED}  ✗ Empty. Aborted.${RESET}" && return 1

    echo ""
    echo -e "${BOLD}${CYAN}── Step 2: Password ──────────────────────────────────${RESET}"
    read -rsp "  Password (hidden): " DB_PASS; echo ""
    read -rsp "  Confirm password : " DB_PASS2; echo ""
    [[ "$DB_PASS" != "$DB_PASS2" ]] && echo -e "${RED}  ✗ Passwords don't match.${RESET}" && return 1
    [[ -z "$DB_PASS" ]] && echo -e "${RED}  ✗ Empty password.${RESET}" && return 1

    echo ""
    echo -e "${BOLD}${CYAN}── Step 3: Database Name ─────────────────────────────${RESET}"
    echo -e "${YELLOW}  Database name?${RESET} (e.g. myapp_db)"
    read -rp "  > " DB_NAME
    [[ -z "$DB_NAME" ]] && echo -e "${RED}  ✗ Empty. Aborted.${RESET}" && return 1

    echo ""
    echo -e "${BOLD}${CYAN}── Step 4: Role Type ─────────────────────────────────${RESET}"
    read -rp "  Make SUPERUSER? [y/n] (default: y): " IS_SUPER
    IS_SUPER="${IS_SUPER:-y}"
    [[ "$IS_SUPER" == "y" || "$IS_SUPER" == "Y" ]] && ROLE_TYPE="SUPERUSER" || ROLE_TYPE=""

    echo ""
    echo -e "  Role     : ${GREEN}${DB_USER}${RESET}"
    echo -e "  Database : ${GREEN}${DB_NAME}${RESET}"
    echo -e "  Type     : ${GREEN}${ROLE_TYPE:-NORMAL USER}${RESET}"
    read -rp "  Proceed? [y/n]: " CONFIRM
    [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1

    echo "$DB_PASS" | PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -c "CREATE ROLE ${DB_USER} WITH LOGIN ${ROLE_TYPE} PASSWORD '${DB_PASS}';" 2>&1
    PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -c "CREATE DATABASE ${DB_NAME};" 2>&1
    PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -c "ALTER DATABASE ${DB_NAME} OWNER TO ${DB_USER};" 2>&1
    PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" 2>&1
    PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -d "$DB_NAME" -c "
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DB_USER};
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};
      GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO ${DB_USER};
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${DB_USER};
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ${DB_USER};
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON FUNCTIONS TO ${DB_USER};
    " 2>&1

    echo ""
    echo -e "${BOLD}${GREEN}✅  Setup complete!${RESET}"
    echo -e "  ${GREEN}psql -U ${DB_USER} -d ${DB_NAME} -h localhost${RESET}"
    echo -e "  ${GREEN}DATABASE_URL=\"postgresql://${DB_USER}:[password]@localhost:5432/${DB_NAME}\"${RESET}"
    echo ""
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION B: DATABASE OPERATIONS
  # ════════════════════════════════════════════════════════════════

  _list_databases() {
    echo ""
    echo -e "${BOLD}${CYAN}📦 All Databases:${RESET}"
    _pg_run "\l+"
  }

  _create_database() {
    echo -e "${YELLOW}  New database name:${RESET}"; read -rp "  > " NEW_DB
    [[ -z "$NEW_DB" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1

    echo ""
    echo -e "${YELLOW}  Select owner (or press Ctrl+C to skip → default: postgres):${RESET}"
    local SEL_USER=""
    _pick_user
    local NEW_OWNER="$SEL_USER"

    local OWN_SQL=""
    [[ -n "$NEW_OWNER" ]] && OWN_SQL="WITH OWNER = ${NEW_OWNER}"
    _pg_run "CREATE DATABASE ${NEW_DB} ${OWN_SQL};"
    echo -e "${GREEN}  ✓ Database '${NEW_DB}' created.${RESET}"
  }

  _drop_database() {
    _pick_database || return 1
    local DROP_DB="$SEL_DB"
    echo -e "${RED}  ⚠ This will permanently delete '${DROP_DB}'. Type name again to confirm:${RESET}"
    read -rp "  > " CONFIRM_DROP
    [[ "$CONFIRM_DROP" != "$DROP_DB" ]] && echo -e "${RED}  ✗ Names don't match. Aborted.${RESET}" && return 1
    _pg_run "DROP DATABASE IF EXISTS ${DROP_DB};"
    echo -e "${GREEN}  ✓ Database '${DROP_DB}' dropped.${RESET}"
  }

  _rename_database() {
    _pick_database || return 1
    local OLD_DB="$SEL_DB"
    echo -e "${YELLOW}  New database name:${RESET}"; read -rp "  > " RENAME_DB
    [[ -z "$RENAME_DB" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _pg_run "ALTER DATABASE ${OLD_DB} RENAME TO ${RENAME_DB};"
    echo -e "${GREEN}  ✓ Renamed '${OLD_DB}' → '${RENAME_DB}'.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION C: TABLE OPERATIONS
  # ════════════════════════════════════════════════════════════════

  _list_tables() {
    _pick_database || return 1
    echo -e "${BOLD}${CYAN}📋 Tables in '${SEL_DB}':${RESET}"
    _pg_run_db "$SEL_DB" "\dt+"
  }

  _describe_table() {
    _pick_database || return 1
    _pick_table    || return 1
    echo -e "${BOLD}${CYAN}🔍 Structure of '${SEL_TABLE}':${RESET}"
    _pg_run_db "$SEL_DB" "\d+ ${SEL_TABLE}"
  }

  _view_table_data() {
    _pick_database || return 1
    _pick_table    || return 1
    echo -e "${BOLD}${CYAN}📄 Data in '${SEL_TABLE}':${RESET}"
    _pg_run_db "$SEL_DB" "SELECT * FROM ${SEL_TABLE};"
  }

  _row_count() {
    _pick_database || return 1
    _pick_table    || return 1
    _pg_run_db "$SEL_DB" "SELECT COUNT(*) AS total_rows FROM ${SEL_TABLE};"
  }

  _create_table() {
    _pick_database || return 1
    echo -e "${YELLOW}  New table name:${RESET}"; read -rp "  > " SEL_TABLE
    [[ -z "$SEL_TABLE" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    echo ""
    echo -e "${CYAN}  Define columns one by one. Format: ${GREEN}column_name data_type [constraints]${RESET}"
    echo -e "${DIM}  Example: id SERIAL PRIMARY KEY | name VARCHAR(100) NOT NULL | age INT DEFAULT 0${RESET}"
    echo -e "${YELLOW}  Type 'done' when finished.${RESET}"
    local COLS=()
    while true; do
      read -rp "  Column definition: " COL_DEF
      [[ "$COL_DEF" == "done" || -z "$COL_DEF" ]] && break
      COLS+=("$COL_DEF")
    done
    if [[ ${#COLS[@]} -eq 0 ]]; then
      echo -e "${RED}  ✗ No columns defined. Aborted.${RESET}"
      return 1
    fi
    local SQL="CREATE TABLE ${SEL_TABLE} (
  $(IFS=$',\n'; printf '%s,\n  ' "${COLS[@]}" | sed 's/,\n  $/\n/')
);"
    echo ""
    echo -e "${CYAN}  SQL Preview:${RESET}"
    echo -e "${DIM}${SQL}${RESET}"
    read -rp "  Execute? [y/n]: " EXEC_CONFIRM
    [[ "$EXEC_CONFIRM" != "y" && "$EXEC_CONFIRM" != "Y" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
    _pg_run_db "$SEL_DB" "$SQL"
    echo -e "${GREEN}  ✓ Table '${SEL_TABLE}' created.${RESET}"
  }

  _drop_table() {
    _pick_database || return 1
    _pick_table    || return 1
    local DROP_TBL="$SEL_TABLE"
    echo -e "${YELLOW}  CASCADE? (also drops dependent objects) [y/n]:${RESET}"; read -rp "  > " USE_CASCADE
    echo -e "${RED}  ⚠ Type table name again to confirm:${RESET}"; read -rp "  > " CONFIRM_TBL
    [[ "$CONFIRM_TBL" != "$DROP_TBL" ]] && echo -e "${RED}  ✗ Names don't match. Aborted.${RESET}" && return 1
    local CASCADE_SQL=""
    [[ "$USE_CASCADE" == "y" || "$USE_CASCADE" == "Y" ]] && CASCADE_SQL="CASCADE"
    _pg_run_db "$SEL_DB" "DROP TABLE IF EXISTS ${DROP_TBL} ${CASCADE_SQL};"
    echo -e "${GREEN}  ✓ Table '${DROP_TBL}' dropped.${RESET}"
  }

  _truncate_table() {
    _pick_database || return 1
    _pick_table    || return 1
    echo -e "${RED}  ⚠ This deletes ALL rows in '${SEL_TABLE}'. Type 'yes' to confirm:${RESET}"
    read -rp "  > " TRUNC_CONFIRM
    [[ "$TRUNC_CONFIRM" != "yes" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
    _pg_run_db "$SEL_DB" "TRUNCATE TABLE ${SEL_TABLE} RESTART IDENTITY CASCADE;"
    echo -e "${GREEN}  ✓ Table '${SEL_TABLE}' truncated.${RESET}"
  }

  _rename_table() {
    _pick_database || return 1
    _pick_table    || return 1
    local OLD_TABLE="$SEL_TABLE"
    echo -e "${YELLOW}  New table name:${RESET}"; read -rp "  > " NEW_TABLE
    [[ -z "$NEW_TABLE" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _pg_run_db "$SEL_DB" "ALTER TABLE ${OLD_TABLE} RENAME TO ${NEW_TABLE};"
    echo -e "${GREEN}  ✓ Renamed '${OLD_TABLE}' → '${NEW_TABLE}'.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION D: COLUMN OPERATIONS
  # ════════════════════════════════════════════════════════════════

  _add_column() {
    _pick_database || return 1
    _pick_table    || return 1
    echo -e "${DIM}  e.g. email VARCHAR(255) NOT NULL DEFAULT ''${RESET}"
    read -rp "  Column definition: " COL_DEF
    [[ -z "$COL_DEF" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _pg_run_db "$SEL_DB" "ALTER TABLE ${SEL_TABLE} ADD COLUMN ${COL_DEF};"
    echo -e "${GREEN}  ✓ Column added.${RESET}"
  }

  _drop_column() {
    _pick_database || return 1
    _pick_table    || return 1

    echo -e "${BOLD}${CYAN}  📋 Fetching columns in '${SEL_TABLE}'...${RESET}"
    local raw_cols
    raw_cols=$(PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -d "$SEL_DB" -Atc \
      "SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='${SEL_TABLE}' ORDER BY ordinal_position;" 2>&1)
    local cols=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && cols+=("$line")
    done <<< "$raw_cols"

    if [[ ${#cols[@]} -eq 0 ]]; then
      echo -e "${RED}  ✗ No columns found.${RESET}"; return 1
    fi

    echo ""
    echo -e "${BOLD}${YELLOW}  Select Column to Drop:${RESET}"
    local i=1
    for col in "${cols[@]}"; do
      echo -e "  ${GREEN}${i})${RESET} ${col}"
      ((i++))
    done
    echo ""
    read -rp "  Choose [1-${#cols[@]}]: " COL_CHOICE
    if ! [[ "$COL_CHOICE" =~ ^[0-9]+$ ]] || \
       [[ "$COL_CHOICE" -lt 1 || "$COL_CHOICE" -gt ${#cols[@]} ]]; then
      echo -e "${RED}  ✗ Invalid choice.${RESET}"; return 1
    fi
    SEL_COL="${cols[$((COL_CHOICE - 1))]}"
    echo -e "  ${GREEN}✓ Selected: ${BOLD}${SEL_COL}${RESET}"
    echo ""

    echo -e "${RED}  ⚠ Drop column '${SEL_COL}' from '${SEL_TABLE}'? [y/n]:${RESET}"
    read -rp "  > " DCOL_CONFIRM
    [[ "$DCOL_CONFIRM" != "y" && "$DCOL_CONFIRM" != "Y" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
    _pg_run_db "$SEL_DB" "ALTER TABLE ${SEL_TABLE} DROP COLUMN IF EXISTS ${SEL_COL} CASCADE;"
    echo -e "${GREEN}  ✓ Column '${SEL_COL}' dropped.${RESET}"
  }

  _rename_column() {
    _pick_database || return 1
    _pick_table    || return 1

    echo -e "${BOLD}${CYAN}  📋 Fetching columns in '${SEL_TABLE}'...${RESET}"
    local raw_cols
    raw_cols=$(PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -d "$SEL_DB" -Atc \
      "SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='${SEL_TABLE}' ORDER BY ordinal_position;" 2>&1)
    local cols=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && cols+=("$line")
    done <<< "$raw_cols"

    if [[ ${#cols[@]} -eq 0 ]]; then
      echo -e "${RED}  ✗ No columns found.${RESET}"; return 1
    fi

    echo ""
    echo -e "${BOLD}${YELLOW}  Select Column to Rename:${RESET}"
    local i=1
    for col in "${cols[@]}"; do
      echo -e "  ${GREEN}${i})${RESET} ${col}"
      ((i++))
    done
    echo ""
    read -rp "  Choose [1-${#cols[@]}]: " COL_CHOICE
    if ! [[ "$COL_CHOICE" =~ ^[0-9]+$ ]] || \
       [[ "$COL_CHOICE" -lt 1 || "$COL_CHOICE" -gt ${#cols[@]} ]]; then
      echo -e "${RED}  ✗ Invalid choice.${RESET}"; return 1
    fi
    local OLD_COL="${cols[$((COL_CHOICE - 1))]}"
    echo -e "  ${GREEN}✓ Selected: ${BOLD}${OLD_COL}${RESET}"
    echo ""

    read -rp "  New column name: " NEW_COL
    [[ -z "$NEW_COL" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _pg_run_db "$SEL_DB" "ALTER TABLE ${SEL_TABLE} RENAME COLUMN ${OLD_COL} TO ${NEW_COL};"
    echo -e "${GREEN}  ✓ Column renamed '${OLD_COL}' → '${NEW_COL}'.${RESET}"
  }

  _change_column_type() {
    _pick_database || return 1
    _pick_table    || return 1

    echo -e "${BOLD}${CYAN}  📋 Fetching columns in '${SEL_TABLE}'...${RESET}"
    local raw_cols
    raw_cols=$(PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -d "$SEL_DB" -Atc \
      "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema='public' AND table_name='${SEL_TABLE}' ORDER BY ordinal_position;" 2>&1)
    local cols=() col_types=()
    while IFS='|' read -r cname ctype; do
      [[ -n "$cname" ]] && cols+=("$cname") && col_types+=("$ctype")
    done <<< "$raw_cols"

    if [[ ${#cols[@]} -eq 0 ]]; then
      echo -e "${RED}  ✗ No columns found.${RESET}"; return 1
    fi

    echo ""
    echo -e "${BOLD}${YELLOW}  Select Column to Change Type:${RESET}"
    local i=1
    for idx in "${!cols[@]}"; do
      echo -e "  ${GREEN}$((idx+1)))${RESET} ${cols[$idx]}  ${DIM}(${col_types[$idx]})${RESET}"
    done
    echo ""
    read -rp "  Choose [1-${#cols[@]}]: " COL_CHOICE
    if ! [[ "$COL_CHOICE" =~ ^[0-9]+$ ]] || \
       [[ "$COL_CHOICE" -lt 1 || "$COL_CHOICE" -gt ${#cols[@]} ]]; then
      echo -e "${RED}  ✗ Invalid choice.${RESET}"; return 1
    fi
    local SEL_COL="${cols[$((COL_CHOICE - 1))]}"
    echo -e "  ${GREEN}✓ Selected: ${BOLD}${SEL_COL}${RESET}"
    echo ""

    echo -e "${DIM}  e.g. TEXT, INTEGER, BOOLEAN, TIMESTAMP, JSONB${RESET}"
    read -rp "  New type: " NEW_TYPE
    [[ -z "$NEW_TYPE" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _pg_run_db "$SEL_DB" "ALTER TABLE ${SEL_TABLE} ALTER COLUMN ${SEL_COL} TYPE ${NEW_TYPE} USING ${SEL_COL}::${NEW_TYPE};"
    echo -e "${GREEN}  ✓ Column type changed.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION E: INDEX OPERATIONS
  # ════════════════════════════════════════════════════════════════

  _list_indexes() {
    _pick_database || return 1
    echo -e "${YELLOW}  Filter by table? (press Enter to list all indexes):${RESET}"
    _pick_table
    if [[ -n "$SEL_TABLE" ]]; then
      _pg_run_db "$SEL_DB" "\di+ ${SEL_TABLE}*"
    else
      _pg_run_db "$SEL_DB" "\di+"
    fi
  }

  _create_index() {
    _pick_database || return 1
    _pick_table    || return 1
    read -rp "  Column(s) to index : " IDX_COLS
    read -rp "  Index name (blank = auto): " IDX_NAME
    echo -e "${YELLOW}  Index type (btree/hash/gin/gist) [default btree]:${RESET}"
    read -rp "  > " IDX_TYPE
    IDX_TYPE="${IDX_TYPE:-btree}"
    echo -e "${YELLOW}  UNIQUE index? [y/n]:${RESET}"; read -rp "  > " IDX_UNIQUE
    [[ -z "$IDX_COLS" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    local UNIQUE_SQL=""
    [[ "$IDX_UNIQUE" == "y" || "$IDX_UNIQUE" == "Y" ]] && UNIQUE_SQL="UNIQUE"
    [[ -z "$IDX_NAME" ]] && IDX_NAME="idx_${SEL_TABLE}_${IDX_COLS// /_}"
    _pg_run_db "$SEL_DB" "CREATE ${UNIQUE_SQL} INDEX ${IDX_NAME} ON ${SEL_TABLE} USING ${IDX_TYPE} (${IDX_COLS});"
    echo -e "${GREEN}  ✓ Index '${IDX_NAME}' created.${RESET}"
  }

  _drop_index() {
    _pick_database || return 1

    echo -e "${BOLD}${CYAN}  📋 Fetching indexes in '${SEL_DB}'...${RESET}"
    local raw_idx
    raw_idx=$(PGPASSWORD="$PG_PASS" psql -U "$PG_USER" -h localhost -d "$SEL_DB" -Atc \
      "SELECT indexname FROM pg_indexes WHERE schemaname='public' ORDER BY indexname;" 2>&1)
    local idxs=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && idxs+=("$line")
    done <<< "$raw_idx"

    if [[ ${#idxs[@]} -eq 0 ]]; then
      echo -e "${RED}  ✗ No indexes found.${RESET}"; return 1
    fi

    echo ""
    echo -e "${BOLD}${YELLOW}  Select Index to Drop:${RESET}"
    local i=1
    for idx in "${idxs[@]}"; do
      echo -e "  ${GREEN}${i})${RESET} ${idx}"
      ((i++))
    done
    echo ""
    read -rp "  Choose [1-${#idxs[@]}]: " IDX_CHOICE
    if ! [[ "$IDX_CHOICE" =~ ^[0-9]+$ ]] || \
       [[ "$IDX_CHOICE" -lt 1 || "$IDX_CHOICE" -gt ${#idxs[@]} ]]; then
      echo -e "${RED}  ✗ Invalid choice.${RESET}"; return 1
    fi
    local IDX_NAME="${idxs[$((IDX_CHOICE - 1))]}"
    echo -e "  ${GREEN}✓ Selected: ${BOLD}${IDX_NAME}${RESET}"

    echo -e "${RED}  ⚠ Drop index '${IDX_NAME}'? [y/n]:${RESET}"; read -rp "  > " IDX_CONFIRM
    [[ "$IDX_CONFIRM" != "y" && "$IDX_CONFIRM" != "Y" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
    _pg_run_db "$SEL_DB" "DROP INDEX IF EXISTS ${IDX_NAME} CASCADE;"
    echo -e "${GREEN}  ✓ Index '${IDX_NAME}' dropped.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION F: USER / ROLE OPERATIONS
  # ════════════════════════════════════════════════════════════════

  _list_users() {
    echo ""
    echo -e "${BOLD}${CYAN}👥 All Roles/Users:${RESET}"
    _pg_run "\du+"
  }

  _create_user() {
    read -rp "  New username : " NEW_USER
    read -rsp "  Password     : " NEW_PASS; echo ""
    echo -e "${YELLOW}  SUPERUSER? [y/n]:${RESET}"; read -rp "  > " IS_SU
    [[ -z "$NEW_USER" || -z "$NEW_PASS" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    local SU_FLAG=""
    [[ "$IS_SU" == "y" || "$IS_SU" == "Y" ]] && SU_FLAG="SUPERUSER"
    _pg_run "CREATE ROLE ${NEW_USER} WITH LOGIN ${SU_FLAG} PASSWORD '${NEW_PASS}';"
    echo -e "${GREEN}  ✓ User '${NEW_USER}' created.${RESET}"
  }

  _drop_user() {
    _pick_user || return 1
    local DROP_USER="$SEL_USER"
    echo -e "${RED}  ⚠ Type username again to confirm:${RESET}"; read -rp "  > " CONFIRM_USR
    [[ "$CONFIRM_USR" != "$DROP_USER" ]] && echo -e "${RED}  ✗ Names don't match. Aborted.${RESET}" && return 1
    _pg_run "DROP ROLE IF EXISTS ${DROP_USER};"
    echo -e "${GREEN}  ✓ User '${DROP_USER}' dropped.${RESET}"
  }

  _change_password() {
    _pick_user || return 1
    local CHG_USER="$SEL_USER"
    read -rsp "  New password     : " CHG_PASS; echo ""
    read -rsp "  Confirm password : " CHG_PASS2; echo ""
    [[ -z "$CHG_PASS" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    [[ "$CHG_PASS" != "$CHG_PASS2" ]] && echo -e "${RED}  ✗ Passwords don't match.${RESET}" && return 1
    _pg_run "ALTER ROLE ${CHG_USER} WITH PASSWORD '${CHG_PASS}';"
    echo -e "${GREEN}  ✓ Password updated for '${CHG_USER}'.${RESET}"
  }

  _grant_privileges() {
    _pick_database || return 1
    _pick_user     || return 1
    local PRIV_USER="$SEL_USER"
    _pg_run "GRANT ALL PRIVILEGES ON DATABASE ${SEL_DB} TO ${PRIV_USER};"
    _pg_run_db "$SEL_DB" "
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${PRIV_USER};
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${PRIV_USER};
      GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO ${PRIV_USER};
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${PRIV_USER};
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ${PRIV_USER};
    "
    echo -e "${GREEN}  ✓ All privileges granted to '${PRIV_USER}' on '${SEL_DB}'.${RESET}"
  }

  _revoke_privileges() {
    _pick_database || return 1
    _pick_user     || return 1
    local REV_USER="$SEL_USER"
    _pg_run_db "$SEL_DB" "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM ${REV_USER};"
    _pg_run "REVOKE ALL PRIVILEGES ON DATABASE ${SEL_DB} FROM ${REV_USER};"
    echo -e "${GREEN}  ✓ Privileges revoked from '${REV_USER}' on '${SEL_DB}'.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION G: CUSTOM SQL
  # ════════════════════════════════════════════════════════════════

  _run_custom_sql() {
    echo -e "${YELLOW}  Select database (or press Ctrl+C to use default postgres):${RESET}"
    _pick_database
    echo -e "${CYAN}  Enter SQL query (single line):${RESET}"
    read -rp "  SQL> " CUSTOM_SQL
    [[ -z "$CUSTOM_SQL" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    if [[ -n "$SEL_DB" ]]; then
      _pg_run_db "$SEL_DB" "$CUSTOM_SQL"
    else
      _pg_run "$CUSTOM_SQL"
    fi
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION H: MONITORING / INFO
  # ════════════════════════════════════════════════════════════════

  _show_connections() {
    echo ""
    echo -e "${BOLD}${CYAN}🔌 Active Connections:${RESET}"
    _pg_run "SELECT pid, usename, datname, client_addr, state, query_start, LEFT(query,60) AS query FROM pg_stat_activity WHERE state IS NOT NULL ORDER BY query_start DESC;"
  }

  _show_db_sizes() {
    echo ""
    echo -e "${BOLD}${CYAN}💾 Database Sizes:${RESET}"
    _pg_run "SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size FROM pg_database ORDER BY pg_database_size(datname) DESC;"
  }

  _show_table_sizes() {
    _pick_database || return 1
    echo ""
    echo -e "${BOLD}${CYAN}📊 Table Sizes in '${SEL_DB}':${RESET}"
    _pg_run_db "$SEL_DB" "SELECT tablename, pg_size_pretty(pg_total_relation_size(quote_ident(tablename))) AS total_size, pg_size_pretty(pg_relation_size(quote_ident(tablename))) AS table_size FROM pg_tables WHERE schemaname='public' ORDER BY pg_total_relation_size(quote_ident(tablename)) DESC;"
  }

  _show_running_queries() {
    echo ""
    echo -e "${BOLD}${CYAN}⚡ Running Queries:${RESET}"
    _pg_run "SELECT pid, usename, datname, state, wait_event_type, wait_event, NOW() - query_start AS duration, LEFT(query,80) AS query FROM pg_stat_activity WHERE state = 'active' ORDER BY duration DESC NULLS LAST;"
  }

  _kill_query() {
    echo ""
    echo -e "${BOLD}${CYAN}⚡ Active Processes:${RESET}"
    _pg_run "SELECT pid, usename, datname, state, LEFT(query,60) AS query FROM pg_stat_activity WHERE state IS NOT NULL ORDER BY pid;"
    echo ""
    read -rp "  Process ID (PID) to terminate: " KILL_PID
    [[ -z "$KILL_PID" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _pg_run "SELECT pg_terminate_backend(${KILL_PID});"
    echo -e "${GREEN}  ✓ Process ${KILL_PID} terminated.${RESET}"
  }

  _show_pg_info() {
    echo ""
    echo -e "${BOLD}${CYAN}ℹ️  PostgreSQL Info:${RESET}"
    _pg_run "SELECT version();"
    echo ""
    echo -e "${BOLD}${CYAN}⚙️  Key Config Values:${RESET}"
    _pg_run "SHOW max_connections; SHOW shared_buffers; SHOW work_mem; SHOW data_directory;"
  }

  _backup_database() {
    _pick_database || return 1
    local BKP_DB="$SEL_DB"
    read -rp "  Output file path (blank = auto): " BKP_FILE
    BKP_FILE="${BKP_FILE:-/tmp/${BKP_DB}_$(date +%Y%m%d_%H%M%S).dump}"
    echo -e "${YELLOW}  Backing up '${BKP_DB}' → ${BKP_FILE} ...${RESET}"
    PGPASSWORD="$PG_PASS" pg_dump -U "$PG_USER" -h localhost -Fc "$BKP_DB" > "$BKP_FILE" 2>&1
    if [[ $? -eq 0 ]]; then
      echo -e "${GREEN}  ✓ Backup saved: ${BKP_FILE}${RESET}"
    else
      echo -e "${RED}  ✗ Backup failed.${RESET}"
    fi
  }

  _restore_database() {
    _pick_database || return 1
    local RST_DB="$SEL_DB"
    read -rp "  Dump file path: " RST_FILE
    [[ -z "$RST_FILE" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    [[ ! -f "$RST_FILE" ]] && echo -e "${RED}  ✗ File not found: ${RST_FILE}${RESET}" && return 1
    echo -e "${YELLOW}  Restoring '${RST_FILE}' → '${RST_DB}' ...${RESET}"
    PGPASSWORD="$PG_PASS" pg_restore -U "$PG_USER" -h localhost -d "$RST_DB" "$RST_FILE" 2>&1
    echo -e "${GREEN}  ✓ Restore complete.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # MAIN MENU LOOP
  # ════════════════════════════════════════════════════════════════
  while true; do
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║          🐘  pgtools — PostgreSQL Toolkit                ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ DATABASE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN} 1)${RESET} 🚀  Full Setup          ${DIM}-- CREATE ROLE myuser WITH LOGIN PASSWORD 'pass'; CREATE DATABASE mydb;${RESET}"
    echo -e "  ${GREEN} 2)${RESET} 📦  List databases      ${DIM}-- \\l+  /  SELECT datname FROM pg_database;${RESET}"
    echo -e "  ${GREEN} 3)${RESET} ➕  Create database     ${DIM}-- CREATE DATABASE mydb WITH OWNER = myuser;${RESET}"
    echo -e "  ${GREEN} 4)${RESET} 🗑   Drop database       ${DIM}-- DROP DATABASE IF EXISTS mydb;${RESET}"
    echo -e "  ${GREEN} 5)${RESET} ✏️   Rename database     ${DIM}-- ALTER DATABASE oldname RENAME TO newname;${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ TABLES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN} 6)${RESET} 📋  List tables         ${DIM}-- \\dt+  /  SELECT tablename FROM pg_tables WHERE schemaname='public';${RESET}"
    echo -e "  ${GREEN} 7)${RESET} 🔍  Describe table      ${DIM}-- \\d+ tablename${RESET}"
    echo -e "  ${GREEN} 8)${RESET} 📄  View table data     ${DIM}-- SELECT * FROM tablename;${RESET}"
    echo -e "  ${GREEN} 9)${RESET} 🔢  Row count           ${DIM}-- SELECT COUNT(*) FROM tablename;${RESET}"
    echo -e "  ${GREEN}10)${RESET} ➕  Create table        ${DIM}-- CREATE TABLE users (id SERIAL PRIMARY KEY, ...);${RESET}"
    echo -e "  ${GREEN}11)${RESET} 🗑   Drop table          ${DIM}-- DROP TABLE IF EXISTS tablename CASCADE;${RESET}"
    echo -e "  ${GREEN}12)${RESET} 🧹  Truncate table      ${DIM}-- TRUNCATE TABLE tablename RESTART IDENTITY CASCADE;${RESET}"
    echo -e "  ${GREEN}13)${RESET} ✏️   Rename table        ${DIM}-- ALTER TABLE oldname RENAME TO newname;${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ COLUMNS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}14)${RESET} ➕  Add column          ${DIM}-- ALTER TABLE users ADD COLUMN age INT DEFAULT 0;${RESET}"
    echo -e "  ${GREEN}15)${RESET} 🗑   Drop column         ${DIM}-- ALTER TABLE users DROP COLUMN IF EXISTS age CASCADE;${RESET}"
    echo -e "  ${GREEN}16)${RESET} ✏️   Rename column       ${DIM}-- ALTER TABLE users RENAME COLUMN oldcol TO newcol;${RESET}"
    echo -e "  ${GREEN}17)${RESET} 🔄  Change column type  ${DIM}-- ALTER TABLE users ALTER COLUMN age TYPE BIGINT USING age::BIGINT;${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ INDEXES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}18)${RESET} 📋  List indexes        ${DIM}-- \\di+${RESET}"
    echo -e "  ${GREEN}19)${RESET} ➕  Create index        ${DIM}-- CREATE UNIQUE INDEX idx_users_email ON users USING btree (email);${RESET}"
    echo -e "  ${GREEN}20)${RESET} 🗑   Drop index          ${DIM}-- DROP INDEX IF EXISTS idx_users_email CASCADE;${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ USERS / ROLES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}21)${RESET} 👥  List users/roles    ${DIM}-- \\du+${RESET}"
    echo -e "  ${GREEN}22)${RESET} ➕  Create user         ${DIM}-- CREATE ROLE myuser WITH LOGIN SUPERUSER PASSWORD 'pass';${RESET}"
    echo -e "  ${GREEN}23)${RESET} 🗑   Drop user           ${DIM}-- DROP ROLE IF EXISTS myuser;${RESET}"
    echo -e "  ${GREEN}24)${RESET} 🔑  Change password     ${DIM}-- ALTER ROLE myuser WITH PASSWORD 'newpass';${RESET}"
    echo -e "  ${GREEN}25)${RESET} ✅  Grant privileges    ${DIM}-- GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;${RESET}"
    echo -e "  ${GREEN}26)${RESET} ❌  Revoke privileges   ${DIM}-- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM myuser;${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ MONITORING ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}27)${RESET} 🔌  Active connections  ${DIM}-- SELECT pid, usename, datname, state FROM pg_stat_activity;${RESET}"
    echo -e "  ${GREEN}28)${RESET} 💾  DB sizes            ${DIM}-- SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;${RESET}"
    echo -e "  ${GREEN}29)${RESET} 📊  Table sizes         ${DIM}-- SELECT tablename, pg_size_pretty(...) FROM pg_tables;${RESET}"
    echo -e "  ${GREEN}30)${RESET} ⚡  Running queries     ${DIM}-- SELECT pid, state, NOW()-query_start AS duration, query FROM pg_stat_activity;${RESET}"
    echo -e "  ${GREEN}31)${RESET} 💀  Kill query by PID   ${DIM}-- SELECT pg_terminate_backend(pid);${RESET}"
    echo -e "  ${GREEN}32)${RESET} ℹ️   PG version & config ${DIM}-- SELECT version(); SHOW max_connections;${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ BACKUP / RESTORE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}33)${RESET} 💾  Backup (pg_dump)    ${DIM}-- pg_dump -Fc mydb > mydb_backup.dump${RESET}"
    echo -e "  ${GREEN}34)${RESET} 📥  Restore (pg_restore)${DIM}-- pg_restore -d mydb mydb_backup.dump${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ CUSTOM SQL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}35)${RESET} 💻  Run custom SQL      ${DIM}-- SELECT * FROM users WHERE ...${RESET}"
    echo ""
    echo -e "  ${RED} 0)${RESET} 🚪  Exit  ${DIM}(stops PostgreSQL)${RESET}"
    echo ""
    read -rp "  Choose option [0-35]: " CHOICE

    echo ""
    case "$CHOICE" in
       1) _pgsetup ;;
       2) _list_databases ;;
       3) _create_database ;;
       4) _drop_database ;;
       5) _rename_database ;;
       6) _list_tables ;;
       7) _describe_table ;;
       8) _view_table_data ;;
       9) _row_count ;;
      10) _create_table ;;
      11) _drop_table ;;
      12) _truncate_table ;;
      13) _rename_table ;;
      14) _add_column ;;
      15) _drop_column ;;
      16) _rename_column ;;
      17) _change_column_type ;;
      18) _list_indexes ;;
      19) _create_index ;;
      20) _drop_index ;;
      21) _list_users ;;
      22) _create_user ;;
      23) _drop_user ;;
      24) _change_password ;;
      25) _grant_privileges ;;
      26) _revoke_privileges ;;
      27) _show_connections ;;
      28) _show_db_sizes ;;
      29) _show_table_sizes ;;
      30) _show_running_queries ;;
      31) _kill_query ;;
      32) _show_pg_info ;;
      33) _backup_database ;;
      34) _restore_database ;;
      35) _run_custom_sql ;;
       0)
          # Disable trap first (clean exit, not crash)
          trap - EXIT
          echo -e "${CYAN}  Goodbye! 🐘${RESET}"
          _pg_stop
          echo ""
          return 0
          ;;
       *) echo -e "${RED}  ✗ Invalid option. Choose 0-35.${RESET}" ;;
    esac

    echo ""
    read -rp "  Press Enter to return to menu..." _PAUSE
  done
}
