#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# prismatools — Full Prisma ORM Interactive Toolkit
#
# INSTALL:
#   cp .prismatools.sh ~/.prismatools.sh
#   echo 'source ~/.prismatools.sh' >> ~/.bashrc
#   source ~/.bashrc
#
# USAGE:
#   prismatools   → Interactive menu for all Prisma commands
#   prismahelp    → Full cheatsheet (schema, relations, commands)
# ─────────────────────────────────────────────────────────────────


# =================================================================
# prismatools — Interactive Menu
# =================================================================
prismatools() {

  # ── Colors ──────────────────────────────────────────────────────
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local MAGENTA='\033[0;35m'
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local RESET='\033[0m'

  # ── Check prisma is installed ────────────────────────────────────
  if ! command -v npx &>/dev/null; then
    echo -e "${RED}  ✗ npx not found. Install Node.js first.${RESET}"
    return 1
  fi

  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║        ▲  prismatools — Prisma Interactive Toolkit           ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  # ── Ask for project path ─────────────────────────────────────────
  read -rp "  Project path (blank = current dir): " PROJ_PATH
  PROJ_PATH="${PROJ_PATH:-.}"
  if [[ ! -d "$PROJ_PATH" ]]; then
    echo -e "${RED}  ✗ Directory not found: ${PROJ_PATH}${RESET}"
    return 1
  fi
  cd "$PROJ_PATH" || return 1
  echo -e "${GREEN}  ✓ Working in: $(pwd)${RESET}"
  echo ""

  # ════════════════════════════════════════════════════════════════
  # SECTION A: SETUP
  # ════════════════════════════════════════════════════════════════

  _prisma_init() {
    echo ""
    echo -e "${BOLD}${CYAN}── Prisma Init ───────────────────────────────────────${RESET}"
    echo -e "${YELLOW}  Datasource provider:${RESET}"
    echo -e "  ${GREEN}1)${RESET} postgresql  ${GREEN}2)${RESET} mysql  ${GREEN}3)${RESET} sqlite  ${GREEN}4)${RESET} mongodb  ${GREEN}5)${RESET} sqlserver"
    read -rp "  Choose [1-5] (default: 1): " DS_CHOICE
    case "${DS_CHOICE:-1}" in
      1) DS="postgresql" ;;
      2) DS="mysql" ;;
      3) DS="sqlite" ;;
      4) DS="mongodb" ;;
      5) DS="sqlserver" ;;
      *) DS="postgresql" ;;
    esac
    echo -e "${YELLOW}  Running: npx prisma init --datasource-provider ${DS}${RESET}"
    npx prisma init --datasource-provider "$DS"
    echo ""
    echo -e "${GREEN}  ✓ Prisma initialized!${RESET}"
    echo -e "  ${DIM}Next: Edit prisma/schema.prisma and set DATABASE_URL in .env${RESET}"
  }

  _prisma_init_url() {
    echo ""
    read -rp "  Full DATABASE_URL (e.g. postgresql://user:pass@localhost:5432/mydb): " DB_URL
    [[ -z "$DB_URL" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    npx prisma init --url "$DB_URL"
    echo -e "${GREEN}  ✓ Prisma initialized with URL.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION B: MIGRATE
  # ════════════════════════════════════════════════════════════════

  _migrate_dev() {
    echo ""
    read -rp "  Migration name (e.g. add_user_table): " MIG_NAME
    [[ -z "$MIG_NAME" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    echo -e "${YELLOW}  Running: npx prisma migrate dev --name ${MIG_NAME}${RESET}"
    npx prisma migrate dev --name "$MIG_NAME"
  }

  _migrate_dev_blank() {
    echo ""
    read -rp "  Migration name: " MIG_NAME
    [[ -z "$MIG_NAME" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    echo -e "${YELLOW}  Running: npx prisma migrate dev --name ${MIG_NAME} --create-only${RESET}"
    npx prisma migrate dev --name "$MIG_NAME" --create-only
    echo -e "${GREEN}  ✓ Empty migration file created. Edit it, then run migrate dev.${RESET}"
  }

  _migrate_deploy() {
    echo ""
    echo -e "${YELLOW}  Running: npx prisma migrate deploy${RESET}"
    echo -e "${DIM}  (Applies all pending migrations — use in production/CI)${RESET}"
    npx prisma migrate deploy
    echo -e "${GREEN}  ✓ All pending migrations applied.${RESET}"
  }

  _migrate_reset() {
    echo ""
    echo -e "${RED}  ⚠  This DROPS the database, re-creates it, and re-runs all migrations!${RESET}"
    echo -e "${RED}  ⚠  ALL DATA WILL BE LOST.${RESET}"
    echo -e "${RED}  Type 'yes' to confirm:${RESET}"
    read -rp "  > " RESET_CONFIRM
    [[ "$RESET_CONFIRM" != "yes" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
    npx prisma migrate reset
    echo -e "${GREEN}  ✓ Database reset complete.${RESET}"
  }

  _migrate_status() {
    echo ""
    echo -e "${BOLD}${CYAN}📋 Migration Status:${RESET}"
    npx prisma migrate status
  }

  _migrate_resolve_applied() {
    echo ""
    echo -e "${YELLOW}  Mark a failed migration as applied (use in prod after manual fix):${RESET}"
    read -rp "  Migration name (exact, e.g. 20240101_add_users): " MIG_RESOLVE
    [[ -z "$MIG_RESOLVE" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    npx prisma migrate resolve --applied "$MIG_RESOLVE"
    echo -e "${GREEN}  ✓ Migration marked as applied.${RESET}"
  }

  _migrate_resolve_rolled_back() {
    echo ""
    read -rp "  Migration name to mark as rolled back: " MIG_RESOLVE
    [[ -z "$MIG_RESOLVE" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    npx prisma migrate resolve --rolled-back "$MIG_RESOLVE"
    echo -e "${GREEN}  ✓ Migration marked as rolled back.${RESET}"
  }

  _migrate_diff() {
    echo ""
    echo -e "${BOLD}${CYAN}🔍 Schema Diff (schema vs database):${RESET}"
    echo -e "${DIM}  Shows SQL that would be run to sync schema → database${RESET}"
    npx prisma migrate diff \
      --from-schema-datamodel prisma/schema.prisma \
      --to-schema-datasource  prisma/schema.prisma \
      --script
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION C: DB PUSH / PULL
  # ════════════════════════════════════════════════════════════════

  _db_push() {
    echo ""
    echo -e "${YELLOW}  Running: npx prisma db push${RESET}"
    echo -e "${DIM}  (Syncs schema to DB without migration files — good for prototyping)${RESET}"
    npx prisma db push
    echo -e "${GREEN}  ✓ Schema pushed to database.${RESET}"
  }

  _db_push_force() {
    echo ""
    echo -e "${RED}  ⚠  --force-reset: drops database before pushing. DATA WILL BE LOST.${RESET}"
    echo -e "${RED}  Type 'yes' to confirm:${RESET}"
    read -rp "  > " FORCE_CONFIRM
    [[ "$FORCE_CONFIRM" != "yes" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
    npx prisma db push --force-reset
    echo -e "${GREEN}  ✓ Force push done.${RESET}"
  }

  _db_pull() {
    echo ""
    echo -e "${YELLOW}  Running: npx prisma db pull${RESET}"
    echo -e "${DIM}  (Introspects existing DB and updates schema.prisma — also called 'introspect')${RESET}"
    npx prisma db pull
    echo -e "${GREEN}  ✓ schema.prisma updated from database.${RESET}"
  }

  _db_execute() {
    echo ""
    read -rp "  SQL file path to execute (e.g. ./seed.sql): " SQL_FILE
    [[ -z "$SQL_FILE" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    [[ ! -f "$SQL_FILE" ]] && echo -e "${RED}  ✗ File not found.${RESET}" && return 1
    npx prisma db execute --file "$SQL_FILE" --schema prisma/schema.prisma
    echo -e "${GREEN}  ✓ SQL executed.${RESET}"
  }

  _db_seed() {
    echo ""
    echo -e "${YELLOW}  Running: npx prisma db seed${RESET}"
    echo -e "${DIM}  (Runs the seed script defined in package.json → prisma.seed)${RESET}"
    npx prisma db seed
    echo -e "${GREEN}  ✓ Seed complete.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION D: GENERATE & STUDIO
  # ════════════════════════════════════════════════════════════════

  _generate() {
    echo ""
    echo -e "${YELLOW}  Running: npx prisma generate${RESET}"
    echo -e "${DIM}  (Re-generates Prisma Client from schema.prisma)${RESET}"
    npx prisma generate
    echo -e "${GREEN}  ✓ Prisma Client generated.${RESET}"
  }

  _generate_watch() {
    echo ""
    echo -e "${YELLOW}  Running: npx prisma generate --watch${RESET}"
    echo -e "${DIM}  (Auto-regenerates on schema changes — Ctrl+C to stop)${RESET}"
    npx prisma generate --watch
  }

  _studio() {
    echo ""
    echo -e "${YELLOW}  Running: npx prisma studio${RESET}"
    echo -e "${DIM}  (Opens browser GUI to browse + edit data — Ctrl+C to stop)${RESET}"
    npx prisma studio
  }

  _studio_port() {
    echo ""
    read -rp "  Port (default 5555): " ST_PORT
    ST_PORT="${ST_PORT:-5555}"
    echo -e "${YELLOW}  Running: npx prisma studio --port ${ST_PORT}${RESET}"
    npx prisma studio --port "$ST_PORT"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION E: VALIDATE & FORMAT
  # ════════════════════════════════════════════════════════════════

  _validate() {
    echo ""
    echo -e "${YELLOW}  Running: npx prisma validate${RESET}"
    npx prisma validate
    echo -e "${GREEN}  ✓ Schema is valid.${RESET}"
  }

  _format() {
    echo ""
    echo -e "${YELLOW}  Running: npx prisma format${RESET}"
    npx prisma format
    echo -e "${GREEN}  ✓ Schema formatted.${RESET}"
  }

  _version() {
    echo ""
    npx prisma version
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION F: INSTALL
  # ════════════════════════════════════════════════════════════════

  _install_prisma() {
    echo ""
    echo -e "${YELLOW}  Installing Prisma CLI + Client...${RESET}"
    npm install prisma --save-dev
    npm install @prisma/client
    echo -e "${GREEN}  ✓ Installed.${RESET}"
  }

  _install_ts() {
    echo ""
    echo -e "${YELLOW}  Installing TypeScript + ts-node + Prisma...${RESET}"
    npm install prisma --save-dev
    npm install @prisma/client
    npm install typescript ts-node @types/node --save-dev
    echo -e "${GREEN}  ✓ Full TypeScript + Prisma stack installed.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # MAIN MENU LOOP
  # ════════════════════════════════════════════════════════════════
  while true; do
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║        ▲  prismatools — Prisma Interactive Toolkit           ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ SETUP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN} 1)${RESET} 📦  Install Prisma            ${DIM}-- npm install prisma @prisma/client${RESET}"
    echo -e "  ${GREEN} 2)${RESET} 📦  Install Prisma + TS       ${DIM}-- + typescript ts-node @types/node${RESET}"
    echo -e "  ${GREEN} 3)${RESET} 🚀  Init (choose provider)    ${DIM}-- npx prisma init --datasource-provider postgresql${RESET}"
    echo -e "  ${GREEN} 4)${RESET} 🚀  Init with URL             ${DIM}-- npx prisma init --url \$DATABASE_URL${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ MIGRATE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN} 5)${RESET} 🔄  migrate dev               ${DIM}-- npx prisma migrate dev --name <name>${RESET}"
    echo -e "  ${GREEN} 6)${RESET} 📝  migrate dev --create-only ${DIM}-- creates empty migration file${RESET}"
    echo -e "  ${GREEN} 7)${RESET} 🚢  migrate deploy            ${DIM}-- npx prisma migrate deploy  (production)${RESET}"
    echo -e "  ${RED} 8)${RESET} 💥  migrate reset  ⚠          ${DIM}-- drops DB + re-runs all migrations${RESET}"
    echo -e "  ${GREEN} 9)${RESET} 📋  migrate status            ${DIM}-- npx prisma migrate status${RESET}"
    echo -e "  ${GREEN}10)${RESET} ✅  migrate resolve --applied ${DIM}-- mark failed migration as applied${RESET}"
    echo -e "  ${GREEN}11)${RESET} 🔙  migrate resolve --rolled  ${DIM}-- mark migration as rolled back${RESET}"
    echo -e "  ${GREEN}12)${RESET} 🔍  migrate diff              ${DIM}-- shows SQL diff schema vs database${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ DB PUSH / PULL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}13)${RESET} ⬆️   db push                  ${DIM}-- npx prisma db push  (no migration files)${RESET}"
    echo -e "  ${RED}14)${RESET} ⬆️   db push --force-reset ⚠   ${DIM}-- drops DB first, then pushes schema${RESET}"
    echo -e "  ${GREEN}15)${RESET} ⬇️   db pull (introspect)      ${DIM}-- npx prisma db pull  (DB → schema.prisma)${RESET}"
    echo -e "  ${GREEN}16)${RESET} 💻  db execute (SQL file)     ${DIM}-- npx prisma db execute --file ./seed.sql${RESET}"
    echo -e "  ${GREEN}17)${RESET} 🌱  db seed                   ${DIM}-- npx prisma db seed${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ GENERATE & STUDIO ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}18)${RESET} ⚙️   generate                  ${DIM}-- npx prisma generate${RESET}"
    echo -e "  ${GREEN}19)${RESET} 👀  generate --watch           ${DIM}-- auto-regenerate on save${RESET}"
    echo -e "  ${GREEN}20)${RESET} 🖥   studio                    ${DIM}-- npx prisma studio  (browser GUI)${RESET}"
    echo -e "  ${GREEN}21)${RESET} 🖥   studio --port             ${DIM}-- npx prisma studio --port 5555${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ VALIDATE & FORMAT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}22)${RESET} ✅  validate                  ${DIM}-- npx prisma validate${RESET}"
    echo -e "  ${GREEN}23)${RESET} 🎨  format                    ${DIM}-- npx prisma format${RESET}"
    echo -e "  ${GREEN}24)${RESET} ℹ️   version                   ${DIM}-- npx prisma version${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ CHEATSHEET ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${CYAN}25)${RESET} 📖  Full cheatsheet           ${DIM}-- prismahelp${RESET}"
    echo -e "  ${CYAN}26)${RESET} 📖  Schema + field types      ${DIM}-- schema reference${RESET}"
    echo -e "  ${CYAN}27)${RESET} 📖  Relationships guide       ${DIM}-- 1:1 / 1:N / M:N${RESET}"
    echo -e "  ${CYAN}28)${RESET} 📖  Client query cheatsheet   ${DIM}-- findMany/create/update/delete${RESET}"
    echo ""
    echo -e "  ${RED} 0)${RESET} 🚪  Exit"
    echo ""
    read -rp "  Choose option [0-28]: " CHOICE

    echo ""
    case "$CHOICE" in
       1) _install_prisma ;;
       2) _install_ts ;;
       3) _prisma_init ;;
       4) _prisma_init_url ;;
       5) _migrate_dev ;;
       6) _migrate_dev_blank ;;
       7) _migrate_deploy ;;
       8) _migrate_reset ;;
       9) _migrate_status ;;
      10) _migrate_resolve_applied ;;
      11) _migrate_resolve_rolled_back ;;
      12) _migrate_diff ;;
      13) _db_push ;;
      14) _db_push_force ;;
      15) _db_pull ;;
      16) _db_execute ;;
      17) _db_seed ;;
      18) _generate ;;
      19) _generate_watch ;;
      20) _studio ;;
      21) _studio_port ;;
      22) _validate ;;
      23) _format ;;
      24) _version ;;
      25) prismahelp ;;
      26) prismahelp_schema ;;
      27) prismahelp_relations ;;
      28) prismahelp_client ;;
       0) echo -e "${CYAN}  Goodbye! ▲${RESET}"; echo ""; return 0 ;;
       *) echo -e "${RED}  ✗ Invalid option. Choose 0-28.${RESET}" ;;
    esac

    echo ""
    read -rp "  Press Enter to return to menu..." _PAUSE
  done
}


