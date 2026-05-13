#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# mkbackend — Node.js Backend Scaffold Tool
# Add to ~/.bashrc:
#   source ~/.nodejs.sh
# Then run:
#   mkbackend
# ─────────────────────────────────────────────────────────────────

mkbackend() {

  # ── Colors ───────────────────────────────────────────────────────
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local MAGENTA='\033[0;35m'
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local WHITE='\033[1;37m'
  local RESET='\033[0m'

  local DIV="${DIM}────────────────────────────────────────────────────────────────${RESET}"

  # ── Ask yes/no helper ────────────────────────────────────────────
  _ask() {
    local QUESTION="$1"
    local VAR_NAME="$2"
    local _ANS
    while true; do
      read -rp "  ${QUESTION} (Y/n): " _ANS
      _ANS="${_ANS:-y}"
      _ANS="${_ANS,,}"
      if [[ "$_ANS" == "y" || "$_ANS" == "n" ]]; then
        break
      else
        echo -e "  ${RED}Please enter only y or n${RESET}"
      fi
    done
    printf -v "$VAR_NAME" '%s' "$_ANS"
  }

  _yes() { [[ "$1" == "y" || "$1" == "Y" ]]; }

  # ── Touch with mkdir ─────────────────────────────────────────────
  _touch() { mkdir -p "$(dirname "$1")" && touch "$1"; }

  # ── Write file with heredoc ──────────────────────────────────────
  _write() {
    local FILE="$1"
    mkdir -p "$(dirname "$FILE")"
    cat > "$FILE"
  }

  # ════════════════════════════════════════════════════════════════
  # BANNER
  # ════════════════════════════════════════════════════════════════
  clear
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║       🚀  mkbackend — Node.js Backend Scaffold Tool         ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  # ════════════════════════════════════════════════════════════════
  # STEP 1: Project Name
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 1: Project Name ──────────────────────────────────────${RESET}"
  read -rp "  Project name: " PROJECT_NAME
  [[ -z "$PROJECT_NAME" ]] && echo -e "${RED}  ✗ Empty. Aborted.${RESET}" && return 1
  PROJECT_NAME="${PROJECT_NAME// /-}"

  local _INPUT_AUTHOR
  read -rp "  Author / GitHub username [your-username]: " _INPUT_AUTHOR
  AUTHOR="${_INPUT_AUTHOR:-your-username}"

  local _INPUT_EMAIL
  read -rp "  Contact email [${AUTHOR}@example.com]: " _INPUT_EMAIL
  CONTACT_EMAIL="${_INPUT_EMAIL:-${AUTHOR}@example.com}"

  echo ""

  # ════════════════════════════════════════════════════════════════
  # STEP 2: Language
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 2: Language ──────────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}1)${RESET} JavaScript (CommonJS)"
  echo -e "  ${GREEN}2)${RESET} JavaScript (ESM  — import/export)"
  echo -e "  ${GREEN}3)${RESET} TypeScript"
  echo ""
  read -rp "  Choose [1-3]: " LANG_CHOICE
  LANG_CHOICE="${LANG_CHOICE:-1}"
  echo ""

  case "$LANG_CHOICE" in
    1) EXT="js";  LANG_LABEL="JavaScript (CJS)" ;;
    2) EXT="js";  LANG_LABEL="JavaScript (ESM)";  IS_ESM=y ;;
    3) EXT="ts";  LANG_LABEL="TypeScript" ;;
    *) EXT="js";  LANG_LABEL="JavaScript (CJS)" ;;
  esac

  # ════════════════════════════════════════════════════════════════
  # STEP 3: Database
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 3: Database ──────────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}1)${RESET} PostgreSQL"
  echo -e "  ${GREEN}2)${RESET} MongoDB"
  echo -e "  ${GREEN}3)${RESET} MySQL"
  echo -e "  ${GREEN}4)${RESET} SQLite"
  echo -e "  ${GREEN}5)${RESET} None"
  echo ""
  read -rp "  Choose [1-5]: " DB_CHOICE
  DB_CHOICE="${DB_CHOICE:-5}"
  echo ""

  case "$DB_CHOICE" in
    1) DB_LABEL="PostgreSQL" ;;
    2) DB_LABEL="MongoDB" ;;
    3) DB_LABEL="MySQL" ;;
    4) DB_LABEL="SQLite" ;;
    *) DB_LABEL="None" ;;
  esac

  # ORM
  ORM_CHOICE="none"; ORM_LABEL="None"
  if [[ "$DB_CHOICE" != "5" ]]; then
    echo -e "${BOLD}${YELLOW}── Step 3b: ORM / Driver ─────────────────────────────────────${RESET}"
    if [[ "$DB_CHOICE" == "2" ]]; then
      echo -e "  ${GREEN}1)${RESET} Mongoose"
      echo -e "  ${GREEN}2)${RESET} Raw mongodb driver"
    else
      echo -e "  ${GREEN}1)${RESET} Prisma"
      echo -e "  ${GREEN}2)${RESET} Sequelize"
      echo -e "  ${GREEN}3)${RESET} TypeORM"
      echo -e "  ${GREEN}4)${RESET} Knex"
      echo -e "  ${GREEN}5)${RESET} Raw driver only"
    fi
    echo ""
    read -rp "  Choose: " ORM_CHOICE
    ORM_CHOICE="${ORM_CHOICE:-1}"
    echo ""
    if [[ "$DB_CHOICE" == "2" ]]; then
      [[ "$ORM_CHOICE" == "1" ]] && ORM_LABEL="Mongoose" || ORM_LABEL="Raw mongodb"
    else
      case "$ORM_CHOICE" in
        1) ORM_LABEL="Prisma" ;;
        2) ORM_LABEL="Sequelize" ;;
        3) ORM_LABEL="TypeORM" ;;
        4) ORM_LABEL="Knex" ;;
        *) ORM_LABEL="Raw driver" ;;
      esac
    fi
  fi

  # ════════════════════════════════════════════════════════════════
  # STEP 4: Features — ask one by one
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 4: Features (select what you need) ───────────────────${RESET}"
  echo -e "${DIM}  Press ENTER to accept default (y). Enter n to skip.${RESET}"
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Core Features ]${RESET}"
  _ask "Auth — JWT (login/register/refresh token)"        F_JWT
  _ask "OAuth — Google / GitHub login"                    F_OAUTH
  _ask "RBAC — Role-based access control"                 F_RBAC
  _ask "WebSockets — Socket.io realtime"                  F_SOCKET
  _ask "Background Jobs — BullMQ + Redis queue"           F_JOBS
  _ask "Email Service — Nodemailer + templates"           F_EMAIL
  _ask "File Upload — Multer + S3/Cloudinary"             F_UPLOAD
  _ask "Redis — Caching layer"                            F_REDIS
  _ask "Swagger — API documentation"                      F_SWAGGER
  _ask "Health check route (/health)"                     F_HEALTH
  _ask "Rate Limiting — express-rate-limit"               F_RATELIMIT
  _ask "Cron jobs (node-cron)"                            F_CRON
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Integrations ]${RESET}"
  _ask "Payment — Razorpay / Stripe"                      F_PAYMENT
  _ask "SMS — Twilio"                                     F_SMS
  _ask "Push Notifications — Firebase FCM"                F_PUSH
  _ask "PDF Generation — Puppeteer / PDFKit"              F_PDF
  _ask "Excel Export — ExcelJS"                           F_EXCEL
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Dev / Quality ]${RESET}"
  _ask "Logging — Winston + Morgan"                       F_LOGGING
  _ask "Testing — Jest + Supertest"                       F_TESTING
  _ask "ESLint + Prettier config"                         F_LINT
  _ask "Husky — pre-commit hooks (lint + format)"         F_HUSKY
  _ask "Nodemon config (nodemon.json)"                    F_NODEMON
  _ask "PM2 config (ecosystem.config.js)"                 F_PM2
  _ask "Docker — Dockerfile + docker-compose"             F_DOCKER
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ GitHub / CI ]${RESET}"
  _ask "CI/CD — GitHub Actions (test + deploy)"           F_CICD
  _ask "Release Action — Auto release on vX.X.X tag push" F_RELEASE
  _ask "GitHub Issue Templates (bug/feature/question)"    F_ISSUES
  _ask "GitHub PR Template"                               F_PR
  _ask "GitHub CODEOWNERS file"                           F_CODEOWNERS
  _ask "dependabot.yml"                                   F_DEPENDABOT
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Project Docs ]${RESET}"
  _ask "README.md"                                        F_README
  _ask "ARCHITECTURE.md"                                  F_ARCHITECTURE
  _ask "CONTRIBUTING.md"                                  F_CONTRIBUTING
  _ask "CHANGELOG.md"                                     F_CHANGELOG
  _ask "LICENSE.md"                                       F_LICENSE
  _ask "SECURITY.md"                                      F_SECURITY
  _ask "CODE_OF_CONDUCT.md"                               F_CODE_OF_CONDUCT
  _ask "ABOUT.md"                                         F_ABOUT
  _ask "NOTICE.md"                                        F_NOTICE
  _ask "TRADEMARKS.md"                                    F_TRADEMARKS
  echo ""

  # ════════════════════════════════════════════════════════════════
  # STEP 5: Summary + Confirm
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${CYAN}── Summary ───────────────────────────────────────────────────${RESET}"
  echo ""
  echo -e "  Project   : ${GREEN}${PROJECT_NAME}${RESET}"
  echo -e "  Language  : ${GREEN}${LANG_LABEL}${RESET}"
  echo -e "  Database  : ${GREEN}${DB_LABEL}${RESET}"
  echo -e "  ORM       : ${GREEN}${ORM_LABEL}${RESET}"
  echo -e "  Author    : ${GREEN}${AUTHOR}${RESET}"
  echo ""
  echo -e "  ${BOLD}Features:${RESET}"

  echo -e "  ${DIM}Core:${RESET}"
  _yes "$F_JWT"       && echo -e "    ${GREEN}✓${RESET} JWT Auth"
  _yes "$F_OAUTH"     && echo -e "    ${GREEN}✓${RESET} OAuth"
  _yes "$F_RBAC"      && echo -e "    ${GREEN}✓${RESET} RBAC"
  _yes "$F_SOCKET"    && echo -e "    ${GREEN}✓${RESET} WebSockets"
  _yes "$F_JOBS"      && echo -e "    ${GREEN}✓${RESET} BullMQ Jobs"
  _yes "$F_EMAIL"     && echo -e "    ${GREEN}✓${RESET} Email"
  _yes "$F_UPLOAD"    && echo -e "    ${GREEN}✓${RESET} File Upload"
  _yes "$F_REDIS"     && echo -e "    ${GREEN}✓${RESET} Redis"
  _yes "$F_SWAGGER"   && echo -e "    ${GREEN}✓${RESET} Swagger"
  _yes "$F_HEALTH"    && echo -e "    ${GREEN}✓${RESET} Health check"
  _yes "$F_RATELIMIT" && echo -e "    ${GREEN}✓${RESET} Rate Limiting"
  _yes "$F_CRON"      && echo -e "    ${GREEN}✓${RESET} Cron jobs"

  echo -e "  ${DIM}Integrations:${RESET}"
  _yes "$F_PAYMENT"   && echo -e "    ${GREEN}✓${RESET} Payment"
  _yes "$F_SMS"       && echo -e "    ${GREEN}✓${RESET} SMS"
  _yes "$F_PUSH"      && echo -e "    ${GREEN}✓${RESET} Push Notifications"
  _yes "$F_PDF"       && echo -e "    ${GREEN}✓${RESET} PDF"
  _yes "$F_EXCEL"     && echo -e "    ${GREEN}✓${RESET} Excel"

  echo -e "  ${DIM}Dev/Quality:${RESET}"
  _yes "$F_LOGGING"   && echo -e "    ${GREEN}✓${RESET} Logging"
  _yes "$F_TESTING"   && echo -e "    ${GREEN}✓${RESET} Testing"
  _yes "$F_LINT"      && echo -e "    ${GREEN}✓${RESET} ESLint + Prettier"
  _yes "$F_HUSKY"     && echo -e "    ${GREEN}✓${RESET} Husky"
  _yes "$F_NODEMON"   && echo -e "    ${GREEN}✓${RESET} Nodemon config"
  _yes "$F_PM2"       && echo -e "    ${GREEN}✓${RESET} PM2 config"
  _yes "$F_DOCKER"    && echo -e "    ${GREEN}✓${RESET} Docker"

  echo -e "  ${DIM}GitHub/CI:${RESET}"
  _yes "$F_CICD"       && echo -e "    ${GREEN}✓${RESET} GitHub Actions CI/CD"
  _yes "$F_RELEASE"    && echo -e "    ${GREEN}✓${RESET} Auto Release workflow"
  _yes "$F_ISSUES"     && echo -e "    ${GREEN}✓${RESET} GitHub Issue Templates"
  _yes "$F_PR"         && echo -e "    ${GREEN}✓${RESET} PR Template"
  _yes "$F_CODEOWNERS" && echo -e "    ${GREEN}✓${RESET} CODEOWNERS"
  _yes "$F_DEPENDABOT" && echo -e "    ${GREEN}✓${RESET} dependabot.yml"

  echo -e "  ${DIM}Docs:${RESET}"
  _yes "$F_README"          && echo -e "    ${GREEN}✓${RESET} README.md"
  _yes "$F_ARCHITECTURE"    && echo -e "    ${GREEN}✓${RESET} ARCHITECTURE.md"
  _yes "$F_CONTRIBUTING"    && echo -e "    ${GREEN}✓${RESET} CONTRIBUTING.md"
  _yes "$F_CHANGELOG"       && echo -e "    ${GREEN}✓${RESET} CHANGELOG.md"
  _yes "$F_LICENSE"         && echo -e "    ${GREEN}✓${RESET} LICENSE.md"
  _yes "$F_SECURITY"        && echo -e "    ${GREEN}✓${RESET} SECURITY.md"
  _yes "$F_CODE_OF_CONDUCT" && echo -e "    ${GREEN}✓${RESET} CODE_OF_CONDUCT.md"
  _yes "$F_ABOUT"           && echo -e "    ${GREEN}✓${RESET} ABOUT.md"
  _yes "$F_NOTICE"          && echo -e "    ${GREEN}✓${RESET} NOTICE.md"
  _yes "$F_TRADEMARKS"      && echo -e "    ${GREEN}✓${RESET} TRADEMARKS.md"

  echo ""
  read -rp "  Create project? [y/n]: " CONFIRM
  [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
  echo ""

  # ════════════════════════════════════════════════════════════════
  # SCAFFOLD — Directories
  # ════════════════════════════════════════════════════════════════
  local B="$PROJECT_NAME"

  echo -e "${BOLD}${CYAN}  🔨 Scaffolding project...${RESET}"
  echo ""

  # ── Core directories ─────────────────────────────────────────────
  mkdir -p "$B"/src/{config,constants,controllers,middleware,routes/{v1,v2},services,utils/{helpers,validators,db},models}
  mkdir -p "$B"/{scripts,logs,uploads/{images,documents}}
  mkdir -p "$B"/.github/workflows

  # ── Feature directories ──────────────────────────────────────────
  _yes "$F_LOGGING" && mkdir -p "$B/src/utils/logger"
  _yes "$F_SOCKET"  && mkdir -p "$B/src/sockets"
  _yes "$F_JOBS"    && mkdir -p "$B/src/jobs"
  _yes "$F_CRON"    && mkdir -p "$B/src/cron"
  _yes "$F_EMAIL"   && mkdir -p "$B/src/templates/emails"
  _yes "$F_PDF"     && mkdir -p "$B/src/templates/pdf"
  _yes "$F_TESTING" && mkdir -p "$B/tests"/{unit/{controllers,services,utils},integration,fixtures,setup}
  _yes "$F_ISSUES"  && mkdir -p "$B/.github/ISSUE_TEMPLATE"
  _yes "$F_HUSKY"   && mkdir -p "$B/.husky"
  if [[ "$ORM_CHOICE" == "1" && "$DB_CHOICE" != "2" ]]; then
    mkdir -p "$B/src/prisma"/{migrations,seeders}
  fi

  # ════════════════════════════════════════════════════════════════
  # SCAFFOLD — Files
  # ════════════════════════════════════════════════════════════════

  # ── Config files ─────────────────────────────────────────────────
  _touch "$B/src/config/env.config.$EXT"
  _touch "$B/src/config/jwt.config.$EXT"
  [[ "$DB_CHOICE" != "5" ]] && _touch "$B/src/config/database.config.$EXT"
  _yes "$F_REDIS"  && _touch "$B/src/config/redis.config.$EXT"
  _yes "$F_EMAIL"  && _touch "$B/src/config/mail.config.$EXT"
  _yes "$F_UPLOAD" && _touch "$B/src/config/cloudinary.config.$EXT"
  _yes "$F_SOCKET" && _touch "$B/src/config/socket.config.$EXT"
  _yes "$F_PUSH"   && _touch "$B/src/config/firebase.config.$EXT"

  # ── Constants ────────────────────────────────────────────────────
  _touch "$B/src/constants/app.constants.$EXT"
  _touch "$B/src/constants/error.constants.$EXT"
  _touch "$B/src/constants/message.constants.$EXT"
  _touch "$B/src/constants/status.constants.$EXT"
  _touch "$B/src/constants/regex.constants.$EXT"
  _touch "$B/src/constants/api.constants.$EXT"
  _yes "$F_RBAC" && _touch "$B/src/constants/role.constants.$EXT"

  # ── Controllers ──────────────────────────────────────────────────
  _touch "$B/src/controllers/auth.controller.$EXT"
  _touch "$B/src/controllers/user.controller.$EXT"
  _yes "$F_PAYMENT" && _touch "$B/src/controllers/payment.controller.$EXT"
  _yes "$F_HEALTH"  && _touch "$B/src/controllers/health.controller.$EXT"

  # ── Middleware ───────────────────────────────────────────────────
  _touch "$B/src/middleware/error.middleware.$EXT"
  _touch "$B/src/middleware/validation.middleware.$EXT"
  _touch "$B/src/middleware/cors.middleware.$EXT"
  _touch "$B/src/middleware/compression.middleware.$EXT"
  _yes "$F_JWT"       && _touch "$B/src/middleware/auth.middleware.$EXT"
  _yes "$F_RBAC"      && _touch "$B/src/middleware/role.middleware.$EXT"
  _yes "$F_UPLOAD"    && _touch "$B/src/middleware/upload.middleware.$EXT"
  _yes "$F_REDIS"     && _touch "$B/src/middleware/cache.middleware.$EXT"
  _yes "$F_RATELIMIT" && _touch "$B/src/middleware/rateLimit.middleware.$EXT"
  _yes "$F_LOGGING"   && _touch "$B/src/middleware/logging.middleware.$EXT"

  # ── Routes ───────────────────────────────────────────────────────
  _touch "$B/src/routes/index.$EXT"
  _touch "$B/src/routes/v1/auth.routes.$EXT"
  _touch "$B/src/routes/v1/user.routes.$EXT"
  _yes "$F_PAYMENT" && _touch "$B/src/routes/v1/payment.routes.$EXT"
  _yes "$F_HEALTH"  && _touch "$B/src/routes/v1/health.routes.$EXT"

  # ── Services ─────────────────────────────────────────────────────
  _touch "$B/src/services/auth.service.$EXT"
  _touch "$B/src/services/user.service.$EXT"
  _yes "$F_EMAIL"   && _touch "$B/src/services/email.service.$EXT"
  _yes "$F_UPLOAD"  && _touch "$B/src/services/fileUpload.service.$EXT"
  _yes "$F_REDIS"   && _touch "$B/src/services/cache.service.$EXT"
  _yes "$F_PAYMENT" && _touch "$B/src/services/payment.service.$EXT"
  _yes "$F_SMS"     && _touch "$B/src/services/sms.service.$EXT"
  _yes "$F_PUSH"    && _touch "$B/src/services/pushNotification.service.$EXT"
  _yes "$F_PDF"     && _touch "$B/src/services/pdf.service.$EXT"
  _yes "$F_EXCEL"   && _touch "$B/src/services/excel.service.$EXT"

  # ── Utils ────────────────────────────────────────────────────────
  _touch "$B/src/utils/helpers/apiResponse.helper.$EXT"
  _touch "$B/src/utils/helpers/apiFeatures.helper.$EXT"
  _touch "$B/src/utils/helpers/encryption.helper.$EXT"
  _touch "$B/src/utils/helpers/token.helper.$EXT"
  _touch "$B/src/utils/helpers/otp.helper.$EXT"
  _touch "$B/src/utils/helpers/dateFormatter.helper.$EXT"
  _touch "$B/src/utils/helpers/stringFormatter.helper.$EXT"
  _touch "$B/src/utils/helpers/slugify.helper.$EXT"
  _touch "$B/src/utils/validators/auth.validator.$EXT"
  _touch "$B/src/utils/validators/user.validator.$EXT"
  _touch "$B/src/utils/db/query.util.$EXT"
  if [[ "$ORM_CHOICE" == "1" && "$DB_CHOICE" != "2" ]]; then
    _touch "$B/src/utils/db/prisma.util.$EXT"
  fi
  if _yes "$F_LOGGING"; then
    _touch "$B/src/utils/logger/logger.util.$EXT"
    _touch "$B/src/utils/logger/morgan.util.$EXT"
  fi

  # ── Models ───────────────────────────────────────────────────────
  _touch "$B/src/models/User.model.$EXT"
  _touch "$B/src/models/index.$EXT"

  # ── Prisma ───────────────────────────────────────────────────────
  if [[ "$ORM_CHOICE" == "1" && "$DB_CHOICE" != "2" ]]; then
    _touch "$B/src/prisma/schema.prisma"
    _touch "$B/src/prisma/seeders/seed.$EXT"
    _touch "$B/src/prisma/seeders/user.seeder.$EXT"
  fi

  # ── Sockets ──────────────────────────────────────────────────────
  if _yes "$F_SOCKET"; then
    _touch "$B/src/sockets/socket.handler.$EXT"
    _touch "$B/src/sockets/events.handler.$EXT"
    _touch "$B/src/sockets/notification.socket.$EXT"
  fi

  # ── Jobs (BullMQ) ────────────────────────────────────────────────
  if _yes "$F_JOBS"; then
    _touch "$B/src/jobs/queue.jobs.$EXT"
    _touch "$B/src/jobs/email.job.$EXT"
    _touch "$B/src/jobs/notification.job.$EXT"
    _touch "$B/src/jobs/cleanup.job.$EXT"
  fi

  # ── Cron ─────────────────────────────────────────────────────────
  if _yes "$F_CRON"; then
    _touch "$B/src/cron/cron.jobs.$EXT"
    _touch "$B/src/cron/cleanup.cron.$EXT"
  fi

  # ── Email templates ──────────────────────────────────────────────
  if _yes "$F_EMAIL"; then
    _touch "$B/src/templates/emails/welcome.email.hbs"
    _touch "$B/src/templates/emails/resetPassword.email.hbs"
    _touch "$B/src/templates/emails/otp.email.hbs"
  fi

  # ── PDF templates ────────────────────────────────────────────────
  _yes "$F_PDF" && _touch "$B/src/templates/pdf/document.pdf.hbs"

  # ── Testing ──────────────────────────────────────────────────────
  if _yes "$F_TESTING"; then
    _touch "$B/tests/unit/controllers/auth.controller.test.$EXT"
    _touch "$B/tests/unit/controllers/user.controller.test.$EXT"
    _touch "$B/tests/unit/services/auth.service.test.$EXT"
    _touch "$B/tests/unit/services/user.service.test.$EXT"
    _touch "$B/tests/unit/utils/helpers.test.$EXT"
    _touch "$B/tests/integration/auth.integration.test.$EXT"
    _touch "$B/tests/integration/api.integration.test.$EXT"
    _touch "$B/tests/fixtures/user.fixture.$EXT"
    _touch "$B/tests/setup/teardown.$EXT"
    _touch "$B/tests/setup/test.db.$EXT"
  fi

  # ── Scripts ──────────────────────────────────────────────────────
  touch "$B/scripts/deploy.sh" "$B/scripts/backup.sh" "$B/scripts/migrate.sh" "$B/scripts/seed.sh"
  chmod +x "$B/scripts/"*.sh

  # ── Keep files ───────────────────────────────────────────────────
  touch "$B/logs/.gitkeep" "$B/uploads/images/.gitkeep" "$B/uploads/documents/.gitkeep"

  # ── Entry points ─────────────────────────────────────────────────
  if [[ "$EXT" == "ts" ]]; then
    _touch "$B/src/app.ts"
    _touch "$B/server.ts"
  else
    _touch "$B/src/app.js"
    _touch "$B/server.js"
  fi

  # ════════════════════════════════════════════════════════════════
  # ROOT CONFIG FILES
  # ════════════════════════════════════════════════════════════════

  # ── .env files ───────────────────────────────────────────────────
  cat > "$B/.env.example" << EOF
# ─── App ───────────────────────────────────────
NODE_ENV=development
PORT=3000
APP_NAME=${PROJECT_NAME}
APP_URL=http://localhost:3000

# ─── Database ──────────────────────────────────
DATABASE_URL=

# ─── JWT ───────────────────────────────────────
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your_refresh_secret_here
JWT_REFRESH_EXPIRES_IN=30d

# ─── Redis ─────────────────────────────────────
REDIS_URL=redis://localhost:6379

# ─── Mail ──────────────────────────────────────
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USER=
MAIL_PASS=
MAIL_FROM=noreply@example.com

# ─── Cloudinary ────────────────────────────────
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

# ─── Firebase ──────────────────────────────────
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=

# ─── Payment ───────────────────────────────────
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
STRIPE_SECRET_KEY=

# ─── Twilio ────────────────────────────────────
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE=
EOF
  cp "$B/.env.example" "$B/.env"
  touch "$B/.env.development" "$B/.env.production" "$B/.env.staging"

  # ── .gitignore ───────────────────────────────────────────────────
  cat > "$B/.gitignore" << 'EOF'
# Dependencies
node_modules/
.pnp
.pnp.js

# Build
dist/
build/

# Env
.env
.env.local
.env.production
.env.staging

# Logs
logs/*.log
*.log
npm-debug.log*

# Uploads (keep structure)
uploads/*
!uploads/.gitkeep
!uploads/images/.gitkeep
!uploads/documents/.gitkeep

# OS
.DS_Store
Thumbs.db

# Coverage
coverage/
.nyc_output/

# Misc
*.dump
.cache/
tmp/
EOF

  # ── package.json ─────────────────────────────────────────────────
  local PKG_TYPE=""
  _yes "$IS_ESM" && PKG_TYPE='"type": "module",'

  if [[ "$EXT" == "ts" ]]; then
    cat > "$B/package.json" << EOF
{
  "name": "${PROJECT_NAME}",
  "version": "1.0.0",
  "description": "",
  "main": "dist/server.js",
  "scripts": {
    "start": "node dist/server.js",
    "dev": "ts-node-dev --respawn --transpile-only src/server.ts",
    "build": "tsc",
    "test": "jest --coverage",
    "test:unit": "jest tests/unit --coverage",
    "test:integration": "jest tests/integration",
    "test:watch": "jest --watch",
    "lint": "eslint . --ext .ts",
    "format": "prettier --write .",
    "migrate": "npx prisma migrate deploy",
    "seed": "ts-node src/prisma/seeders/seed.ts"
  },
  "dependencies": {},
  "devDependencies": {}
}
EOF
    cat > "$B/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
EOF
  else
    cat > "$B/package.json" << EOF
{
  "name": "${PROJECT_NAME}",
  "version": "1.0.0",
  "description": "",
  ${PKG_TYPE}
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest --coverage",
    "test:unit": "jest tests/unit --coverage",
    "test:integration": "jest tests/integration",
    "test:watch": "jest --watch",
    "lint": "eslint .",
    "format": "prettier --write .",
    "migrate": "npx sequelize-cli db:migrate",
    "seed": "node scripts/seed.js"
  },
  "dependencies": {},
  "devDependencies": {}
}
EOF
  fi

  # ── ESLint + Prettier ────────────────────────────────────────────
  if _yes "$F_LINT"; then
    cat > "$B/.eslintrc.js" << 'EOF'
module.exports = {
  env: { node: true, es2021: true },
  extends: ['eslint:recommended'],
  parserOptions: { ecmaVersion: 'latest', sourceType: 'module' },
  rules: {
    'no-console': 'warn',
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
  },
};
EOF
    cat > "$B/.prettierrc" << 'EOF'
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
EOF
  fi

  # ── Nodemon ──────────────────────────────────────────────────────
  if _yes "$F_NODEMON"; then
    cat > "$B/nodemon.json" << EOF
{
  "watch": ["src"],
  "ext": "${EXT}",
  "ignore": ["src/**/*.test.${EXT}", "node_modules"],
  "exec": "node server.${EXT}"
}
EOF
  fi

  # ── PM2 ──────────────────────────────────────────────────────────
  if _yes "$F_PM2"; then
    cat > "$B/ecosystem.config.js" << EOF
