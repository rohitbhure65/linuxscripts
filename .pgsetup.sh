#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# pgsetup — Interactive PostgreSQL database + user setup
#
# INSTALL:
#   cp .pgsetup.sh ~/.pgsetup.sh
#   echo 'source ~/.pgsetup.sh' >> ~/.bashrc
#   source ~/.bashrc
#
# USAGE:
#   pgsetup   → Auto-starts PostgreSQL, runs setup, stops on exit
#
# BEHAVIOR:
#   • PostgreSQL auto-starts when you run `pgsetup`
#   • PostgreSQL auto-stops + disables when setup completes
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
# pgsetup — Interactive Setup
# =================================================================
pgsetup() {

  # ── Colors ──────────────────────────────────────────────────────
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local BOLD='\033[1m'
  local RESET='\033[0m'

  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║     🐘 PostgreSQL Interactive Setup Tool     ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""

  # ── Auto-start PostgreSQL ────────────────────────────────────────
  _pg_start || return 1

  # ── EXIT trap: stop PostgreSQL if terminal is force-closed ───────
  # (normal completion also calls _pg_stop explicitly at the end)
  trap '_pg_stop' EXIT

  # ── Info ─────────────────────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}This tool will:${RESET}"
  echo -e "  ${GREEN}✓${RESET} Create a PostgreSQL role (user) with superuser login"
  echo -e "  ${GREEN}✓${RESET} Create a new database"
  echo -e "  ${GREEN}✓${RESET} Set the database owner to your role"
  echo -e "  ${GREEN}✓${RESET} Grant all privileges on database, tables, sequences, functions"
  echo -e "  ${GREEN}✓${RESET} Set default privileges for future objects"
  echo ""
  echo -e "${YELLOW}Connection Examples:${RESET}"
  echo ""
  echo -e "  ${GREEN}✓${RESET} Connect as your new user:"
  echo -e "      ${CYAN}psql -U USERNAME -d DATABASE -h HOST${RESET}"
  echo -e "      ${CYAN}Example:${RESET} psql -U admin -d demo -h localhost"
  echo ""
  echo -e "  ${GREEN}✓${RESET} Connection string (Prisma / .env):"
  echo -e "      ${CYAN}DATABASE_URL="postgresql://USERNAME:[PASSWORD]@HOST:5432/DATABASE"${RESET}'"
  echo -e "      ${CYAN}Example:${RESET} DATABASE_URL="postgresql://admin:secret123@localhost:5432/demo""
  echo ""
  echo -e "  ${GREEN}✓${RESET} Connect via postgres superuser:"
  echo -e "      ${CYAN}sudo -i -u postgres psql -d DATABASE${RESET}"
  echo -e "      ${CYAN}Example:${RESET} sudo -i -u postgres psql -d demo"
  echo ""

  # ── Step 1: DB Username ─────────────────────────────────────────
  echo -e "${BOLD}${CYAN}── Step 1: Database Role (Username) ──────────────────${RESET}"
  echo -e "${YELLOW}What is the PostgreSQL role/username you want to create?${RESET}"
  echo -e "  Example: ${GREEN}myapp_user${RESET}, ${GREEN}admin${RESET}, ${GREEN}root${RESET}, ${GREEN}devuser${RESET}"
  echo -e "  ${YELLOW}Note:${RESET} Avoid using 'postgres' (already exists)"
  echo ""
  read -rp "  Enter username: " DB_USER

  if [[ -z "$DB_USER" ]]; then
    echo -e "${RED}  ✗ Username cannot be empty. Exiting.${RESET}"
    trap - EXIT
    _pg_stop
    return 1
  fi

  # ── Step 2: DB Password ─────────────────────────────────────────
  echo ""
  echo -e "${BOLD}${CYAN}── Step 2: Password ──────────────────────────────────${RESET}"
  echo -e "${YELLOW}What password do you want for the role '${DB_USER}'?${RESET}"
  echo -e "  Example: ${GREEN}MyStr0ng@Pass${RESET}, ${GREEN}secret123${RESET}"
  echo -e "  ${YELLOW}Tip:${RESET} Use a strong password in production"
  echo ""
  read -rsp "  Enter password (hidden): " DB_PASS
  echo ""
  read -rsp "  Confirm password (hidden): " DB_PASS_CONFIRM
  echo ""

  if [[ "$DB_PASS" != "$DB_PASS_CONFIRM" ]]; then
    echo -e "${RED}  ✗ Passwords do not match. Exiting.${RESET}"
    trap - EXIT
    _pg_stop
    return 1
  fi

  if [[ -z "$DB_PASS" ]]; then
    echo -e "${RED}  ✗ Password cannot be empty. Exiting.${RESET}"
    trap - EXIT
    _pg_stop
    return 1
  fi

  # ── Step 3: Database Name ───────────────────────────────────────
  echo ""
  echo -e "${BOLD}${CYAN}── Step 3: Database Name ─────────────────────────────${RESET}"
  echo -e "${YELLOW}What do you want to name the database?${RESET}"
  echo -e "  Example: ${GREEN}myapp_db${RESET}, ${GREEN}streamx24${RESET}, ${GREEN}arenax${RESET}, ${GREEN}production_db${RESET}"
  echo -e "  ${YELLOW}Note:${RESET} Use lowercase, underscores allowed, no spaces"
  echo ""
  read -rp "  Enter database name: " DB_NAME

  if [[ -z "$DB_NAME" ]]; then
    echo -e "${RED}  ✗ Database name cannot be empty. Exiting.${RESET}"
    trap - EXIT
    _pg_stop
    return 1
  fi

  # ── Step 4: Superuser option ────────────────────────────────────
  echo ""
  echo -e "${BOLD}${CYAN}── Step 4: Role Type ─────────────────────────────────${RESET}"
  echo -e "${YELLOW}Should '${DB_USER}' be a SUPERUSER?${RESET}"
  echo -e "  ${GREEN}y${RESET} = SUPERUSER   (full control, recommended for dev)"
  echo -e "  ${GREEN}n${RESET} = normal user (safer for production)"
  echo ""
  read -rp "  Make superuser? [y/n] (default: y): " IS_SUPER
  IS_SUPER="${IS_SUPER:-y}"

  if [[ "$IS_SUPER" == "y" || "$IS_SUPER" == "Y" ]]; then
    ROLE_TYPE="SUPERUSER"
  else
    ROLE_TYPE=""
  fi

  # ── Confirm ─────────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}${CYAN}── Confirm Settings ──────────────────────────────────${RESET}"
  echo -e "  Role/Username : ${GREEN}${DB_USER}${RESET}"
  echo -e "  Password      : ${GREEN}[hidden]${RESET}"
  echo -e "  Database      : ${GREEN}${DB_NAME}${RESET}"
  echo -e "  Role Type     : ${GREEN}${ROLE_TYPE:-NORMAL USER}${RESET}"
  echo ""
  read -rp "  Proceed? [y/n]: " CONFIRM

  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "${RED}  Aborted.${RESET}"
    trap - EXIT
    _pg_stop
    return 1
  fi

  # ── Build SQL ───────────────────────────────────────────────────
  local SQL="
-- Step 1: Create role
CREATE ROLE ${DB_USER} WITH LOGIN ${ROLE_TYPE} PASSWORD '${DB_PASS}';

-- Step 2: Create database
CREATE DATABASE ${DB_NAME};

-- Step 3: Set owner
ALTER DATABASE ${DB_NAME} OWNER TO ${DB_USER};

-- Step 4: Grant all privileges on database
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
"

  local SQL_IN_DB="
-- Step 5: Grant on all existing tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DB_USER};