# =================================================================
# prismahelp — Full cheatsheet dispatcher
# =================================================================
prismahelp() {
  prismahelp_commands
  prismahelp_schema
  prismahelp_relations
  prismahelp_client
}


# =================================================================
# prismahelp_commands — All CLI Commands
# =================================================================
prismahelp_commands() {
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local MAGENTA='\033[0;35m'
  local RESET='\033[0m'
  local DIV="${DIM}────────────────────────────────────────────────────────────────────────${RESET}"

  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║        ▲  Prisma CLI — Full Command Reference                ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "  ${BOLD}${YELLOW}» Install${RESET}"
  echo -e "  ${GREEN}npm install prisma --save-dev${RESET}                    ${DIM}# Prisma CLI (dev dependency)${RESET}"
  echo -e "  ${GREEN}npm install @prisma/client${RESET}                       ${DIM}# Prisma Client (runtime)${RESET}"
  echo -e "  ${GREEN}npm install typescript ts-node @types/node --save-dev${RESET}  ${DIM}# TypeScript support${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Init${RESET}"
  echo -e "  ${GREEN}npx prisma init${RESET}                                  ${DIM}# Creates prisma/schema.prisma + .env${RESET}"
  echo -e "  ${GREEN}npx prisma init --datasource-provider postgresql${RESET} ${DIM}# Init with specific DB${RESET}"
  echo -e "  ${GREEN}npx prisma init --datasource-provider sqlite${RESET}     ${DIM}# SQLite (no server needed)${RESET}"
  echo -e "  ${GREEN}npx prisma init --url \$DATABASE_URL${RESET}              ${DIM}# Init with connection string${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Generate${RESET}"
  echo -e "  ${GREEN}npx prisma generate${RESET}                              ${DIM}# Generate Prisma Client from schema${RESET}"
  echo -e "  ${GREEN}npx prisma generate --watch${RESET}                      ${DIM}# Auto-regenerate on schema changes${RESET}"
  echo -e "  ${GREEN}npx prisma generate --schema=./custom/schema.prisma${RESET} ${DIM}# Custom schema path${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Migrate (Development)${RESET}"
  echo -e "  ${GREEN}npx prisma migrate dev --name init${RESET}               ${DIM}# Create + apply migration (dev)${RESET}"
  echo -e "  ${GREEN}npx prisma migrate dev --name add_user_table${RESET}     ${DIM}# Descriptive migration name${RESET}"
  echo -e "  ${GREEN}npx prisma migrate dev --create-only --name xyz${RESET}  ${DIM}# Only create file, don't apply yet${RESET}"
  echo -e "  ${GREEN}npx prisma migrate dev --skip-generate${RESET}           ${DIM}# Skip client regeneration after migrate${RESET}"
  echo -e "  ${GREEN}npx prisma migrate dev --skip-seed${RESET}               ${DIM}# Skip seeding after migrate${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Migrate (Production / CI)${RESET}"
  echo -e "  ${GREEN}npx prisma migrate deploy${RESET}                        ${DIM}# Apply all pending migrations (prod)${RESET}"
  echo -e "  ${GREEN}npx prisma migrate status${RESET}                        ${DIM}# Show which migrations are applied${RESET}"
  echo -e "  ${GREEN}npx prisma migrate diff --from-schema-datamodel ... --to-schema-datasource ... --script${RESET}"
  echo -e "                                                           ${DIM}# Show SQL diff between schema + DB${RESET}"
  echo -e "  ${RED}npx prisma migrate reset${RESET}                         ${DIM}# ⚠  DROP + recreate DB + re-run all${RESET}"
  echo -e "  ${RED}npx prisma migrate reset --skip-seed${RESET}             ${DIM}# ⚠  Same but skip seeding${RESET}"
  echo -e "  ${GREEN}npx prisma migrate resolve --applied <name>${RESET}      ${DIM}# Mark migration as applied (after manual fix)${RESET}"
  echo -e "  ${GREEN}npx prisma migrate resolve --rolled-back <name>${RESET}  ${DIM}# Mark migration as rolled back${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» DB Push / Pull (no migration files)${RESET}"
  echo -e "  ${GREEN}npx prisma db push${RESET}                               ${DIM}# Push schema → DB directly (prototyping)${RESET}"
  echo -e "  ${GREEN}npx prisma db push --accept-data-loss${RESET}            ${DIM}# Allow destructive changes${RESET}"
  echo -e "  ${RED}npx prisma db push --force-reset${RESET}                 ${DIM}# ⚠  Drop DB first, then push${RESET}"
  echo -e "  ${GREEN}npx prisma db pull${RESET}                               ${DIM}# Introspect DB → update schema.prisma${RESET}"
  echo -e "  ${GREEN}npx prisma db execute --file ./seed.sql --schema prisma/schema.prisma${RESET}"
  echo -e "                                                           ${DIM}# Run raw SQL file against DB${RESET}"
  echo -e "  ${GREEN}npx prisma db seed${RESET}                               ${DIM}# Run seed script (package.json → prisma.seed)${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Studio${RESET}"
  echo -e "  ${GREEN}npx prisma studio${RESET}                                ${DIM}# Open browser GUI on localhost:5555${RESET}"
  echo -e "  ${GREEN}npx prisma studio --port 4000${RESET}                    ${DIM}# Custom port${RESET}"
  echo -e "  ${GREEN}npx prisma studio --browser none${RESET}                 ${DIM}# Don't open browser automatically${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Validate & Format${RESET}"
  echo -e "  ${GREEN}npx prisma validate${RESET}                              ${DIM}# Check schema for errors${RESET}"
  echo -e "  ${GREEN}npx prisma format${RESET}                                ${DIM}# Auto-format schema.prisma${RESET}"
  echo -e "  ${GREEN}npx prisma version${RESET}                               ${DIM}# Show Prisma + engine versions${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Typical Workflows${RESET}"
  echo ""
  echo -e "  ${CYAN}── New Project (Dev) ─────────────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}npm install prisma --save-dev && npm install @prisma/client${RESET}"
  echo -e "  ${GREEN}npx prisma init --datasource-provider postgresql${RESET}"
  echo -e "  ${DIM}  # Edit .env → DATABASE_URL, edit prisma/schema.prisma${RESET}"
  echo -e "  ${GREEN}npx prisma migrate dev --name init${RESET}"
  echo -e "  ${GREEN}npx prisma generate${RESET}"
  echo ""
  echo -e "  ${CYAN}── Existing DB (Introspect) ──────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}npx prisma init${RESET}"
  echo -e "  ${DIM}  # Set DATABASE_URL in .env${RESET}"
  echo -e "  ${GREEN}npx prisma db pull${RESET}           ${DIM}# Generates schema from existing DB${RESET}"
  echo -e "  ${GREEN}npx prisma generate${RESET}"
  echo ""
  echo -e "  ${CYAN}── Deploy to Production ─────────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}npx prisma migrate deploy${RESET}    ${DIM}# Apply pending migrations (safe, no data loss)${RESET}"
  echo -e "  ${GREEN}npx prisma generate${RESET}          ${DIM}# Regenerate client${RESET}"
  echo ""
  echo -e "  ${CYAN}── Prototype / Rapid Dev ────────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}npx prisma db push${RESET}           ${DIM}# No migration files; schema → DB directly${RESET}"
  echo -e "  ${GREEN}npx prisma db push${RESET}           ${DIM}# Keep pushing on each schema change${RESET}"
  echo -e "  ${DIM}  # When ready to commit: run migrate dev to create migration history${RESET}"
  echo ""
  echo -e "  ${CYAN}── Seeding ──────────────────────────────────────────────────────${RESET}"
  echo -e "  ${DIM}  # In package.json:${RESET}"
  echo -e "  ${GREEN}  \"prisma\": { \"seed\": \"ts-node prisma/seed.ts\" }${RESET}"
  echo -e "  ${GREEN}npx prisma db seed${RESET}"
  echo ""
}