module.exports = {
  apps: [{
    name: '${PROJECT_NAME}',
    script: 'server.${EXT}',
    instances: 'max',
    exec_mode: 'cluster',
    env: { NODE_ENV: 'development' },
    env_production: { NODE_ENV: 'production' },
    error_file: 'logs/pm2-error.log',
    out_file: 'logs/pm2-out.log',
  }]
};
EOF
  fi

  # ── Swagger ──────────────────────────────────────────────────────
  if _yes "$F_SWAGGER"; then
    cat > "$B/swagger.yaml" << 'EOF'
openapi: 3.0.0
info:
  title: API Documentation
  version: 1.0.0
  description: Auto-generated API docs
servers:
  - url: http://localhost:3000/api/v1
paths:
  /health:
    get:
      summary: Health check
      responses:
        '200':
          description: OK
EOF
  fi

  # ── Docker ───────────────────────────────────────────────────────
  if _yes "$F_DOCKER"; then
    cat > "$B/Dockerfile" << EOF
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM base AS development
RUN npm ci
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

FROM base AS production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF
    cat > "$B/docker-compose.yml" << EOF
version: '3.8'
services:
  app:
    build:
      context: .
      target: development
    ports:
      - "3000:3000"
    env_file: .env
    volumes:
      - .:/app
      - /app/node_modules
    depends_on:
      - db
      - redis

  db:
    image: postgres:15-alpine
    restart: always
    environment:
      POSTGRES_DB: \${DB_NAME:-${PROJECT_NAME}_db}
      POSTGRES_USER: \${DB_USER:-postgres}
      POSTGRES_PASSWORD: \${DB_PASS:-password}
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data