-- Step 6: Grant on all existing sequences
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${DB_USER};

-- Step 7: Grant on all existing functions
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO ${DB_USER};

-- Step 8: Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON TABLES TO ${DB_USER};

-- Step 9: Set default privileges for future sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON SEQUENCES TO ${DB_USER};

-- Step 10: Set default privileges for future functions
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON FUNCTIONS TO ${DB_USER};
"

  # ── Run ─────────────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}${CYAN}── Running Setup ─────────────────────────────────────${RESET}"
  echo ""

  echo -e "${YELLOW}[1/2]${RESET} Running global SQL (role + database)..."
  echo "$SQL" | sudo -i -u postgres psql

  if [[ $? -ne 0 ]]; then
    echo -e "${RED}  ✗ Error in Step 1/2. Check output above.${RESET}"
    trap - EXIT
    _pg_stop
    return 1
  fi

  echo ""
  echo -e "${YELLOW}[2/2]${RESET} Running in-database SQL (privileges + defaults)..."
  echo "$SQL_IN_DB" | sudo -i -u postgres psql -d "$DB_NAME"

  if [[ $? -ne 0 ]]; then
    echo -e "${RED}  ✗ Error in Step 2/2. Check output above.${RESET}"
    trap - EXIT
    _pg_stop
    return 1
  fi

  # ── Done ────────────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${GREEN}║           ✅  Setup Complete!                ║${RESET}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${CYAN}Connect as your new user:${RESET}"
  echo -e "  ${GREEN}psql -U ${DB_USER} -d ${DB_NAME} -h localhost${RESET}"
  echo ""
  echo -e "  ${CYAN}Connection string (Prisma / .env):${RESET}"
  echo -e "  ${GREEN}DATABASE_URL=\"postgresql://${DB_USER}:[password]@localhost:5432/${DB_NAME}\"${RESET}"
  echo ""
  echo -e "  ${CYAN}Connect via postgres superuser:${RESET}"
  echo -e "  ${GREEN}sudo -i -u postgres psql -d ${DB_NAME}${RESET}"
  echo ""

  # ── Clean exit: disable trap then stop PostgreSQL ───────────────
  trap - EXIT
  _pg_stop
  echo ""
}