# =================================================================
# prismahelp_schema — Schema syntax + field types + attributes
# =================================================================
prismahelp_schema() {
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local MAGENTA='\033[0;35m'
  local RESET='\033[0m'
  local DIV="${DIM}────────────────────────────────────────────────────────────────────────${RESET}"

  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║        ▲  Prisma Schema — Field Types & Attributes           ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "  ${BOLD}${YELLOW}» Full schema.prisma Structure${RESET}"
  echo ""
  echo -e "  ${DIM}// ── datasource (top of file) ────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}datasource db {${RESET}"
  echo -e "  ${GREEN}  provider = \"postgresql\"   ${DIM}// postgresql | mysql | sqlite | mongodb | sqlserver${RESET}"
  echo -e "  ${GREEN}  url      = env(\"DATABASE_URL\")${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${DIM}// ── generator (Prisma Client) ────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}generator client {${RESET}"
  echo -e "  ${GREEN}  provider = \"prisma-client-js\"${RESET}"
  echo -e "  ${GREEN}  // output = \"../src/generated/client\"  ${DIM}// custom output path${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${DIM}// ── model ────────────────────────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}model User {${RESET}"
  echo -e "  ${GREEN}  id        Int      @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  uuid      String   @id @default(uuid())           ${DIM}// or use uuid${RESET}"
  echo -e "  ${GREEN}  cuid      String   @id @default(cuid())           ${DIM}// or cuid${RESET}"
  echo -e "  ${GREEN}  name      String${RESET}"
  echo -e "  ${GREEN}  email     String   @unique${RESET}"
  echo -e "  ${GREEN}  age       Int?                                    ${DIM}// ? = optional (nullable)${RESET}"
  echo -e "  ${GREEN}  bio       String?  @db.Text                       ${DIM}// @db.Text = unlimited length${RESET}"
  echo -e "  ${GREEN}  score     Float    @default(0.0)${RESET}"
  echo -e "  ${GREEN}  isActive  Boolean  @default(true)${RESET}"
  echo -e "  ${GREEN}  role      Role     @default(USER)                 ${DIM}// enum type${RESET}"
  echo -e "  ${GREEN}  createdAt DateTime @default(now())${RESET}"
  echo -e "  ${GREEN}  updatedAt DateTime @updatedAt                     ${DIM}// auto-updates on every save${RESET}"
  echo -e "  ${GREEN}  data      Json?                                   ${DIM}// store any JSON${RESET}"
  echo -e "  ${GREEN}  bytes     Bytes?                                  ${DIM}// binary data${RESET}"
  echo ""
  echo -e "  ${DIM}  // ── Block-level attributes ────────────────────────────────────${RESET}"
  echo -e "  ${DIM}  // @@unique([name, email])     → composite unique (name+email combo)${RESET}"
  echo -e "  ${DIM}  // @@index([email])            → index for faster search on email${RESET}"
  echo -e "  ${DIM}  // @@index([name, createdAt])  → composite index${RESET}"
  echo -e "  ${DIM}  // @@id([name, email])         → composite primary key (no id field)${RESET}"
  echo -e "  ${DIM}  // @@map(\"users\")              → map model to table named 'users'${RESET}"
  echo -e "  ${GREEN}  @@unique([name, email])${RESET}"
  echo -e "  ${GREEN}  @@index([email])${RESET}"
  echo -e "  ${GREEN}  @@map(\"users\")${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${DIM}// ── enum ─────────────────────────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}enum Role {${RESET}"
  echo -e "  ${GREEN}  USER${RESET}"
  echo -e "  ${GREEN}  ADMIN${RESET}"
  echo -e "  ${GREEN}  MODERATOR${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Field Types${RESET}"
  echo ""
  printf "  ${GREEN}%-14s${RESET} ${DIM}%s${RESET}\n" "String"    "VARCHAR — text, email, name, slug"
  printf "  ${GREEN}%-14s${RESET} ${DIM}%s${RESET}\n" "Int"       "INTEGER — whole numbers, IDs, counts"
  printf "  ${GREEN}%-14s${RESET} ${DIM}%s${RESET}\n" "BigInt"    "BIGINT — large integers (use n suffix: 9007199254740991n)"
  printf "  ${GREEN}%-14s${RESET} ${DIM}%s${RESET}\n" "Float"     "FLOAT — decimal numbers (less precise)"
  printf "  ${GREEN}%-14s${RESET} ${DIM}%s${RESET}\n" "Decimal"   "DECIMAL — exact decimals (money, prices)"
  printf "  ${GREEN}%-14s${RESET} ${DIM}%s${RESET}\n" "Boolean"   "BOOLEAN — true / false"
  printf "  ${GREEN}%-14s${RESET} ${DIM}%s${RESET}\n" "DateTime"  "TIMESTAMP — dates and times"
  printf "  ${GREEN}%-14s${RESET} ${DIM}%s${RESET}\n" "Json"      "JSON — store objects/arrays as JSON"
  printf "  ${GREEN}%-14s${RESET} ${DIM}%s${RESET}\n" "Bytes"     "BYTEA — binary data, file blobs"
  printf "  ${GREEN}%-14s${RESET} ${DIM}%s${RESET}\n" "Unsupported" "raw DB type not supported by Prisma"
  echo ""
  echo -e "  ${DIM}  Tip: Add ? to make nullable → String? Int? DateTime?${RESET}"
  echo -e "  ${DIM}  Add [] to make array (MongoDB only) → String[] Int[]${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Field Attributes (@)${RESET}"
  echo ""
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@id"                          "Primary key"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@default(autoincrement())"    "Auto-increment integer PK"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@default(uuid())"             "UUID string PK"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@default(cuid())"             "CUID string PK"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@default(now())"              "Current timestamp on create"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@default(true)"               "Default boolean"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@default(0)"                  "Default number"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@default(\"\")"               "Default empty string"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@updatedAt"                   "Auto-set to now() on every update"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@unique"                      "Unique constraint on this field"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@map(\"column_name\")"        "Map field to different DB column name"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@ignore"                      "Exclude from Prisma Client (but keep in DB)"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@db.Text"                     "Map to TEXT type (unlimited length)"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@db.VarChar(255)"             "Map to VARCHAR(255)"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@db.SmallInt"                 "Map to SMALLINT"
  printf "  ${GREEN}%-35s${RESET} ${DIM}%s${RESET}\n" "@relation(...)"               "Define relation (see relations guide)"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Block Attributes (@@)${RESET}"
  echo ""
  printf "  ${GREEN}%-40s${RESET} ${DIM}%s${RESET}\n" "@@id([field1, field2])"             "Composite primary key"
  printf "  ${GREEN}%-40s${RESET} ${DIM}%s${RESET}\n" "@@unique([field1, field2])"          "Composite unique constraint"
  printf "  ${GREEN}%-40s${RESET} ${DIM}%s${RESET}\n" "@@index([field1, field2])"           "Composite index for fast lookup"
  printf "  ${GREEN}%-40s${RESET} ${DIM}%s${RESET}\n" "@@index([email(ops: TextOps)])"      "Index with ops (full-text search)"
  printf "  ${GREEN}%-40s${RESET} ${DIM}%s${RESET}\n" "@@map(\"table_name\")"               "Map model to custom table name"
  printf "  ${GREEN}%-40s${RESET} ${DIM}%s${RESET}\n" "@@ignore"                            "Exclude model from Prisma Client"
  echo ""
}


# =================================================================
# prismahelp_relations — All relationship types with full examples
# =================================================================
prismahelp_relations() {
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local MAGENTA='\033[0;35m'
  local RED='\033[0;31m'
  local RESET='\033[0m'
  local DIV="${DIM}────────────────────────────────────────────────────────────────────────${RESET}"

  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║        ▲  Prisma — All Relationship Types                    ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  # ── 1:1 ────────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» 1. One-to-One (1:1)${RESET}  ${DIM}← User has one Profile, Profile belongs to one User${RESET}"
  echo ""
  echo -e "  ${GREEN}model User {${RESET}"
  echo -e "  ${GREEN}  id      Int      @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  name    String${RESET}"
  echo -e "  ${GREEN}  profile Profile? ${DIM}// optional: user might not have a profile yet${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${GREEN}model Profile {${RESET}"
  echo -e "  ${GREEN}  id     Int    @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  bio    String${RESET}"
  echo -e "  ${GREEN}  userId Int    @unique           ${DIM}// @unique enforces 1:1 (not 1:many)${RESET}"
  echo -e "  ${GREEN}  user   User   @relation(fields: [userId], references: [id])${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${DIM}  // Rule: Foreign key (userId) lives on Profile (the 'child' side)${RESET}"
  echo -e "  ${DIM}  // @unique on userId ensures one user can only have one profile${RESET}"
  echo -e "  ${DIM}  // User side has Profile? (optional — user exists without profile)${RESET}"
  echo -e "$DIV"

  # ── 1:N ────────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» 2. One-to-Many (1:N)${RESET}  ${DIM}← User has many Posts, Post belongs to one User${RESET}"
  echo ""
  echo -e "  ${GREEN}model User {${RESET}"
  echo -e "  ${GREEN}  id    Int    @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  name  String${RESET}"
  echo -e "  ${GREEN}  posts Post[] ${DIM}// array = many${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${GREEN}model Post {${RESET}"
  echo -e "  ${GREEN}  id       Int    @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  title    String${RESET}"
  echo -e "  ${GREEN}  authorId Int${RESET}"
  echo -e "  ${GREEN}  author   User   @relation(fields: [authorId], references: [id])${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${DIM}  // Rule: Foreign key (authorId) always lives on the 'many' side (Post)${RESET}"
  echo -e "  ${DIM}  // User side has Post[] (array = can have many)${RESET}"
  echo -e "  ${DIM}  // No @unique on authorId (many posts can have same authorId)${RESET}"
  echo -e "$DIV"

  # ── M:N ────────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» 3. Many-to-Many (M:N) — Implicit${RESET}  ${DIM}← Post has many Tags, Tag has many Posts${RESET}"
  echo ""
  echo -e "  ${GREEN}model Post {${RESET}"
  echo -e "  ${GREEN}  id    Int    @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  title String${RESET}"
  echo -e "  ${GREEN}  tags  Tag[]  ${DIM}// no @relation needed — Prisma handles join table automatically${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${GREEN}model Tag {${RESET}"
  echo -e "  ${GREEN}  id    Int    @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  name  String @unique${RESET}"
  echo -e "  ${GREEN}  posts Post[]${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${DIM}  // Prisma auto-creates hidden join table _PostToTag in DB${RESET}"
  echo -e "  ${DIM}  // Use this when join table needs NO extra fields${RESET}"
  echo -e "$DIV"

  # ── M:N Explicit ───────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» 4. Many-to-Many (M:N) — Explicit Join Table${RESET}"
  echo -e "     ${DIM}← When join table needs extra fields (e.g. enrolledAt, role)${RESET}"
  echo ""
  echo -e "  ${GREEN}model Student {${RESET}"
  echo -e "  ${GREEN}  id        Int          @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  name      String${RESET}"
  echo -e "  ${GREEN}  courses   Enrollment[] ${DIM}// through join model${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${GREEN}model Course {${RESET}"
  echo -e "  ${GREEN}  id       Int          @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  title    String${RESET}"
  echo -e "  ${GREEN}  students Enrollment[]${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${GREEN}model Enrollment {            ${DIM}// ← explicit join table${RESET}"
  echo -e "  ${GREEN}  id         Int      @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  enrolledAt DateTime @default(now()) ${DIM}// extra field on join${RESET}"
  echo -e "  ${GREEN}  grade      String?                  ${DIM}// another extra field${RESET}"
  echo -e "  ${GREEN}  studentId  Int${RESET}"
  echo -e "  ${GREEN}  courseId   Int${RESET}"
  echo -e "  ${GREEN}  student    Student  @relation(fields: [studentId], references: [id])${RESET}"
  echo -e "  ${GREEN}  course     Course   @relation(fields: [courseId], references: [id])${RESET}"
  echo ""
  echo -e "  ${DIM}  // @@unique([studentId, courseId])  → prevent duplicate enrollment${RESET}"
  echo -e "  ${GREEN}  @@unique([studentId, courseId])${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo -e "$DIV"

  # ── Self-referential ───────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» 5. Self-Referential${RESET}  ${DIM}← Category has sub-categories, Employee has manager${RESET}"
  echo ""
  echo -e "  ${GREEN}model Category {${RESET}"
  echo -e "  ${GREEN}  id         Int        @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  name       String${RESET}"
  echo -e "  ${GREEN}  parentId   Int?                                    ${DIM}// null = root category${RESET}"
  echo -e "  ${GREEN}  parent     Category?  @relation(\"SubCategories\", fields: [parentId], references: [id])${RESET}"
  echo -e "  ${GREEN}  children   Category[] @relation(\"SubCategories\") ${DIM}// sub-categories${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${DIM}  // Named relation (\"SubCategories\") required to distinguish the two sides${RESET}"
  echo -e "$DIV"

  # ── Multiple relations between same models ─────────────────────
  echo -e "  ${BOLD}${YELLOW}» 6. Multiple Relations Between Same Models${RESET}"
  echo -e "     ${DIM}← User writes Posts AND likes Posts${RESET}"
  echo ""
  echo -e "  ${GREEN}model User {${RESET}"
  echo -e "  ${GREEN}  id           Int    @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  writtenPosts Post[] @relation(\"WrittenPosts\")${RESET}"
  echo -e "  ${GREEN}  likedPosts   Post[] @relation(\"LikedPosts\")${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${GREEN}model Post {${RESET}"
  echo -e "  ${GREEN}  id        Int  @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  title     String${RESET}"
  echo -e "  ${GREEN}  authorId  Int${RESET}"
  echo -e "  ${GREEN}  author    User @relation(\"WrittenPosts\", fields: [authorId],  references: [id])${RESET}"
  echo -e "  ${GREEN}  likedById Int?${RESET}"
  echo -e "  ${GREEN}  likedBy   User? @relation(\"LikedPosts\",   fields: [likedById], references: [id])${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${DIM}  // Named relations required when 2+ relations exist between same models${RESET}"
  echo -e "$DIV"

  # ── onDelete / onUpdate ────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» 7. Referential Actions (onDelete / onUpdate)${RESET}"
  echo ""
  echo -e "  ${GREEN}model Post {${RESET}"
  echo -e "  ${GREEN}  id       Int  @id @default(autoincrement())${RESET}"
  echo -e "  ${GREEN}  authorId Int${RESET}"
  echo -e "  ${GREEN}  author   User @relation(fields: [authorId], references: [id],${RESET}"
  echo -e "  ${GREEN}                            onDelete: Cascade,  ${DIM}// delete post when user deleted${RESET}"
  echo -e "  ${GREEN}                            onUpdate: Cascade)  ${DIM}// update FK when user id changes${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  printf "  ${GREEN}%-18s${RESET} ${DIM}%s${RESET}\n" "Cascade"      "Delete/update child records when parent deleted/updated"
  printf "  ${GREEN}%-18s${RESET} ${DIM}%s${RESET}\n" "Restrict"     "Block delete/update if related records exist"
  printf "  ${GREEN}%-18s${RESET} ${DIM}%s${RESET}\n" "SetNull"      "Set FK to NULL when parent deleted (FK must be nullable)"
  printf "  ${GREEN}%-18s${RESET} ${DIM}%s${RESET}\n" "SetDefault"   "Set FK to @default value when parent deleted"
  printf "  ${GREEN}%-18s${RESET} ${DIM}%s${RESET}\n" "NoAction"     "Do nothing — DB handles it (or throws error)"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Quick Reference: Which side gets the FK?${RESET}"
  echo ""
  echo -e "  ${CYAN}Relation Type     FK Location               Example${RESET}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────${RESET}"
  printf "  ${GREEN}%-18s${RESET} %-24s %s\n" "1:1"          "child model   "         "profileId on Profile"
  printf "  ${GREEN}%-18s${RESET} %-24s %s\n" "1:N"          "many side     "         "authorId on Post"
  printf "  ${GREEN}%-18s${RESET} %-24s %s\n" "M:N implicit" "Prisma auto join table" "_PostToTag (hidden)"
  printf "  ${GREEN}%-18s${RESET} %-24s %s\n" "M:N explicit" "join model    "         "studentId+courseId on Enrollment"
  printf "  ${GREEN}%-18s${RESET} %-24s %s\n" "Self-ref"     "same model    "         "parentId on Category"
  echo ""
}


# =================================================================
# prismahelp_client — Prisma Client query cheatsheet
# =================================================================
prismahelp_client() {
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local MAGENTA='\033[0;35m'
  local RESET='\033[0m'
  local DIV="${DIM}────────────────────────────────────────────────────────────────────────${RESET}"

  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║        ▲  Prisma Client — Query Cheatsheet                   ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "  ${BOLD}${YELLOW}» Setup (import in your file)${RESET}"
  echo ""
  echo -e "  ${GREEN}import { PrismaClient } from '@prisma/client'${RESET}"
  echo -e "  ${GREEN}const prisma = new PrismaClient()${RESET}"
  echo -e "$DIV"

  # ── findMany ───────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» READ — findMany${RESET}"
  echo ""
  echo -e "  ${DIM}// Get all users${RESET}"
  echo -e "  ${GREEN}const users = await prisma.user.findMany()${RESET}"
  echo ""
  echo -e "  ${DIM}// Filter + sort + paginate${RESET}"
  echo -e "  ${GREEN}const users = await prisma.user.findMany({${RESET}"
  echo -e "  ${GREEN}  where:   { isActive: true, role: 'ADMIN' },${RESET}"
  echo -e "  ${GREEN}  orderBy: { createdAt: 'desc' },            ${DIM}// 'asc' | 'desc'${RESET}"
  echo -e "  ${GREEN}  take:    10,                               ${DIM}// LIMIT 10${RESET}"
  echo -e "  ${GREEN}  skip:    20,                               ${DIM}// OFFSET 20 (page 3)${RESET}"
  echo -e "  ${GREEN}  select:  { id: true, name: true, email: true }, ${DIM}// only these fields${RESET}"
  echo -e "  ${GREEN}})"
  echo ""
  echo -e "  ${DIM}// With relations (include)${RESET}"
  echo -e "  ${GREEN}const users = await prisma.user.findMany({${RESET}"
  echo -e "  ${GREEN}  include: {${RESET}"
  echo -e "  ${GREEN}    posts:   true,                           ${DIM}// include all posts${RESET}"
  echo -e "  ${GREEN}    profile: true,${RESET}"
  echo -e "  ${GREEN}  }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// Nested include (posts + their comments)${RESET}"
  echo -e "  ${GREEN}const users = await prisma.user.findMany({${RESET}"
  echo -e "  ${GREEN}  include: {${RESET}"
  echo -e "  ${GREEN}    posts: { include: { comments: true } }${RESET}"
  echo -e "  ${GREEN}  }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo -e "$DIV"

  # ── findUnique / findFirst ─────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» READ — findUnique / findFirst${RESET}"
  echo ""
  echo -e "  ${DIM}// findUnique — must use @id or @unique field${RESET}"
  echo -e "  ${GREEN}const user = await prisma.user.findUnique({${RESET}"
  echo -e "  ${GREEN}  where: { id: 1 }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${GREEN}const user = await prisma.user.findUnique({${RESET}"
  echo -e "  ${GREEN}  where: { email: 'user@example.com' }       ${DIM}// email has @unique${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// findFirst — finds first match (any field)${RESET}"
  echo -e "  ${GREEN}const user = await prisma.user.findFirst({${RESET}"
  echo -e "  ${GREEN}  where:   { name: { contains: 'John' } },${RESET}"
  echo -e "  ${GREEN}  orderBy: { createdAt: 'desc' }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo -e "$DIV"

  # ── WHERE filters ──────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» WHERE Filters${RESET}"
  echo ""
  echo -e "  ${GREEN}where: { name: 'Alice' }                     ${DIM}// equals${RESET}"
  echo -e "  ${GREEN}where: { name: { not: 'Alice' } }            ${DIM}// not equals${RESET}"
  echo -e "  ${GREEN}where: { name: { in:    ['Alice','Bob'] } }  ${DIM}// IN list${RESET}"
  echo -e "  ${GREEN}where: { name: { notIn: ['Alice','Bob'] } }  ${DIM}// NOT IN list${RESET}"
  echo -e "  ${GREEN}where: { name: { contains:   'ali' } }       ${DIM}// LIKE %ali%${RESET}"
  echo -e "  ${GREEN}where: { name: { startsWith: 'Ali' } }       ${DIM}// LIKE Ali%${RESET}"
  echo -e "  ${GREEN}where: { name: { endsWith:   'ce' } }        ${DIM}// LIKE %ce${RESET}"
  echo -e "  ${GREEN}where: { age:  { gt: 18 } }                  ${DIM}// > 18${RESET}"
  echo -e "  ${GREEN}where: { age:  { gte: 18 } }                 ${DIM}// >= 18${RESET}"
  echo -e "  ${GREEN}where: { age:  { lt: 65 } }                  ${DIM}// < 65${RESET}"
  echo -e "  ${GREEN}where: { age:  { lte: 65 } }                 ${DIM}// <= 65${RESET}"
  echo -e "  ${GREEN}where: { bio:  { isSet: true } }             ${DIM}// field is not null${RESET}"
  echo ""
  echo -e "  ${DIM}// AND / OR / NOT${RESET}"
  echo -e "  ${GREEN}where: { AND: [ { age: { gte: 18 } }, { isActive: true } ] }${RESET}"
  echo -e "  ${GREEN}where: { OR:  [ { role: 'ADMIN' },   { role: 'MOD' } ] }${RESET}"
  echo -e "  ${GREEN}where: { NOT: { email: { contains: 'spam' } } }${RESET}"
  echo ""
  echo -e "  ${DIM}// Relation filter${RESET}"
  echo -e "  ${GREEN}where: { posts: { some: { published: true } } }  ${DIM}// user has at least one published post${RESET}"
  echo -e "  ${GREEN}where: { posts: { every: { published: true } } } ${DIM}// all posts are published${RESET}"
  echo -e "  ${GREEN}where: { posts: { none: { published: false } } } ${DIM}// no unpublished posts${RESET}"
  echo -e "$DIV"

  # ── create ─────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» CREATE${RESET}"
  echo ""
  echo -e "  ${DIM}// Create one record${RESET}"
  echo -e "  ${GREEN}const user = await prisma.user.create({${RESET}"
  echo -e "  ${GREEN}  data: { name: 'Alice', email: 'alice@example.com' }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// Create with nested relation (create user + profile together)${RESET}"
  echo -e "  ${GREEN}const user = await prisma.user.create({${RESET}"
  echo -e "  ${GREEN}  data: {${RESET}"
  echo -e "  ${GREEN}    name:    'Alice',${RESET}"
  echo -e "  ${GREEN}    email:   'alice@example.com',${RESET}"
  echo -e "  ${GREEN}    profile: { create: { bio: 'Hello world' } }  ${DIM}// nested create${RESET}"
  echo -e "  ${GREEN}  }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// Create many (bulk insert — no return data)${RESET}"
  echo -e "  ${GREEN}await prisma.user.createMany({${RESET}"
  echo -e "  ${GREEN}  data: [${RESET}"
  echo -e "  ${GREEN}    { name: 'Alice', email: 'a@ex.com' },${RESET}"
  echo -e "  ${GREEN}    { name: 'Bob',   email: 'b@ex.com' },${RESET}"
  echo -e "  ${GREEN}  ],${RESET}"
  echo -e "  ${GREEN}  skipDuplicates: true,  ${DIM}// skip if unique constraint fails${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo -e "$DIV"

  # ── update ─────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» UPDATE${RESET}"
  echo ""
  echo -e "  ${DIM}// Update one (must use @id or @unique in where)${RESET}"
  echo -e "  ${GREEN}const updated = await prisma.user.update({${RESET}"
  echo -e "  ${GREEN}  where: { id: 1 },${RESET}"
  echo -e "  ${GREEN}  data:  { name: 'Alice Smith' }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// Increment / Decrement a number field${RESET}"
  echo -e "  ${GREEN}await prisma.user.update({${RESET}"
  echo -e "  ${GREEN}  where: { id: 1 },${RESET}"
  echo -e "  ${GREEN}  data:  { score: { increment: 10 } }  ${DIM}// also: decrement, multiply, divide${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// Update many (returns count)${RESET}"
  echo -e "  ${GREEN}const { count } = await prisma.user.updateMany({${RESET}"
  echo -e "  ${GREEN}  where: { isActive: false },${RESET}"
  echo -e "  ${GREEN}  data:  { role: 'BANNED' }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// Upsert (create if not exists, update if exists)${RESET}"
  echo -e "  ${GREEN}const user = await prisma.user.upsert({${RESET}"
  echo -e "  ${GREEN}  where:  { email: 'alice@example.com' },${RESET}"
  echo -e "  ${GREEN}  create: { name: 'Alice', email: 'alice@example.com' },${RESET}"
  echo -e "  ${GREEN}  update: { name: 'Alice Updated' }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo -e "$DIV"

  # ── delete ─────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» DELETE${RESET}"
  echo ""
  echo -e "  ${DIM}// Delete one${RESET}"
  echo -e "  ${GREEN}await prisma.user.delete({ where: { id: 1 } })${RESET}"
  echo ""
  echo -e "  ${DIM}// Delete many${RESET}"
  echo -e "  ${GREEN}const { count } = await prisma.user.deleteMany({${RESET}"
  echo -e "  ${GREEN}  where: { isActive: false }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// Delete ALL records in table${RESET}"
  echo -e "  ${GREEN}await prisma.user.deleteMany({})${RESET}"
  echo -e "$DIV"

  # ── aggregate / count ──────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» COUNT / AGGREGATE${RESET}"
  echo ""
  echo -e "  ${GREEN}const count = await prisma.user.count()${RESET}"
  echo -e "  ${GREEN}const count = await prisma.user.count({ where: { isActive: true } })${RESET}"
  echo ""
  echo -e "  ${GREEN}const agg = await prisma.user.aggregate({${RESET}"
  echo -e "  ${GREEN}  _count: { _all: true },   ${DIM}// total rows${RESET}"
  echo -e "  ${GREEN}  _avg:   { score: true },  ${DIM}// average score${RESET}"
  echo -e "  ${GREEN}  _sum:   { score: true },  ${DIM}// sum of scores${RESET}"
  echo -e "  ${GREEN}  _min:   { age: true },    ${DIM}// min age${RESET}"
  echo -e "  ${GREEN}  _max:   { age: true },    ${DIM}// max age${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// Group by${RESET}"
  echo -e "  ${GREEN}const grouped = await prisma.user.groupBy({${RESET}"
  echo -e "  ${GREEN}  by:      ['role'],${RESET}"
  echo -e "  ${GREEN}  _count:  { _all: true },${RESET}"
  echo -e "  ${GREEN}  having:  { role: { not: 'BANNED' } }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo -e "$DIV"

  # ── transactions ───────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» TRANSACTIONS${RESET}"
  echo ""
  echo -e "  ${DIM}// Sequential transaction (all-or-nothing)${RESET}"
  echo -e "  ${GREEN}const [user, post] = await prisma.\$transaction([${RESET}"
  echo -e "  ${GREEN}  prisma.user.create({ data: { name: 'Alice', email: 'a@ex.com' } }),${RESET}"
  echo -e "  ${GREEN}  prisma.post.create({ data: { title: 'Hello', authorId: 1 } }),${RESET}"
  echo -e "  ${GREEN}])${RESET}"
  echo ""
  echo -e "  ${DIM}// Interactive transaction (with rollback logic)${RESET}"
  echo -e "  ${GREEN}await prisma.\$transaction(async (tx) => {${RESET}"
  echo -e "  ${GREEN}  const user = await tx.user.create({ data: { name: 'Bob', email: 'b@ex.com' } })${RESET}"
  echo -e "  ${GREEN}  await tx.profile.create({ data: { bio: 'Hi', userId: user.id } })${RESET}"
  echo -e "  ${GREEN}  // if any line throws, entire transaction rolls back${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo -e "$DIV"

  # ── raw queries ────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» RAW SQL Queries${RESET}"
  echo ""
  echo -e "  ${DIM}// Raw query with result (SELECT)${RESET}"
  echo -e "  ${GREEN}const result = await prisma.\$queryRaw\`SELECT * FROM \"User\" WHERE id = \${userId}\`${RESET}"
  echo ""
  echo -e "  ${DIM}// Raw execute (INSERT / UPDATE / DELETE — returns count)${RESET}"
  echo -e "  ${GREEN}await prisma.\$executeRaw\`UPDATE \"User\" SET score = 0 WHERE role = 'BANNED'\`${RESET}"
  echo ""
  echo -e "  ${DIM}// Unsafe raw (string interpolation — use only if parameterized not possible)${RESET}"
  echo -e "  ${GREEN}const result = await prisma.\$queryRawUnsafe('SELECT * FROM \"User\" WHERE id = ' + id)${RESET}"
  echo -e "$DIV"

  # ── relations queries ─────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» RELATION QUERIES${RESET}"
  echo ""
  echo -e "  ${DIM}// Connect existing record (set FK)${RESET}"
  echo -e "  ${GREEN}await prisma.post.create({${RESET}"
  echo -e "  ${GREEN}  data: {${RESET}"
  echo -e "  ${GREEN}    title:  'Hello',${RESET}"
  echo -e "  ${GREEN}    author: { connect: { id: 1 } }  ${DIM}// link to existing user${RESET}"
  echo -e "  ${GREEN}  }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// connectOrCreate (connect if exists, create if not)${RESET}"
  echo -e "  ${GREEN}author: { connectOrCreate: {${RESET}"
  echo -e "  ${GREEN}  where:  { email: 'alice@example.com' },${RESET}"
  echo -e "  ${GREEN}  create: { name: 'Alice', email: 'alice@example.com' }${RESET}"
  echo -e "  ${GREEN}}}${RESET}"
  echo ""
  echo -e "  ${DIM}// Disconnect (remove FK, not delete record)${RESET}"
  echo -e "  ${GREEN}await prisma.post.update({${RESET}"
  echo -e "  ${GREEN}  where: { id: 1 },${RESET}"
  echo -e "  ${GREEN}  data:  { author: { disconnect: true } }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// M:N connect (add tag to post)${RESET}"
  echo -e "  ${GREEN}await prisma.post.update({${RESET}"
  echo -e "  ${GREEN}  where: { id: 1 },${RESET}"
  echo -e "  ${GREEN}  data:  { tags: { connect: { id: 5 } } }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// M:N disconnect (remove tag from post)${RESET}"
  echo -e "  ${GREEN}await prisma.post.update({${RESET}"
  echo -e "  ${GREEN}  where: { id: 1 },${RESET}"
  echo -e "  ${GREEN}  data:  { tags: { disconnect: { id: 5 } } }${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo ""
  echo -e "  ${DIM}// set (replace all connected records)${RESET}"
  echo -e "  ${GREEN}await prisma.post.update({${RESET}"
  echo -e "  ${GREEN}  where: { id: 1 },${RESET}"
  echo -e "  ${GREEN}  data:  { tags: { set: [{ id: 1 }, { id: 2 }] } }  ${DIM}// replace all tags${RESET}"
  echo -e "  ${GREEN}})${RESET}"
  echo -e "$DIV"

  echo -e "  ${BOLD}${YELLOW}» Seed Script Template (prisma/seed.ts)${RESET}"
  echo ""
  echo -e "  ${GREEN}import { PrismaClient } from '@prisma/client'${RESET}"
  echo -e "  ${GREEN}const prisma = new PrismaClient()${RESET}"
  echo ""
  echo -e "  ${GREEN}async function main() {${RESET}"
  echo -e "  ${GREEN}  await prisma.user.upsert({${RESET}"
  echo -e "  ${GREEN}    where:  { email: 'admin@example.com' },${RESET}"
  echo -e "  ${GREEN}    create: { name: 'Admin', email: 'admin@example.com', role: 'ADMIN' },${RESET}"
  echo -e "  ${GREEN}    update: {}${RESET}"
  echo -e "  ${GREEN}  })${RESET}"
  echo -e "  ${GREEN}}${RESET}"
  echo ""
  echo -e "  ${GREEN}main()${RESET}"
  echo -e "  ${GREEN}  .catch(console.error)${RESET}"
  echo -e "  ${GREEN}  .finally(async () => { await prisma.\$disconnect() })${RESET}"
  echo ""
  echo -e "  ${DIM}  // package.json:${RESET}"
  echo -e "  ${GREEN}  \"prisma\": { \"seed\": \"ts-node prisma/seed.ts\" }${RESET}"
  echo ""
}