volumes:
  pgdata:
  redisdata:
EOF
    cat > "$B/.dockerignore" << 'EOF'
node_modules
.env
logs
uploads
.git
coverage
dist
EOF
  fi

  # ── Husky ────────────────────────────────────────────────────────
  if _yes "$F_HUSKY"; then
    cat > "$B/.husky/pre-commit" << 'EOF'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"
npm run lint
npm run format
EOF
    cat > "$B/.husky/commit-msg" << 'EOF'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"
npx --no -- commitlint --edit "$1"
EOF
    chmod +x "$B/.husky/pre-commit" "$B/.husky/commit-msg"
  fi

  # ── Testing config ───────────────────────────────────────────────
  if _yes "$F_TESTING"; then
    cat > "$B/jest.config.js" << EOF
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.${EXT}'],
  collectCoverageFrom: ['src/**/*.${EXT}', '!src/**/*.d.ts'],
  coverageThreshold: {
    global: { branches: 70, functions: 70, lines: 70, statements: 70 }
  },
};
EOF
  fi

  # ════════════════════════════════════════════════════════════════
  # GITHUB FILES
  # ════════════════════════════════════════════════════════════════

  # ── Issue Templates ──────────────────────────────────────────────
  if _yes "$F_ISSUES"; then
    cat > "$B/.github/ISSUE_TEMPLATE/bug_report.yml" << 'EOF'
name: 🐛 Bug Report
description: Report a bug or unexpected behavior
labels: ["bug", "needs-triage"]
body:
  - type: textarea
    id: description
    attributes:
      label: Describe the bug
    validations:
      required: true
  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: Expected behavior
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Relevant logs / stack trace
      render: shell
  - type: input
    id: node-version
    attributes:
      label: Node.js version
      placeholder: "node --version"
  - type: input
    id: os
    attributes:
      label: OS / environment
      placeholder: "e.g. Ubuntu 22.04, Docker"
  - type: dropdown
    id: severity
    attributes:
      label: Severity
      options:
        - Critical (server crash / data loss)
        - High (major feature broken)
        - Medium (feature partially broken)
        - Low (minor / cosmetic)
    validations:
      required: true
EOF

    cat > "$B/.github/ISSUE_TEMPLATE/feature_request.yml" << 'EOF'
name: 🚀 Feature Request
description: Suggest a new endpoint, feature, or improvement
labels: ["enhancement"]
body:
  - type: textarea
    id: problem
    attributes:
      label: Problem / motivation
    validations:
      required: true
  - type: textarea
    id: solution
    attributes:
      label: Proposed solution
    validations:
      required: true
  - type: textarea
    id: api_design
    attributes:
      label: Proposed API design (if applicable)
      render: markdown
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considered
EOF

    cat > "$B/.github/ISSUE_TEMPLATE/question.yml" << 'EOF'
name: ❓ Question
description: Ask a question about the API or project
labels: ["question"]
body:
  - type: textarea
    id: question
    attributes:
      label: Your question
    validations:
      required: true
  - type: textarea
    id: context
    attributes:
      label: What have you tried?
EOF

    cat > "$B/.github/ISSUE_TEMPLATE/config.yml" << 'EOF'
blank_issues_enabled: false
EOF
  fi

  # ── PR Template ──────────────────────────────────────────────────
  if _yes "$F_PR"; then
    cat > "$B/.github/PULL_REQUEST_TEMPLATE.md" << 'EOF'
## 📋 Description

<!-- What does this PR do? Closes #? -->

## 🔄 Type of Change

- [ ] 🐛 Bug fix
- [ ] 🚀 New feature / endpoint
- [ ] 💥 Breaking change (API contract changed)
- [ ] ♻️  Refactor
- [ ] ⚡ Performance
- [ ] 🔒 Security fix
- [ ] 📝 Documentation
- [ ] 🧪 Tests only

## 🧪 Testing

- [ ] Unit tests added / updated
- [ ] Integration tests added / updated
- [ ] All tests pass locally (`npm test`)
- [ ] New endpoint tested with Postman / curl

## ✅ Checklist

- [ ] `npm run lint` passes
- [ ] No `console.log` left in code
- [ ] `.env.example` updated for new env vars
- [ ] Migration file created for schema changes
- [ ] CHANGELOG updated under `[Unreleased]`
- [ ] Swagger / API docs updated if endpoint changed

## 📸 API Response (for new/changed endpoints)

```json
POST /api/v1/example
{ "field": "value" }

Response 200
{ "success": true, "data": {} }
```

## 🔗 Related Issues / PRs
EOF
  fi

  # ── CODEOWNERS ───────────────────────────────────────────────────
  if _yes "$F_CODEOWNERS"; then
    cat > "$B/.github/CODEOWNERS" << EOF
# Global
* @${AUTHOR}

# Core infrastructure
src/config/     @${AUTHOR}
src/middleware/  @${AUTHOR}

# Database / schema
src/models/      @${AUTHOR}
src/prisma/      @${AUTHOR}

# Auth (security-sensitive)
src/services/auth.service.${EXT}     @${AUTHOR}
src/middleware/auth.middleware.${EXT} @${AUTHOR}
EOF
  fi

  # ── dependabot.yml ───────────────────────────────────────────────
  if _yes "$F_DEPENDABOT"; then
    cat > "$B/.github/dependabot.yml" << 'EOF'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
      - "automated"
    ignore:
      - dependency-name: "*"
        update-types: ["version-update:semver-major"]
EOF
  fi

  # ── GitHub Actions CI ─────────────────────────────────────────────
  if _yes "$F_CICD"; then
    cat > "$B/.github/workflows/ci.yml" << EOF
name: CI

on:
  push:
    branches: [master, develop]
  pull_request:
    branches: [master, develop]

jobs:
  lint-and-test:
    name: Lint & Test
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: password
        ports: ['5432:5432']
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:7-alpine
        ports: ['6379:6379']
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Run tests
        run: npm test
        env:
          NODE_ENV: test
          PORT: 3001
          DATABASE_URL: postgresql://postgres:password@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379
          JWT_SECRET: ci_test_secret_do_not_use_in_prod
          JWT_EXPIRES_IN: 15m

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        if: always()
        with:
          fail_ci_if_error: false
EOF

    cat > "$B/.github/workflows/cd.yml" << 'EOF'
name: CD — Deploy

on:
  push:
    branches: [master]

jobs:
  deploy:
    name: Deploy to Production
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install production dependencies
        run: npm ci --only=production

      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          port: ${{ secrets.SERVER_PORT || 22 }}
          script: |
            set -e
            cd /var/www/${{ github.event.repository.name }}
            git pull origin master
            npm ci --only=production
            npm run migrate
            pm2 reload ecosystem.config.js --env production
            echo "✓ Deployment complete"
EOF
  fi

  # ── Release Action ───────────────────────────────────────────────
  if _yes "$F_RELEASE"; then
    cat > "$B/.github/workflows/release.yml" << EOF
name: 🚀 Auto Release

on:
  push:
    tags:
      - 'v*.*.*'

permissions:
  contents: write

jobs:
  release:
    name: Create GitHub Release
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests before release
        run: npm test
        env:
          NODE_ENV: test
          JWT_SECRET: release_test_secret

      - name: Get version from tag
        id: version
        run: echo "VERSION=\${GITHUB_REF#refs/tags/}" >> \$GITHUB_OUTPUT

      - name: Generate changelog
        id: changelog
        uses: orhun/git-cliff-action@v2
        with:
          config: cliff.toml
          args: --latest --strip header
        continue-on-error: true

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: \${{ steps.version.outputs.VERSION }}
          name: "Release \${{ steps.version.outputs.VERSION }}"
          body: |
            ## What's Changed in \${{ steps.version.outputs.VERSION }}

            \${{ steps.changelog.outputs.content }}

            ---
            **Full Changelog**: https://github.com/\${{ github.repository }}/commits/\${{ steps.version.outputs.VERSION }}
          draft: false
          prerelease: \${{ contains(steps.version.outputs.VERSION, '-') }}
          generate_release_notes: true
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
EOF

    cat > "$B/cliff.toml" << 'EOF'
[changelog]
header = ""
body = """
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | upper_first }}
{% for commit in commits %}
- {{ commit.message | upper_first }}
{% endfor %}
{% endfor %}
"""
trim = true

[git]
conventional_commits = true
filter_unconventional = true
commit_parsers = [
  { message = "^feat", group = "🚀 Features" },
  { message = "^fix", group = "🐛 Bug Fixes" },
  { message = "^perf", group = "⚡ Performance" },
  { message = "^refactor", group = "♻️  Refactor" },
  { message = "^docs", group = "📝 Documentation" },
  { message = "^test", group = "🧪 Tests" },
  { message = "^chore", group = "🔧 Chores" },
]
EOF
  fi

  # ════════════════════════════════════════════════════════════════
  # PROJECT DOCS
  # ════════════════════════════════════════════════════════════════

  echo ""
  echo -e "${BOLD}${CYAN}  📝 Generating project docs...${RESET}"
  echo ""

  # ── README.md ────────────────────────────────────────────────────
  if _yes "$F_README"; then
    cat > "$B/README.md" << EOF
# ${PROJECT_NAME}

> ${LANG_LABEL} backend API — ${DB_LABEL} | ${ORM_LABEL}

[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js)](https://nodejs.org)
[![${LANG_LABEL}](https://img.shields.io/badge/${LANG_LABEL}-blue)](https://www.typescriptlang.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE.md)

---

## 🚀 Quick Start

\`\`\`bash
git clone https://github.com/${AUTHOR}/${PROJECT_NAME}.git
cd ${PROJECT_NAME}
cp .env.example .env
npm install
npm run dev
\`\`\`

Server starts at **http://localhost:3000**

---

## ⚙️ Environment Variables

| Variable | Description | Required |
|---|---|---|
| \`NODE_ENV\` | \`development\` / \`production\` / \`test\` | ✓ |
| \`PORT\` | Server port (default: \`3000\`) | ✓ |
| \`DATABASE_URL\` | ${DB_LABEL} connection string | ✓ |
| \`JWT_SECRET\` | JWT signing secret | ✓ |
| \`JWT_EXPIRES_IN\` | Access token expiry e.g. \`7d\` | ✓ |
| \`REDIS_URL\` | Redis connection URL | — |
| \`MAIL_HOST\` | SMTP host | — |
| \`CLOUDINARY_CLOUD_NAME\` | Cloudinary cloud name | — |

> Full list in [.env.example](.env.example)

---

## 📋 API Endpoints

### Auth

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| POST | \`/api/v1/auth/register\` | Register new user | — |
| POST | \`/api/v1/auth/login\` | Login, receive JWT | — |
| POST | \`/api/v1/auth/refresh\` | Refresh access token | — |
| POST | \`/api/v1/auth/logout\` | Invalidate refresh token | ✓ |
| POST | \`/api/v1/auth/forgot-password\` | Send reset email | — |
| POST | \`/api/v1/auth/reset-password\` | Reset with token | — |

### Users

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| GET | \`/api/v1/users/me\` | Current user profile | ✓ |
| PATCH | \`/api/v1/users/me\` | Update profile | ✓ |
| DELETE | \`/api/v1/users/me\` | Delete account | ✓ |
| GET | \`/api/v1/users\` | List all users | Admin |
| GET | \`/api/v1/users/:id\` | Get user by ID | Admin |
$(_yes "$F_HEALTH" && echo -e "\n### Health\n\n| Method | Endpoint | Description |\n|---|---|---|\n| GET | \`/health\` | Server health status |")

---

## 🏗️ Project Structure

\`\`\`
src/
├── config/          # env, jwt, db, redis, mail configs
├── constants/       # app constants, enums, error codes
├── controllers/     # thin request handlers
├── middleware/      # auth, error, validation, cors, rate-limit
├── models/          # ${ORM_LABEL} models / schemas
├── routes/v1/       # versioned API routes
├── services/        # all business logic
├── utils/
│   ├── helpers/     # response, token, encryption, formatters
│   ├── validators/  # request validation schemas
│   └── logger/      # winston + morgan
$(_yes "$F_JOBS"   && echo "├── jobs/            # BullMQ background workers")
$(_yes "$F_CRON"   && echo "├── cron/            # node-cron scheduled tasks")
$(_yes "$F_SOCKET" && echo "├── sockets/         # socket.io real-time handlers")
$(_yes "$F_EMAIL"  && echo "├── templates/       # handlebars email templates")
└── app.${EXT}           # express app bootstrap
server.${EXT}             # http server entry point
\`\`\`

---

## 🛠️ Commands

| Command | Description |
|---|---|
| \`npm run dev\` | Start with hot reload |
| \`npm start\` | Start production server |
| \`npm test\` | Run full test suite |
| \`npm run test:unit\` | Unit tests only |
| \`npm run lint\` | Run ESLint |
| \`npm run format\` | Run Prettier |
| \`npm run migrate\` | Apply DB migrations |
| \`npm run seed\` | Seed dev data |
$([[ "$EXT" == "ts" ]] && echo "| \`npm run build\` | Compile TypeScript |")

---

## 🐳 Docker

\`\`\`bash
docker compose up --build       # start app + db + redis
docker compose down             # stop all services
\`\`\`

---

## 🚢 Deployment

\`\`\`bash
# PM2
pm2 start ecosystem.config.js --env production

# Release via tag
git tag v1.0.0 && git push origin v1.0.0
\`\`\`

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## 🔒 Security

See [SECURITY.md](SECURITY.md)

## 📄 License

MIT — see [LICENSE.md](LICENSE.md)
EOF
    echo -e "  ${GREEN}✓${RESET} README.md"
  fi

  # ── ARCHITECTURE.md ──────────────────────────────────────────────
  if _yes "$F_ARCHITECTURE"; then
    cat > "$B/ARCHITECTURE.md" << EOF
# ${PROJECT_NAME} — Architecture

## Overview

**${PROJECT_NAME}** is a layered REST API built with ${LANG_LABEL}, ${DB_LABEL}, and ${ORM_LABEL}.

\`\`\`
HTTP Request
     │
     ▼
  Router  (src/routes/v1/)
     │
     ▼
  Middleware  (auth · validation · rate-limit · cors · logging)
     │
     ▼
  Controller  (parse → call service → respond)
     │
     ▼
  Service  (all business logic)
     │
     ▼
  Model / ${ORM_LABEL}
     │
     ▼
  ${DB_LABEL}
\`\`\`

---

## 📁 Folder Structure

\`\`\`
src/
├── config/
│   ├── env.config.${EXT}            # dotenv + env validation
│   ├── database.config.${EXT}       # ${DB_LABEL} connection
│   ├── jwt.config.${EXT}            # token options
$(_yes "$F_REDIS"  && echo "│   ├── redis.config.${EXT}          # Redis client")
$(_yes "$F_EMAIL"  && echo "│   ├── mail.config.${EXT}           # Nodemailer transport")
$(_yes "$F_UPLOAD" && echo "│   ├── cloudinary.config.${EXT}     # file storage")
$(_yes "$F_SOCKET" && echo "│   ├── socket.config.${EXT}         # socket.io")
$(_yes "$F_PUSH"   && echo "│   └── firebase.config.${EXT}       # FCM")
│
├── constants/
│   ├── app.constants.${EXT}         # app-wide constants
│   ├── error.constants.${EXT}       # error codes + messages
│   ├── message.constants.${EXT}     # API response messages
│   ├── status.constants.${EXT}      # HTTP status codes
│   ├── regex.constants.${EXT}       # shared regex patterns
│   ├── api.constants.${EXT}         # route prefixes
$(_yes "$F_RBAC" && echo "│   └── role.constants.${EXT}          # RBAC role definitions")
│
├── controllers/                     # thin — parse, delegate, respond
│   ├── auth.controller.${EXT}
│   ├── user.controller.${EXT}
$(_yes "$F_PAYMENT" && echo "│   ├── payment.controller.${EXT}")
$(_yes "$F_HEALTH"  && echo "│   └── health.controller.${EXT}")
│
├── middleware/
│   ├── error.middleware.${EXT}      # global error handler (always last)
│   ├── validation.middleware.${EXT} # Joi / Zod schema validation
│   ├── cors.middleware.${EXT}
│   ├── compression.middleware.${EXT}
$(_yes "$F_JWT"       && echo "│   ├── auth.middleware.${EXT}       # JWT verify, attach req.user")
$(_yes "$F_RBAC"      && echo "│   ├── role.middleware.${EXT}       # RBAC guard")
$(_yes "$F_UPLOAD"    && echo "│   ├── upload.middleware.${EXT}     # Multer")
$(_yes "$F_REDIS"     && echo "│   ├── cache.middleware.${EXT}      # Redis response cache")
$(_yes "$F_RATELIMIT" && echo "│   ├── rateLimit.middleware.${EXT}  # express-rate-limit")
$(_yes "$F_LOGGING"   && echo "│   └── logging.middleware.${EXT}    # Morgan HTTP logs")
│
├── models/
│   ├── User.model.${EXT}
│   └── index.${EXT}
│
├── routes/
│   ├── index.${EXT}                 # mounts v1, v2
│   ├── v1/
│   │   ├── auth.routes.${EXT}
│   │   ├── user.routes.${EXT}
$(_yes "$F_PAYMENT" && echo "│   │   ├── payment.routes.${EXT}")
$(_yes "$F_HEALTH"  && echo "│   │   └── health.routes.${EXT}")
│   └── v2/
│       └── (future)
│
├── services/                        # all business logic lives here
│   ├── auth.service.${EXT}
│   ├── user.service.${EXT}
$(_yes "$F_EMAIL"   && echo "│   ├── email.service.${EXT}")
$(_yes "$F_REDIS"   && echo "│   ├── cache.service.${EXT}")
$(_yes "$F_UPLOAD"  && echo "│   ├── fileUpload.service.${EXT}")
$(_yes "$F_PAYMENT" && echo "│   ├── payment.service.${EXT}")
$(_yes "$F_SMS"     && echo "│   ├── sms.service.${EXT}")
$(_yes "$F_PUSH"    && echo "│   ├── pushNotification.service.${EXT}")
$(_yes "$F_PDF"     && echo "│   ├── pdf.service.${EXT}")
$(_yes "$F_EXCEL"   && echo "│   └── excel.service.${EXT}")
│
├── utils/
│   ├── helpers/
│   │   ├── apiResponse.helper.${EXT}      # standard response envelope
│   │   ├── apiFeatures.helper.${EXT}      # filter / paginate / sort
│   │   ├── encryption.helper.${EXT}       # bcrypt hash/compare
│   │   ├── token.helper.${EXT}            # JWT sign/verify
│   │   ├── otp.helper.${EXT}              # OTP generation
│   │   ├── dateFormatter.helper.${EXT}
│   │   └── stringFormatter.helper.${EXT}
│   ├── validators/
│   │   ├── auth.validator.${EXT}
│   │   └── user.validator.${EXT}
$(_yes "$F_LOGGING" && echo "│   └── logger/")
$(_yes "$F_LOGGING" && echo "│       ├── logger.util.${EXT}          # Winston logger")
$(_yes "$F_LOGGING" && echo "│       └── morgan.util.${EXT}          # Morgan stream → Winston")
$(_yes "$F_JOBS" && echo "│")
$(_yes "$F_JOBS" && echo "├── jobs/                            # BullMQ workers")
$(_yes "$F_JOBS" && echo "│   ├── queue.jobs.${EXT}               # queue registration")
$(_yes "$F_JOBS" && echo "│   ├── email.job.${EXT}")
$(_yes "$F_JOBS" && echo "│   ├── notification.job.${EXT}")
$(_yes "$F_JOBS" && echo "│   └── cleanup.job.${EXT}")
$(_yes "$F_CRON" && echo "│")
$(_yes "$F_CRON" && echo "├── cron/                            # node-cron tasks")
$(_yes "$F_CRON" && echo "│   ├── cron.jobs.${EXT}")
$(_yes "$F_CRON" && echo "│   └── cleanup.cron.${EXT}")
$(_yes "$F_SOCKET" && echo "│")
$(_yes "$F_SOCKET" && echo "├── sockets/                         # socket.io real-time")
$(_yes "$F_SOCKET" && echo "│   ├── socket.handler.${EXT}")
$(_yes "$F_SOCKET" && echo "│   ├── events.handler.${EXT}")
$(_yes "$F_SOCKET" && echo "│   └── notification.socket.${EXT}")
└── app.${EXT}
server.${EXT}
\`\`\`

---

## 🔐 Auth Flow

\`\`\`
POST /auth/login
  → validate input
  → bcrypt.compare(password, hash)
  → sign accessToken (short TTL) + refreshToken (long TTL)
  → store refreshToken hash in DB

Protected routes
  → auth.middleware: extract Bearer token
  → jwt.verify signature + expiry
  → attach req.user

POST /auth/refresh
  → verify refreshToken signature
  → lookup hash in DB (rotation check)
  → issue new accessToken + rotate refreshToken
\`\`\`

---

## 🧪 Testing

| Type | Tool | Location |
|---|---|---|
| Unit | Jest + jest.fn() | \`tests/unit/\` |
| Integration | Jest + Supertest | \`tests/integration/\` |

\`\`\`bash
npm test                   # all tests
npm run test:unit          # unit only
npm test -- --coverage     # with coverage
\`\`\`

---

## ⚙️ CI / CD

| Workflow | Trigger | Action |
|---|---|---|
| \`ci.yml\` | push / PR → master, develop | Lint → Test |
| \`cd.yml\` | push → master | SSH deploy + PM2 reload |
| \`release.yml\` | push tag \`v*.*.*\` | GitHub Release + changelog |
EOF
    echo -e "  ${GREEN}✓${RESET} ARCHITECTURE.md"
  fi

  # ── CONTRIBUTING.md ──────────────────────────────────────────────
  if _yes "$F_CONTRIBUTING"; then
    cat > "$B/CONTRIBUTING.md" << EOF
# Contributing to ${PROJECT_NAME}

## Development Setup

\`\`\`bash
git clone https://github.com/${AUTHOR}/${PROJECT_NAME}.git
cd ${PROJECT_NAME}
cp .env.example .env
npm install
npm run dev
\`\`\`

## Running Tests

\`\`\`bash
npm test               # full suite
npm run test:unit      # unit only
npm test -- --coverage # with coverage report
\`\`\`

## Database Migrations

Always create a new migration for schema changes — never edit existing committed migrations:

\`\`\`bash
npm run migrate        # apply pending migrations
npm run seed           # seed dev data
\`\`\`

## Pull Request Guidelines

- One concern per PR — keep diffs small and reviewable
- Add / update tests for changed behaviour
- Update \`.env.example\` when adding new environment variables
- Update \`CHANGELOG.md\` under \`[Unreleased]\` for user-visible changes
- Run \`npm run lint && npm test\` before pushing
- Never commit \`.env\`, secrets, keystores, or build artefacts

## Coding Conventions

- Follow existing ESLint + Prettier config
- Use \`async/await\` over raw Promises
- Throw typed \`AppError\` instances — never plain \`new Error()\`
- Use \`apiResponse.helper\` for all HTTP responses
- Keep controllers thin — all logic goes in services
- Name service functions descriptively: \`createUser\`, \`sendPasswordResetEmail\`

## Commit Format (Conventional Commits)

\`\`\`
feat: add rate limiting to auth routes
fix: handle expired refresh token gracefully
docs: update environment variable table
chore: upgrade express to v5
refactor: extract token logic into token.helper
test: add integration tests for /auth/login
\`\`\`

## Contribution Licensing

By submitting a contribution, you agree it will be licensed under the MIT License.

See [TRADEMARKS.md](TRADEMARKS.md) for branding rules on forks.
EOF
    echo -e "  ${GREEN}✓${RESET} CONTRIBUTING.md"
  fi

  # ── CHANGELOG.md ─────────────────────────────────────────────────
  if _yes "$F_CHANGELOG"; then
    cat > "$B/CHANGELOG.md" << EOF
# Changelog

All notable changes to **${PROJECT_NAME}** will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

## [1.0.0] - $(date +%Y-%m-%d)
### Added
- Initial Node.js backend scaffold
- ${LANG_LABEL} + ${DB_LABEL} + ${ORM_LABEL} setup
- JWT authentication (login / register / refresh / logout)
$(_yes "$F_RBAC"   && echo "- Role-based access control (RBAC)")
$(_yes "$F_DOCKER" && echo "- Docker + docker-compose setup")
$(_yes "$F_CICD"   && echo "- GitHub Actions CI/CD pipeline")
EOF
    echo -e "  ${GREEN}✓${RESET} CHANGELOG.md"
  fi

  # ── LICENSE.md ───────────────────────────────────────────────────
  if _yes "$F_LICENSE"; then
    cat > "$B/LICENSE.md" << EOF
MIT License

Copyright (c) $(date +%Y) ${AUTHOR}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
    echo -e "  ${GREEN}✓${RESET} LICENSE.md"
  fi

  # ── SECURITY.md ──────────────────────────────────────────────────
  if _yes "$F_SECURITY"; then
    cat > "$B/SECURITY.md" << EOF
# Security Policy

## Supported Versions

Security fixes are prioritised for the latest code on \`master\` and the most recent public release.

## Reporting a Vulnerability

Report privately by email to **${CONTACT_EMAIL}** — do not open a public GitHub issue.

Include:
- Description of the vulnerability
- Steps to reproduce / proof-of-concept
- Affected version, branch, or commit
- Potential impact

## In Scope

- Authentication / authorisation flaws (JWT issues, broken RBAC)
- SQL / NoSQL injection
- SSRF, RCE, IDOR
- Sensitive data exposure via API responses

## Out of Scope

- DoS via high request volume (rate limiting is in place)
- Issues in unpatched upstream dependencies
- Missing headers on non-production environments

## Response

We will acknowledge within 72 hours and credit reporters in the changelog upon release.
EOF
    echo -e "  ${GREEN}✓${RESET} SECURITY.md"
  fi

  # ── CODE_OF_CONDUCT.md ───────────────────────────────────────────
  if _yes "$F_CODE_OF_CONDUCT"; then
    cat > "$B/CODE_OF_CONDUCT.md" << EOF
# Code of Conduct

## Our Commitment

**${PROJECT_NAME}** is committed to a welcoming, respectful, and constructive community.

## Expected Behavior

- Be respectful and professional
- Assume good intent; discuss ideas without attacking people
- Offer constructive, actionable feedback
- Welcome questions from contributors of all levels
- Respect project boundaries and maintainers' time

## Unacceptable Behavior

- Harassment, discrimination, or hateful conduct
- Personal attacks, insults, or intimidation
- Deliberate disruption or bad-faith engagement
- Sharing private information without permission

## Reporting

Report incidents privately to **${CONTACT_EMAIL}**.

## Enforcement

Maintainers may remove content, reject contributions, or restrict participation
for violations of this Code of Conduct.
EOF
    echo -e "  ${GREEN}✓${RESET} CODE_OF_CONDUCT.md"
  fi

  # ── ABOUT.md ─────────────────────────────────────────────────────
  if _yes "$F_ABOUT"; then
    cat > "$B/ABOUT.md" << EOF
# About ${PROJECT_NAME}

**Last Updated:** $(date +"%B %d, %Y")

**${PROJECT_NAME}** is an open-source Node.js REST API built with **${LANG_LABEL}**,
**${DB_LABEL}**, and **${ORM_LABEL}**.

## Stack at a Glance

| Category       | Choice              |
|----------------|---------------------|
| Language       | ${LANG_LABEL}       |
| Database       | ${DB_LABEL}         |
| ORM / Driver   | ${ORM_LABEL}        |
| Auth           | JWT (access + refresh) |
$(_yes "$F_REDIS"   && echo "| Cache          | Redis               |")
$(_yes "$F_JOBS"    && echo "| Queue          | BullMQ + Redis      |")
$(_yes "$F_LOGGING" && echo "| Logging        | Winston + Morgan    |")

## Features

- RESTful API with versioned routes (\`/api/v1\`, \`/api/v2\`)
- JWT authentication with refresh token rotation
$(_yes "$F_RBAC"    && echo "- Role-based access control (RBAC)")
$(_yes "$F_SOCKET"  && echo "- Real-time WebSockets via Socket.io")
$(_yes "$F_JOBS"    && echo "- Background job processing via BullMQ")
$(_yes "$F_EMAIL"   && echo "- Transactional email via Nodemailer")
$(_yes "$F_UPLOAD"  && echo "- File upload support (Multer + Cloudinary)")
$(_yes "$F_REDIS"   && echo "- Redis caching layer")
$(_yes "$F_TESTING" && echo "- Jest + Supertest test suite")
$(_yes "$F_DOCKER"  && echo "- Docker + docker-compose")
$(_yes "$F_CICD"    && echo "- GitHub Actions CI/CD")

## Contact

**${CONTACT_EMAIL}**
EOF
    echo -e "  ${GREEN}✓${RESET} ABOUT.md"
  fi

  # ── NOTICE.md ────────────────────────────────────────────────────
  if _yes "$F_NOTICE"; then
    cat > "$B/NOTICE.md" << EOF
${PROJECT_NAME}
Copyright (c) $(date +%Y) ${AUTHOR}

This repository's source code and documentation are licensed under the MIT
License unless otherwise noted.

The ${PROJECT_NAME} name, logo, and branding are reserved and may not be used
to imply endorsement or official project status for modified forks or
redistributions. See LICENSE.md and TRADEMARKS.md for details.
EOF
    echo -e "  ${GREEN}✓${RESET} NOTICE.md"
  fi

  # ── TRADEMARKS.md ────────────────────────────────────────────────
  if _yes "$F_TRADEMARKS"; then
    cat > "$B/TRADEMARKS.md" << EOF
# Trademarks and Branding

**${PROJECT_NAME}** is open source, but open source code does not automatically
grant branding rights.

## What the MIT License Covers

The [MIT License](LICENSE.md) applies to source code and documentation.

## What Is Reserved

- The \`${PROJECT_NAME}\` project name when used to imply official status
- The ${PROJECT_NAME} logo, icon, and branded visual identity
- Any presentation suggesting endorsement by the original maintainers

## What You May Do

- Fork and modify the code under the MIT License
- Credit ${PROJECT_NAME} as the upstream project in your fork

## What You May Not Do

- Ship a modified fork as the official ${PROJECT_NAME} API
- Reuse the name or branding in a way that confuses users
- Remove copyright or license notices from source files

For special-case branding requests, contact **${CONTACT_EMAIL}**.
EOF
    echo -e "  ${GREEN}✓${RESET} TRADEMARKS.md"
  fi

  # ════════════════════════════════════════════════════════════════
  # DONE
  # ════════════════════════════════════════════════════════════════
  echo ""
  local DIR_COUNT FILE_COUNT
  DIR_COUNT=$(find "${B}" -type d | wc -l | tr -d ' ')
  FILE_COUNT=$(find "${B}" -type f | wc -l | tr -d ' ')

  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${GREEN}║   ✅  '${PROJECT_NAME}' scaffolded successfully!             ${RESET}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${DIM}📁 Folders : ${WHITE}${DIR_COUNT}${RESET}"
  echo -e "  ${DIM}📄 Files   : ${WHITE}${FILE_COUNT}${RESET}"
  echo ""
  echo -e "${BOLD}${YELLOW}  ⚡ Next steps:${RESET}"
  echo -e "  ${GREEN}cd ${PROJECT_NAME}${RESET}"
  echo -e "  ${GREEN}npm install${RESET}"
  echo -e "  ${GREEN}cp .env.example .env${RESET}   ${DIM}# then fill in your values${RESET}"
  echo -e "  ${GREEN}npm run dev${RESET}"
  echo ""
  if _yes "$F_RELEASE"; then
    echo -e "${BOLD}${YELLOW}  🏷️  To create a release:${RESET}"
    echo -e "  ${GREEN}git tag v1.0.0 && git push origin v1.0.0${RESET}   ${DIM}# triggers auto release${RESET}"
    echo ""
  fi
}
