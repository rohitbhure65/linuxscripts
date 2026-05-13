#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# mkdocs — Interactive Universal Project Docs & GitHub Files Generator
#
# INSTALL:
#   echo 'source ~/.mkdocs.sh' >> ~/.bashrc
#   source ~/.bashrc
#
# USAGE:
#   mkdocs
# ─────────────────────────────────────────────────────────────────

mkdocs() {

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

  # ── Helpers ──────────────────────────────────────────────────────
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

  _yes() { [[ "$1" == "y" ]]; }

  _choose() {
    local PROMPT="$1"
    local MIN="$2"
    local MAX="$3"
    local VAR_NAME="$4"
    local _VAL
    while true; do
      read -rp "  ${PROMPT} [${MIN}-${MAX}] (default ${MIN}): " _VAL
      _VAL="${_VAL:-$MIN}"
      if [[ "$_VAL" =~ ^[0-9]+$ ]] && (( _VAL >= MIN && _VAL <= MAX )); then
        break
      else
        echo -e "  ${RED}Invalid option. Please choose between ${MIN} and ${MAX}.${RESET}"
      fi
    done
    printf -v "$VAR_NAME" '%s' "$_VAL"
  }

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
  echo -e "${BOLD}${CYAN}║   🚀  mkdocs — Universal Project Docs & GitHub Files Tool    ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  # ════════════════════════════════════════════════════════════════
  # STEP 0: Project Info
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 0: Project Info ──────────────────────────────────────${RESET}"

  # Re-run guard
  if [[ -f "./package.json" ]]; then
    echo -e "  ${RED}⚠  package.json already exists in this directory.${RESET}"
    echo -e "  ${DIM}  Running mkdocs here may overwrite existing files.${RESET}"
    local _OVERWRITE
    read -rp "  Continue anyway? [y/N]: " _OVERWRITE
    _OVERWRITE="${_OVERWRITE:-n}"
    _OVERWRITE="${_OVERWRITE,,}"
    [[ "$_OVERWRITE" != "y" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
    echo ""
  fi

  CURRENT_DIR_NAME=$(basename "$(pwd)")
  PROJECT_NAME=$(echo "$CURRENT_DIR_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9_-' '-' | sed 's/^-//;s/-$//')
  [[ -z "$PROJECT_NAME" ]] && PROJECT_NAME="my-project"

  local _INPUT_NAME
  read -rp "  Project name [${PROJECT_NAME}]: " _INPUT_NAME
  [[ -n "$_INPUT_NAME" ]] && PROJECT_NAME="$_INPUT_NAME"

  local _INPUT_DESC
  read -rp "  Short description [A modern project]: " _INPUT_DESC
  PROJECT_DESC="${_INPUT_DESC:-A modern project}"

  local _INPUT_AUTHOR
  read -rp "  Author name / GitHub username: " _INPUT_AUTHOR
  AUTHOR="${_INPUT_AUTHOR:-your-username}"

  local _INPUT_EMAIL
  read -rp "  Contact email [${AUTHOR}@example.com]: " _INPUT_EMAIL
  CONTACT_EMAIL="${_INPUT_EMAIL:-${AUTHOR}@example.com}"

  echo -e "  ${GREEN}✓ Project : ${CYAN}${PROJECT_NAME}${RESET}"
  echo -e "  ${GREEN}✓ Author  : ${CYAN}${AUTHOR}${RESET}"
  echo ""

  # ════════════════════════════════════════════════════════════════
  # STEP 1: Project Type
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 1: Project Type ──────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${GREEN}1)${RESET} Frontend Web App"
  echo -e "  ${GREEN}2)${RESET} Backend API / Server"
  echo -e "  ${GREEN}3)${RESET} Full-Stack Web App"
  echo -e "  ${GREEN}4)${RESET} Mobile App"
  echo -e "  ${GREEN}5)${RESET} CLI Tool / Script"
  echo -e "  ${GREEN}6)${RESET} Library / Package"
  echo ""
  _choose "Project Type" 1 6 PROJ_TYPE_CHOICE
  echo ""

  case "$PROJ_TYPE_CHOICE" in
    1) PROJECT_TYPE="Frontend Web App" ;;
    2) PROJECT_TYPE="Backend API" ;;
    3) PROJECT_TYPE="Full-Stack Web App" ;;
    4) PROJECT_TYPE="Mobile App" ;;
    5) PROJECT_TYPE="CLI Tool" ;;
    6) PROJECT_TYPE="Library / Package" ;;
  esac

  # ════════════════════════════════════════════════════════════════
  # STEP 1b: Tech Stack (project-type aware menus)
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 1b: Tech Stack ───────────────────────────────────────${RESET}"
  echo ""

  TECH_LANG=""
  TECH_FRAMEWORK=""
  TECH_RUNTIME=""
  CI_SETUP_CMD=""
  CI_LINT_CMD=""
  CI_TEST_CMD=""
  CI_NODE_VERSION="20"

  case "$PROJ_TYPE_CHOICE" in

    # ── Frontend Web App ─────────────────────────────────────────
    1)
      echo -e "  ${BOLD}${MAGENTA}Language:${RESET}"
      echo -e "  ${GREEN}1)${RESET} JavaScript (JS only)"
      echo -e "  ${GREEN}2)${RESET} TypeScript (TS only)"
      echo -e "  ${GREEN}3)${RESET} JavaScript + TypeScript (mixed)"
      echo ""
      _choose "Language" 1 3 _LANG_CHOICE
      echo ""

      case "$_LANG_CHOICE" in
        1) TECH_LANG="JavaScript" ;;
        2) TECH_LANG="TypeScript" ;;
        3) TECH_LANG="JavaScript + TypeScript" ;;
      esac

      echo -e "  ${BOLD}${MAGENTA}Framework:${RESET}"
      echo -e "  ${GREEN}1)${RESET} React"
      echo -e "  ${GREEN}2)${RESET} Vue.js"
      echo -e "  ${GREEN}3)${RESET} Next.js"
      echo -e "  ${GREEN}4)${RESET} Nuxt.js"
      echo -e "  ${GREEN}5)${RESET} SvelteKit"
      echo -e "  ${GREEN}6)${RESET} Astro"
      echo -e "  ${GREEN}7)${RESET} Vanilla (no framework)"
      echo -e "  ${GREEN}8)${RESET} Other / Not specified"
      echo ""
      _choose "Framework" 1 8 _FW_CHOICE
      echo ""

      case "$_FW_CHOICE" in
        1) TECH_FRAMEWORK="React" ;;
        2) TECH_FRAMEWORK="Vue.js" ;;
        3) TECH_FRAMEWORK="Next.js" ;;
        4) TECH_FRAMEWORK="Nuxt.js" ;;
        5) TECH_FRAMEWORK="SvelteKit" ;;
        6) TECH_FRAMEWORK="Astro" ;;
        7) TECH_FRAMEWORK="Vanilla JS/HTML/CSS" ;;
        8) TECH_FRAMEWORK="Not specified" ;;
      esac

      TECH_RUNTIME="Node.js (build tooling)"
      CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
      CI_LINT_CMD="npm run lint"
      CI_TEST_CMD="npm run test"
      MAIN_TECH="${TECH_LANG} / ${TECH_FRAMEWORK}"
      ;;

    # ── Backend API ───────────────────────────────────────────────
    2)
      echo -e "  ${BOLD}${MAGENTA}Language:${RESET}"
      echo -e "  ${GREEN}1)${RESET} JavaScript only  ${DIM}(CommonJS / ESM)${RESET}"
      echo -e "  ${GREEN}2)${RESET} TypeScript only"
      echo -e "  ${GREEN}3)${RESET} JavaScript + Node.js  ${DIM}(plain Node, no TS)${RESET}"
      echo -e "  ${GREEN}4)${RESET} TypeScript + Node.js"
      echo -e "  ${GREEN}5)${RESET} Python"
      echo -e "  ${GREEN}6)${RESET} Go"
      echo -e "  ${GREEN}7)${RESET} Rust"
      echo -e "  ${GREEN}8)${RESET} Java / Kotlin"
      echo -e "  ${GREEN}9)${RESET} Other / Not specified"
      echo ""
      _choose "Language" 1 9 _LANG_CHOICE
      echo ""

      case "$_LANG_CHOICE" in
        1) TECH_LANG="JavaScript"
           TECH_RUNTIME="Node.js"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        2) TECH_LANG="TypeScript"
           TECH_RUNTIME="Node.js"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        3) TECH_LANG="JavaScript"
           TECH_RUNTIME="Node.js"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        4) TECH_LANG="TypeScript"
           TECH_RUNTIME="Node.js"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        5) TECH_LANG="Python"
           TECH_RUNTIME="Python"
           CI_SETUP_CMD="uses: actions/setup-python@v5\n        with:\n          python-version: '3.12'"
           CI_LINT_CMD="ruff check ."
           CI_TEST_CMD="pytest" ;;
        6) TECH_LANG="Go"
           TECH_RUNTIME="Go"
           CI_SETUP_CMD="uses: actions/setup-go@v5\n        with:\n          go-version: '1.22'"
           CI_LINT_CMD="go vet ./..."
           CI_TEST_CMD="go test ./..." ;;
        7) TECH_LANG="Rust"
           TECH_RUNTIME="Rust"
           CI_SETUP_CMD="uses: dtolnay/rust-toolchain@stable"
           CI_LINT_CMD="cargo clippy"
           CI_TEST_CMD="cargo test" ;;
        8) TECH_LANG="Java / Kotlin"
           TECH_RUNTIME="JVM"
           CI_SETUP_CMD="uses: actions/setup-java@v4\n        with:\n          distribution: 'temurin'\n          java-version: '21'"
           CI_LINT_CMD="./gradlew check"
           CI_TEST_CMD="./gradlew test" ;;
        9) TECH_LANG="Not specified"
           TECH_RUNTIME="Not specified"
           CI_LINT_CMD="# add lint command"
           CI_TEST_CMD="# add test command" ;;
      esac

      # Framework sub-menu for JS/TS backend
      if [[ "$_LANG_CHOICE" =~ ^[1-4]$ ]]; then
        echo -e "  ${BOLD}${MAGENTA}Framework:${RESET}"
        echo -e "  ${GREEN}1)${RESET} Express.js"
        echo -e "  ${GREEN}2)${RESET} Fastify"
        echo -e "  ${GREEN}3)${RESET} NestJS"
        echo -e "  ${GREEN}4)${RESET} Hono"
        echo -e "  ${GREEN}5)${RESET} Koa"
        echo -e "  ${GREEN}6)${RESET} Plain Node.js (no framework)"
        echo -e "  ${GREEN}7)${RESET} Other / Not specified"
        echo ""
        _choose "Framework" 1 7 _FW_CHOICE
        echo ""
        case "$_FW_CHOICE" in
          1) TECH_FRAMEWORK="Express.js" ;;
          2) TECH_FRAMEWORK="Fastify" ;;
          3) TECH_FRAMEWORK="NestJS" ;;
          4) TECH_FRAMEWORK="Hono" ;;
          5) TECH_FRAMEWORK="Koa" ;;
          6) TECH_FRAMEWORK="Plain Node.js" ;;
          7) TECH_FRAMEWORK="Not specified" ;;
        esac
      elif [[ "$_LANG_CHOICE" == "5" ]]; then
        echo -e "  ${BOLD}${MAGENTA}Framework:${RESET}"
        echo -e "  ${GREEN}1)${RESET} FastAPI"
        echo -e "  ${GREEN}2)${RESET} Django"
        echo -e "  ${GREEN}3)${RESET} Flask"
        echo -e "  ${GREEN}4)${RESET} Other / Not specified"
        echo ""
        _choose "Framework" 1 4 _FW_CHOICE
        echo ""
        case "$_FW_CHOICE" in
          1) TECH_FRAMEWORK="FastAPI" ;;
          2) TECH_FRAMEWORK="Django" ;;
          3) TECH_FRAMEWORK="Flask" ;;
          4) TECH_FRAMEWORK="Not specified" ;;
        esac
      else
        TECH_FRAMEWORK=""
      fi

      MAIN_TECH="${TECH_LANG}${TECH_FRAMEWORK:+ / ${TECH_FRAMEWORK}}"
      ;;

    # ── Full-Stack ─────────────────────────────────────────────────
    3)
      echo -e "  ${BOLD}${MAGENTA}Language:${RESET}"
      echo -e "  ${GREEN}1)${RESET} JavaScript only"
      echo -e "  ${GREEN}2)${RESET} TypeScript only"
      echo -e "  ${GREEN}3)${RESET} JavaScript + TypeScript (mixed)"
      echo ""
      _choose "Language" 1 3 _LANG_CHOICE
      echo ""
      case "$_LANG_CHOICE" in
        1) TECH_LANG="JavaScript" ;;
        2) TECH_LANG="TypeScript" ;;
        3) TECH_LANG="JavaScript + TypeScript" ;;
      esac

      echo -e "  ${BOLD}${MAGENTA}Stack / Framework:${RESET}"
      echo -e "  ${GREEN}1)${RESET} Next.js (App Router)"
      echo -e "  ${GREEN}2)${RESET} Nuxt.js"
      echo -e "  ${GREEN}3)${RESET} SvelteKit"
      echo -e "  ${GREEN}4)${RESET} Remix"
      echo -e "  ${GREEN}5)${RESET} T3 Stack  ${DIM}(Next + tRPC + Prisma + Tailwind)${RESET}"
      echo -e "  ${GREEN}6)${RESET} React + Express  ${DIM}(separate frontend/backend)${RESET}"
      echo -e "  ${GREEN}7)${RESET} Vue + Node.js  ${DIM}(separate frontend/backend)${RESET}"
      echo -e "  ${GREEN}8)${RESET} Other / Not specified"
      echo ""
      _choose "Stack" 1 8 _FW_CHOICE
      echo ""
      case "$_FW_CHOICE" in
        1) TECH_FRAMEWORK="Next.js" ;;
        2) TECH_FRAMEWORK="Nuxt.js" ;;
        3) TECH_FRAMEWORK="SvelteKit" ;;
        4) TECH_FRAMEWORK="Remix" ;;
        5) TECH_FRAMEWORK="T3 Stack" ;;
        6) TECH_FRAMEWORK="React + Express" ;;
        7) TECH_FRAMEWORK="Vue + Node.js" ;;
        8) TECH_FRAMEWORK="Not specified" ;;
      esac

      TECH_RUNTIME="Node.js"
      CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
      CI_LINT_CMD="npm run lint"
      CI_TEST_CMD="npm test"
      MAIN_TECH="${TECH_LANG} / ${TECH_FRAMEWORK}"
      ;;

    # ── Mobile App ─────────────────────────────────────────────────
    4)
      echo -e "  ${BOLD}${MAGENTA}Platform / Stack:${RESET}"
      echo -e "  ${GREEN}1)${RESET} Flutter  ${DIM}(Dart)${RESET}"
      echo -e "  ${GREEN}2)${RESET} React Native  ${DIM}(JavaScript)${RESET}"
      echo -e "  ${GREEN}3)${RESET} React Native  ${DIM}(TypeScript)${RESET}"
      echo -e "  ${GREEN}4)${RESET} Expo  ${DIM}(React Native + managed workflow)${RESET}"
      echo -e "  ${GREEN}5)${RESET} Native iOS  ${DIM}(Swift)${RESET}"
      echo -e "  ${GREEN}6)${RESET} Native Android  ${DIM}(Kotlin)${RESET}"
      echo -e "  ${GREEN}7)${RESET} Other / Not specified"
      echo ""
      _choose "Platform" 1 7 _MOB_CHOICE
      echo ""
      case "$_MOB_CHOICE" in
        1) TECH_LANG="Dart"
           TECH_FRAMEWORK="Flutter"
           CI_SETUP_CMD="uses: subosito/flutter-action@v2\n        with:\n          flutter-version: 'stable'"
           CI_LINT_CMD="flutter analyze"
           CI_TEST_CMD="flutter test" ;;
        2) TECH_LANG="JavaScript"
           TECH_FRAMEWORK="React Native"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        3) TECH_LANG="TypeScript"
           TECH_FRAMEWORK="React Native"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        4) TECH_LANG="JavaScript / TypeScript"
           TECH_FRAMEWORK="Expo"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npx expo lint"
           CI_TEST_CMD="npm test" ;;
        5) TECH_LANG="Swift"
           TECH_FRAMEWORK="iOS (UIKit / SwiftUI)"
           CI_SETUP_CMD="# Requires macOS runner\n      # runs-on: macos-latest"
           CI_LINT_CMD="swiftlint"
           CI_TEST_CMD="xcodebuild test -scheme MyApp" ;;
        6) TECH_LANG="Kotlin"
           TECH_FRAMEWORK="Android"
           CI_SETUP_CMD="uses: actions/setup-java@v4\n        with:\n          distribution: 'temurin'\n          java-version: '21'"
           CI_LINT_CMD="./gradlew lint"
           CI_TEST_CMD="./gradlew test" ;;
        7) TECH_LANG="Not specified"
           TECH_FRAMEWORK="Not specified"
           CI_LINT_CMD="# add lint command"
           CI_TEST_CMD="# add test command" ;;
      esac
      MAIN_TECH="${TECH_LANG} / ${TECH_FRAMEWORK}"
      ;;

    # ── CLI Tool ──────────────────────────────────────────────────
    5)
      echo -e "  ${BOLD}${MAGENTA}Language:${RESET}"
      echo -e "  ${GREEN}1)${RESET} JavaScript only  ${DIM}(Node.js CLI)${RESET}"
      echo -e "  ${GREEN}2)${RESET} TypeScript  ${DIM}(Node.js CLI)${RESET}"
      echo -e "  ${GREEN}3)${RESET} Python"
      echo -e "  ${GREEN}4)${RESET} Go"
      echo -e "  ${GREEN}5)${RESET} Rust"
      echo -e "  ${GREEN}6)${RESET} Bash / Shell"
      echo -e "  ${GREEN}7)${RESET} Other / Not specified"
      echo ""
      _choose "Language" 1 7 _LANG_CHOICE
      echo ""
      case "$_LANG_CHOICE" in
        1) TECH_LANG="JavaScript"
           TECH_RUNTIME="Node.js"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        2) TECH_LANG="TypeScript"
           TECH_RUNTIME="Node.js"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        3) TECH_LANG="Python"
           TECH_RUNTIME="Python"
           CI_SETUP_CMD="uses: actions/setup-python@v5\n        with:\n          python-version: '3.12'"
           CI_LINT_CMD="ruff check ."
           CI_TEST_CMD="pytest" ;;
        4) TECH_LANG="Go"
           TECH_RUNTIME="Go"
           CI_SETUP_CMD="uses: actions/setup-go@v5\n        with:\n          go-version: '1.22'"
           CI_LINT_CMD="go vet ./..."
           CI_TEST_CMD="go test ./..." ;;
        5) TECH_LANG="Rust"
           TECH_RUNTIME="Rust"
           CI_SETUP_CMD="uses: dtolnay/rust-toolchain@stable"
           CI_LINT_CMD="cargo clippy"
           CI_TEST_CMD="cargo test" ;;
        6) TECH_LANG="Bash / Shell"
           TECH_RUNTIME="Bash"
           CI_SETUP_CMD="# No special setup needed for shell scripts"
           CI_LINT_CMD="shellcheck *.sh"
           CI_TEST_CMD="bats tests/" ;;
        7) TECH_LANG="Not specified"
           TECH_RUNTIME="Not specified"
           CI_LINT_CMD="# add lint command"
           CI_TEST_CMD="# add test command" ;;
      esac
      MAIN_TECH="${TECH_LANG}${TECH_RUNTIME:+ (${TECH_RUNTIME})}"
      ;;

    # ── Library / Package ─────────────────────────────────────────
    6)
      echo -e "  ${BOLD}${MAGENTA}Language:${RESET}"
      echo -e "  ${GREEN}1)${RESET} JavaScript only  ${DIM}(npm package)${RESET}"
      echo -e "  ${GREEN}2)${RESET} TypeScript  ${DIM}(npm package)${RESET}"
      echo -e "  ${GREEN}3)${RESET} JavaScript + TypeScript  ${DIM}(dual package)${RESET}"
      echo -e "  ${GREEN}4)${RESET} Python  ${DIM}(PyPI package)${RESET}"
      echo -e "  ${GREEN}5)${RESET} Go  ${DIM}(Go module)${RESET}"
      echo -e "  ${GREEN}6)${RESET} Rust  ${DIM}(crates.io)${RESET}"
      echo -e "  ${GREEN}7)${RESET} Flutter / Dart  ${DIM}(pub.dev package)${RESET}"
      echo -e "  ${GREEN}8)${RESET} Other / Not specified"
      echo ""
      _choose "Language" 1 8 _LANG_CHOICE
      echo ""
      case "$_LANG_CHOICE" in
        1) TECH_LANG="JavaScript"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        2) TECH_LANG="TypeScript"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        3) TECH_LANG="JavaScript + TypeScript"
           CI_SETUP_CMD="uses: actions/setup-node@v4\n        with:\n          node-version: '${CI_NODE_VERSION}'\n          cache: 'npm'"
           CI_LINT_CMD="npm run lint"
           CI_TEST_CMD="npm test" ;;
        4) TECH_LANG="Python"
           CI_SETUP_CMD="uses: actions/setup-python@v5\n        with:\n          python-version: '3.12'"
           CI_LINT_CMD="ruff check ."
           CI_TEST_CMD="pytest" ;;
        5) TECH_LANG="Go"
           CI_SETUP_CMD="uses: actions/setup-go@v5\n        with:\n          go-version: '1.22'"
           CI_LINT_CMD="go vet ./..."
           CI_TEST_CMD="go test ./..." ;;
        6) TECH_LANG="Rust"
           CI_SETUP_CMD="uses: dtolnay/rust-toolchain@stable"
           CI_LINT_CMD="cargo clippy"
           CI_TEST_CMD="cargo test" ;;
        7) TECH_LANG="Dart"
           TECH_FRAMEWORK="Flutter"
           CI_SETUP_CMD="uses: subosito/flutter-action@v2\n        with:\n          flutter-version: 'stable'"
           CI_LINT_CMD="dart analyze"
           CI_TEST_CMD="dart test" ;;
        8) TECH_LANG="Not specified"
           CI_LINT_CMD="# add lint command"
           CI_TEST_CMD="# add test command" ;;
      esac
      MAIN_TECH="${TECH_LANG}"
      ;;
  esac

  # ── Database ─────────────────────────────────────────────────────
  echo -e "  ${BOLD}${MAGENTA}Database / Storage:${RESET}"
  echo -e "  ${GREEN}1)${RESET} None"
  echo -e "  ${GREEN}2)${RESET} PostgreSQL"
  echo -e "  ${GREEN}3)${RESET} MySQL / MariaDB"
  echo -e "  ${GREEN}4)${RESET} MongoDB"
  echo -e "  ${GREEN}5)${RESET} SQLite"
  echo -e "  ${GREEN}6)${RESET} Redis"
  echo -e "  ${GREEN}7)${RESET} Firebase / Firestore"
  echo -e "  ${GREEN}8)${RESET} Supabase"
  echo -e "  ${GREEN}9)${RESET} Other / Not specified"
  echo ""
  _choose "Database" 1 9 _DB_CHOICE
  echo ""
  case "$_DB_CHOICE" in
    1) DB_LABEL="None" ;;
    2) DB_LABEL="PostgreSQL" ;;
    3) DB_LABEL="MySQL / MariaDB" ;;
    4) DB_LABEL="MongoDB" ;;
    5) DB_LABEL="SQLite" ;;
    6) DB_LABEL="Redis" ;;
    7) DB_LABEL="Firebase / Firestore" ;;
    8) DB_LABEL="Supabase" ;;
    9)
      local _DB_OTHER
      read -rp "  Specify database/storage: " _DB_OTHER
      DB_LABEL="${_DB_OTHER:-Not specified}"
      ;;
  esac

  # ════════════════════════════════════════════════════════════════
  # STEP 2: Generation Mode
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 2: What to Generate ──────────────────────────────────${RESET}"
  echo -e "  ${GREEN}1)${RESET} Everything                   ${DIM}— all docs + .github files${RESET}"
  echo -e "  ${GREEN}2)${RESET} Root markdown docs only      ${DIM}— README, CONTRIBUTING, LICENSE, etc.${RESET}"
  echo -e "  ${GREEN}3)${RESET} .github/ folder only         ${DIM}— workflows, templates, CODEOWNERS${RESET}"
  echo -e "  ${GREEN}4)${RESET} Pick files individually      ${DIM}— choose each file yourself${RESET}"
  echo ""
  _choose "Mode" 1 4 GEN_MODE
  echo ""

  # ════════════════════════════════════════════════════════════════
  # STEP 3: File Selection
  # ════════════════════════════════════════════════════════════════
  F_README="n"; F_ARCHITECTURE="n"; F_CONTRIBUTING="n"; F_CHANGELOG="n"
  F_LICENSE="n"; F_SECURITY="n"; F_CODE_OF_CONDUCT="n"; F_ABOUT="n"
  F_NOTICE="n"; F_TRADEMARKS="n"
  F_CODEOWNERS="n"; F_PR_TEMPLATE="n"; F_DEPENDABOT="n"
  F_BUG_ISSUE="n"; F_FEATURE_ISSUE="n"; F_QUESTION_ISSUE="n"
  F_CI="n"; F_CD="n"; F_RELEASE="n"

  case "$GEN_MODE" in
    1)
      F_README="y"; F_ARCHITECTURE="y"; F_CONTRIBUTING="y"; F_CHANGELOG="y"
      F_LICENSE="y"; F_SECURITY="y"; F_CODE_OF_CONDUCT="y"; F_ABOUT="y"
      F_NOTICE="y"; F_TRADEMARKS="y"
      F_CODEOWNERS="y"; F_PR_TEMPLATE="y"; F_DEPENDABOT="y"
      F_BUG_ISSUE="y"; F_FEATURE_ISSUE="y"; F_QUESTION_ISSUE="y"
      F_CI="y"; F_CD="y"; F_RELEASE="y"
      ;;
    2)
      echo -e "${BOLD}${YELLOW}── Step 3: Select Root Docs ──────────────────────────────────${RESET}"
      echo -e "${DIM}  Press ENTER to accept default (y). Enter n to skip.${RESET}"
      echo ""
      _ask "README.md"              F_README
      _ask "ARCHITECTURE.md"        F_ARCHITECTURE
      _ask "CONTRIBUTING.md"        F_CONTRIBUTING
      _ask "CHANGELOG.md"           F_CHANGELOG
      _ask "LICENSE.md"             F_LICENSE
      _ask "SECURITY.md"            F_SECURITY
      _ask "CODE_OF_CONDUCT.md"     F_CODE_OF_CONDUCT
      _ask "ABOUT.md"               F_ABOUT
      _ask "NOTICE.md"              F_NOTICE
      _ask "TRADEMARKS.md"          F_TRADEMARKS
      echo ""
      ;;
    3)
      echo -e "${BOLD}${YELLOW}── Step 3: Select .github Files ──────────────────────────────${RESET}"
      echo -e "${DIM}  Press ENTER to accept default (y). Enter n to skip.${RESET}"
      echo ""
      echo -e "  ${BOLD}${MAGENTA}[ Issue Templates ]${RESET}"
      _ask "Bug report template"            F_BUG_ISSUE
      _ask "Feature request template"       F_FEATURE_ISSUE
      _ask "Question template"              F_QUESTION_ISSUE
      echo ""
      echo -e "  ${BOLD}${MAGENTA}[ GitHub Files ]${RESET}"
      _ask "PULL_REQUEST_TEMPLATE.md"       F_PR_TEMPLATE
      _ask "CODEOWNERS"                     F_CODEOWNERS
      _ask "dependabot.yml"                 F_DEPENDABOT
      echo ""
      echo -e "  ${BOLD}${MAGENTA}[ GitHub Actions Workflows ]${RESET}"
      _ask "ci.yml  (lint + test)"          F_CI
      _ask "cd.yml  (deploy on push)"       F_CD
      _ask "release.yml (auto release tag)" F_RELEASE
      echo ""
      ;;
    4)
      echo -e "${BOLD}${YELLOW}── Step 3: Individual File Selection ─────────────────────────${RESET}"
      echo -e "${DIM}  Press ENTER to accept default (y). Enter n to skip.${RESET}"
      echo ""
      echo -e "  ${BOLD}${MAGENTA}[ Root Markdown Docs ]${RESET}"
      _ask "README.md"              F_README
      _ask "ARCHITECTURE.md"        F_ARCHITECTURE
      _ask "CONTRIBUTING.md"        F_CONTRIBUTING
      _ask "CHANGELOG.md"           F_CHANGELOG
      _ask "LICENSE.md"             F_LICENSE
      _ask "SECURITY.md"            F_SECURITY
      _ask "CODE_OF_CONDUCT.md"     F_CODE_OF_CONDUCT
      _ask "ABOUT.md"               F_ABOUT
      _ask "NOTICE.md"              F_NOTICE
      _ask "TRADEMARKS.md"          F_TRADEMARKS
      echo ""
      echo -e "  ${BOLD}${MAGENTA}[ .github — Issue Templates ]${RESET}"
      _ask "Bug report template"            F_BUG_ISSUE
      _ask "Feature request template"       F_FEATURE_ISSUE
      _ask "Question template"              F_QUESTION_ISSUE
      echo ""
      echo -e "  ${BOLD}${MAGENTA}[ .github — Files ]${RESET}"
      _ask "PULL_REQUEST_TEMPLATE.md"       F_PR_TEMPLATE
      _ask "CODEOWNERS"                     F_CODEOWNERS
      _ask "dependabot.yml"                 F_DEPENDABOT
      echo ""
      echo -e "  ${BOLD}${MAGENTA}[ .github — Workflows ]${RESET}"
      _ask "ci.yml  (lint + test)"          F_CI
      _ask "cd.yml  (deploy on push)"       F_CD
      _ask "release.yml (auto release tag)" F_RELEASE
      echo ""
      ;;
  esac

  # ════════════════════════════════════════════════════════════════
  # STEP 4: Summary + Confirm
  # ════════════════════════════════════════════════════════════════
  clear
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║              📋  Generation Summary                          ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  Project     : ${GREEN}${PROJECT_NAME}${RESET}"
  echo -e "  Type        : ${GREEN}${PROJECT_TYPE}${RESET}"
  echo -e "  Language    : ${GREEN}${TECH_LANG}${RESET}"
  [[ -n "$TECH_FRAMEWORK" ]] && \
  echo -e "  Framework   : ${GREEN}${TECH_FRAMEWORK}${RESET}"
  echo -e "  Database    : ${GREEN}${DB_LABEL}${RESET}"
  echo -e "  Author      : ${GREEN}${AUTHOR}${RESET}"
  echo ""
  echo -e "  ${BOLD}Files to generate:${RESET}"

  echo -e "  ${DIM}Root Docs:${RESET}"
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

  echo -e "  ${DIM}.github:${RESET}"
  _yes "$F_BUG_ISSUE"       && echo -e "    ${GREEN}✓${RESET} ISSUE_TEMPLATE/bug_report.yml"
  _yes "$F_FEATURE_ISSUE"   && echo -e "    ${GREEN}✓${RESET} ISSUE_TEMPLATE/feature_request.yml"
  _yes "$F_QUESTION_ISSUE"  && echo -e "    ${GREEN}✓${RESET} ISSUE_TEMPLATE/question.yml"
  _yes "$F_PR_TEMPLATE"     && echo -e "    ${GREEN}✓${RESET} PULL_REQUEST_TEMPLATE.md"
  _yes "$F_CODEOWNERS"      && echo -e "    ${GREEN}✓${RESET} CODEOWNERS"
  _yes "$F_DEPENDABOT"      && echo -e "    ${GREEN}✓${RESET} dependabot.yml"

  echo -e "  ${DIM}Workflows:${RESET}"
  _yes "$F_CI"      && echo -e "    ${GREEN}✓${RESET} workflows/ci.yml  ${DIM}(${TECH_LANG})${RESET}"
  _yes "$F_CD"      && echo -e "    ${GREEN}✓${RESET} workflows/cd.yml"
  _yes "$F_RELEASE" && echo -e "    ${GREEN}✓${RESET} workflows/release.yml"

  echo ""
  local CONFIRM
  read -rp "  Generate files? [y/n]: " CONFIRM
  CONFIRM="${CONFIRM:-y}"
  CONFIRM="${CONFIRM,,}"
  [[ "$CONFIRM" != "y" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
  echo ""

  # ════════════════════════════════════════════════════════════════
  # GENERATE FILES
  # ════════════════════════════════════════════════════════════════
  local B="."
  echo -e "${BOLD}${CYAN}  🔨 Generating files...${RESET}"
  echo ""

  if _yes "$F_CI" || _yes "$F_CD" || _yes "$F_RELEASE"; then
    mkdir -p "${B}/.github/workflows"
  fi
  if _yes "$F_BUG_ISSUE" || _yes "$F_FEATURE_ISSUE" || _yes "$F_QUESTION_ISSUE"; then
    mkdir -p "${B}/.github/ISSUE_TEMPLATE"
  fi
  if _yes "$F_PR_TEMPLATE" || _yes "$F_CODEOWNERS" || _yes "$F_DEPENDABOT"; then
    mkdir -p "${B}/.github"
  fi

  # ════════════════════════════════════════════════════════════════
  # README.md
  # ════════════════════════════════════════════════════════════════
  if _yes "$F_README"; then
    _write "${B}/README.md" << EOF
# ${PROJECT_NAME}

> ${PROJECT_DESC}

[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE.md)

---

## 📖 Overview

**${PROJECT_NAME}** is a **${PROJECT_TYPE}** built with **${MAIN_TECH}**$( [[ "$DB_LABEL" != "None" ]] && echo " and **${DB_LABEL}**").

---

## 🚀 Quick Start

### Prerequisites

$( case "$PROJ_TYPE_CHOICE" in
  1|2|3|5|6)
    [[ "$TECH_LANG" == *"JavaScript"* || "$TECH_LANG" == *"TypeScript"* ]] && echo "- [Node.js](https://nodejs.org/) v18+"
    [[ "$TECH_LANG" == "Python" ]] && echo "- [Python](https://www.python.org/) 3.10+"
    [[ "$TECH_LANG" == "Go" ]] && echo "- [Go](https://go.dev/) 1.22+"
    [[ "$TECH_LANG" == "Rust" ]] && echo "- [Rust](https://www.rust-lang.org/) (stable)"
    [[ "$TECH_LANG" == "Bash / Shell" ]] && echo "- Bash 5+"
    ;;
  4)
    [[ "$TECH_FRAMEWORK" == "Flutter" ]] && echo "- [Flutter SDK](https://flutter.dev/) (stable channel)"
    [[ "$TECH_FRAMEWORK" == "React Native" || "$TECH_FRAMEWORK" == "Expo" ]] && echo "- [Node.js](https://nodejs.org/) v18+"
    ;;
esac
[[ "$DB_LABEL" != "None" && "$DB_LABEL" != "Not specified" ]] && echo "- ${DB_LABEL} running locally (or connection string to hosted instance)")

### Installation

\`\`\`bash
git clone https://github.com/${AUTHOR}/${PROJECT_NAME}.git
cd ${PROJECT_NAME}
$( case "$TECH_LANG" in
  *"JavaScript"*|*"TypeScript"*) echo "npm install" ;;
  "Python") echo "pip install -r requirements.txt" ;;
  "Go") echo "go mod download" ;;
  "Rust") echo "cargo build" ;;
  "Dart") echo "flutter pub get" ;;
  *) echo "# Install dependencies" ;;
esac )
\`\`\`

### Running the Project

\`\`\`bash
$( case "$TECH_LANG" in
  *"JavaScript"*|*"TypeScript"*) echo "npm run dev" ;;
  "Python") echo "python -m ${PROJECT_NAME}" ;;
  "Go") echo "go run ." ;;
  "Rust") echo "cargo run" ;;
  "Dart") echo "flutter run" ;;
  *) echo "# Start command here" ;;
esac )
\`\`\`

---

## 🏗️ Project Structure

\`\`\`
src/                 # Source code
tests/               # Test files
docs/                # Additional documentation
\`\`\`

---

## 🛠️ Development Commands

| Command | Description |
|---|---|
$( case "$TECH_LANG" in
  *"JavaScript"*|*"TypeScript"*)
    echo "| \`npm run dev\` | Start development server |"
    echo "| \`npm run build\` | Build for production |"
    echo "| \`npm test\` | Run test suite |"
    echo "| \`npm run lint\` | Run linting |"
    ;;
  "Python")
    echo "| \`python -m ${PROJECT_NAME}\` | Run the project |"
    echo "| \`pytest\` | Run tests |"
    echo "| \`ruff check .\` | Run linting |"
    ;;
  "Go")
    echo "| \`go run .\` | Run the project |"
    echo "| \`go test ./...\` | Run tests |"
    echo "| \`go vet ./...\` | Run linting |"
    ;;
  "Rust")
    echo "| \`cargo run\` | Run the project |"
    echo "| \`cargo test\` | Run tests |"
    echo "| \`cargo clippy\` | Run linting |"
    ;;
  "Dart")
    echo "| \`flutter run\` | Run on device/emulator |"
    echo "| \`flutter test\` | Run tests |"
    echo "| \`flutter analyze\` | Run linting |"
    ;;
  *)
    echo "| \`start\` | Start the project |"
    echo "| \`test\` | Run tests |"
    ;;
esac )

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 🔒 Security

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

## 📄 License

MIT — see [LICENSE.md](LICENSE.md)
EOF
    echo -e "  ${GREEN}✓${RESET} README.md"
  fi

  # ════════════════════════════════════════════════════════════════
  # ARCHITECTURE.md
  # ════════════════════════════════════════════════════════════════
  if _yes "$F_ARCHITECTURE"; then
    _write "${B}/ARCHITECTURE.md" << EOF
# ${PROJECT_NAME} — Architecture

This document describes the high-level architecture and design decisions for **${PROJECT_NAME}**.

---

## 🎯 Overview

**${PROJECT_NAME}** is a **${PROJECT_TYPE}** built with **${MAIN_TECH}**.
$( [[ "$DB_LABEL" != "None" ]] && echo "Data persistence is handled via **${DB_LABEL}**." )

## 🧩 High-Level Design

\`\`\`
[ Component A ]  <--->  [ Component B ]
       |                       |
       v                       v
[ Data Source ]         [ External API ]
\`\`\`

## 📁 Core Directories

- **\`src/\`**: Main source code directory.
- **\`tests/\`**: Unit and integration tests.
- **\`docs/\`**: Architecture Decision Records (ADRs) and detailed guides.

## 🛠️ Technology Stack

| Category | Choice |
|---|---|
| Project Type | ${PROJECT_TYPE} |
| Language | ${TECH_LANG} |
$( [[ -n "$TECH_FRAMEWORK" ]] && echo "| Framework | ${TECH_FRAMEWORK} |" )
| Database/Storage | ${DB_LABEL} |
| CI/CD | GitHub Actions |

## 🔄 Data Flow

Document how data flows through your system.

## ⚡ Performance & Scaling

- Detail caching strategies.
- Detail deployment scaling approaches.

## 🚧 Future Improvements

- Add upcoming architectural changes here.
EOF
    echo -e "  ${GREEN}✓${RESET} ARCHITECTURE.md"
  fi

  # ════════════════════════════════════════════════════════════════
  # CONTRIBUTING.md
  # ════════════════════════════════════════════════════════════════
  if _yes "$F_CONTRIBUTING"; then
    _write "${B}/CONTRIBUTING.md" << EOF
# Contributing to ${PROJECT_NAME}

Thank you for helping improve **${PROJECT_NAME}**.

## Ways to Contribute

- Report bugs with clear reproduction steps and relevant logs
- Propose focused feature requests
- Improve docs and developer setup
- Submit code changes with tests

## Before You Start

- Check existing issues and pull requests before opening a new one
- For larger changes, open an issue first to align on scope

## Development Setup

\`\`\`bash
git clone https://github.com/${AUTHOR}/${PROJECT_NAME}.git
cd ${PROJECT_NAME}
$( case "$TECH_LANG" in
  *"JavaScript"*|*"TypeScript"*) echo "npm install" ;;
  "Python") echo "pip install -r requirements.txt" ;;
  "Go") echo "go mod download" ;;
  "Rust") echo "cargo build" ;;
  "Dart") echo "flutter pub get" ;;
  *) echo "# Install dependencies" ;;
esac )
\`\`\`

### Running Tests

\`\`\`bash
$( echo "${CI_TEST_CMD}" )
\`\`\`

### Linting

\`\`\`bash
$( echo "${CI_LINT_CMD}" )
\`\`\`

## Pull Request Guidelines

- Keep pull requests focused on a single concern
- Add or update tests for any changed behaviour
- Update \`CHANGELOG.md\` under \`[Unreleased]\` for user-visible changes
- Run linting and tests locally before pushing

## Commit Message Format

This project follows [Conventional Commits](https://www.conventionalcommits.org):

\`\`\`
feat: add new feature
fix: handle edge case gracefully
docs: update setup instructions
chore: upgrade dependencies
refactor: extract logic into helper
test: add unit tests for module
\`\`\`

## Contribution Licensing

By submitting a contribution, you agree that your work will be licensed under
the repository's MIT License.
EOF
    echo -e "  ${GREEN}✓${RESET} CONTRIBUTING.md"
  fi

  # ════════════════════════════════════════════════════════════════
  # CHANGELOG.md
  # ════════════════════════════════════════════════════════════════
  if _yes "$F_CHANGELOG"; then
    _write "${B}/CHANGELOG.md" << EOF
# Changelog

All notable changes to **${PROJECT_NAME}** will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

## [1.0.0] - $(date +%Y-%m-%d)
### Added
- Initial project scaffold
- ${MAIN_TECH} setup
- CI/CD pipeline basics
- Standard community documentation
EOF
    echo -e "  ${GREEN}✓${RESET} CHANGELOG.md"
  fi

  # ════════════════════════════════════════════════════════════════
  # LICENSE.md
  # ════════════════════════════════════════════════════════════════
  if _yes "$F_LICENSE"; then
    _write "${B}/LICENSE.md" << EOF
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

  # ════════════════════════════════════════════════════════════════
  # SECURITY.md
  # ════════════════════════════════════════════════════════════════
  if _yes "$F_SECURITY"; then
    _write "${B}/SECURITY.md" << EOF
# Security Policy

## Supported Versions

Security fixes are prioritised for:

- The latest code on \`main\`
- The most recent public release, if one exists

## Reporting a Vulnerability

Please report security vulnerabilities **privately** by email to **${CONTACT_EMAIL}**.

**Do not open a public GitHub issue for security vulnerabilities.**

When possible, include:

- A clear description of the vulnerability
- Steps to reproduce or a proof-of-concept (PoC)
- The affected version, branch, or commit hash
- Potential impact (e.g. data exposure, privilege escalation, DoS)

## Response Expectations

We will acknowledge reports within **72 hours** and work toward a fix as quickly
as possible. We will credit you in the changelog if you wish.
EOF
    echo -e "  ${GREEN}✓${RESET} SECURITY.md"
  fi

  # ════════════════════════════════════════════════════════════════
  # CODE_OF_CONDUCT.md
  # ════════════════════════════════════════════════════════════════
  if _yes "$F_CODE_OF_CONDUCT"; then
    _write "${B}/CODE_OF_CONDUCT.md" << EOF
# Code of Conduct

## Our Commitment

**${PROJECT_NAME}** is committed to a welcoming, respectful, and constructive
community for everyone, regardless of background, identity, or experience level.

## Expected Behavior

- Be respectful and professional in all interactions
- Assume good intent; discuss ideas without attacking people
- Offer constructive feedback
- Welcome questions from contributors of all experience levels

## Unacceptable Behavior

- Harassment, discrimination, or hateful conduct of any kind
- Personal attacks, insults, threats, or intimidation
- Deliberate disruption or bad-faith engagement
- Sharing private information without explicit permission

## Reporting

Report unacceptable behavior privately to **${CONTACT_EMAIL}**.

This Code of Conduct is adapted from the
[Contributor Covenant](https://www.contributor-covenant.org), version 2.1.
EOF
    echo -e "  ${GREEN}✓${RESET} CODE_OF_CONDUCT.md"
  fi

  # ════════════════════════════════════════════════════════════════
  # ABOUT.md
  # ════════════════════════════════════════════════════════════════
  if _yes "$F_ABOUT"; then
    _write "${B}/ABOUT.md" << EOF
# About ${PROJECT_NAME}

**Last Updated:** $(date +"%B %d, %Y")

**${PROJECT_NAME}** is an open-source **${PROJECT_TYPE}** built with **${MAIN_TECH}**.

## Stack at a Glance

| Category       | Choice                     |
|----------------|----------------------------|
| Project Type   | ${PROJECT_TYPE}            |
| Language       | ${TECH_LANG}               |
$( [[ -n "$TECH_FRAMEWORK" ]] && echo "| Framework      | ${TECH_FRAMEWORK}          |" )
| Database       | ${DB_LABEL}                |

## Contact

Questions, feedback, and collaboration inquiries: **${CONTACT_EMAIL}**
EOF
    echo -e "  ${GREEN}✓${RESET} ABOUT.md"
  fi

  # ════════════════════════════════════════════════════════════════
  # NOTICE.md
  # ════════════════════════════════════════════════════════════════
  if _yes "$F_NOTICE"; then
    _write "${B}/NOTICE.md" << EOF
${PROJECT_NAME}
Copyright (c) $(date +%Y) ${AUTHOR}

This repository's source code and documentation are licensed under the MIT
License unless otherwise noted.

The ${PROJECT_NAME} name, logo, and branding are reserved and may not be used
to imply endorsement or official project status for modified forks or
redistributions.

See LICENSE.md and TRADEMARKS.md for details.
EOF
    echo -e "  ${GREEN}✓${RESET} NOTICE.md"
  fi

  # ════════════════════════════════════════════════════════════════
  # TRADEMARKS.md
  # ════════════════════════════════════════════════════════════════
  if _yes "$F_TRADEMARKS"; then
    _write "${B}/TRADEMARKS.md" << EOF
# Trademarks and Branding

**${PROJECT_NAME}** is open source, but open source code does not automatically
grant branding rights.

## What the MIT License Covers

The [MIT License](LICENSE.md) applies to the source code and repository
documentation unless a specific file states otherwise.

## What Is Reserved

- The \`${PROJECT_NAME}\` project name when used to imply official status
- The ${PROJECT_NAME} logo and branded visual identity

## What You May Do

- Fork the repository
- Modify the code under the MIT License
- Credit ${PROJECT_NAME} as the upstream project in your fork

## What You May Not Do

- Ship a modified fork as if it were the official ${PROJECT_NAME}
- Remove required copyright or license notices from source files

Contact **${CONTACT_EMAIL}** for special branding requests.
EOF
    echo -e "  ${GREEN}✓${RESET} TRADEMARKS.md"
  fi

  # ════════════════════════════════════════════════════════════════
  # .github FILES
  # ════════════════════════════════════════════════════════════════

  if _yes "$F_BUG_ISSUE"; then
    _write "${B}/.github/ISSUE_TEMPLATE/bug_report.yml" << 'EOF'
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
    id: actual
    attributes:
      label: Actual behavior
    validations:
      required: true

  - type: textarea
    id: logs
    attributes:
      label: Relevant logs / stack trace
      render: shell

  - type: input
    id: version
    attributes:
      label: Version / commit hash
      placeholder: "e.g. v1.2.3 or abc1234"

  - type: input
    id: os
    attributes:
      label: OS / environment
      placeholder: "e.g. Ubuntu 22.04, macOS 14, Windows 11"

  - type: dropdown
    id: severity
    attributes:
      label: Severity
      options:
        - Critical (crash / data loss)
        - High (major feature broken)
        - Medium (feature partially broken)
        - Low (minor / cosmetic)
    validations:
      required: true
EOF
    echo -e "  ${GREEN}✓${RESET} .github/ISSUE_TEMPLATE/bug_report.yml"
  fi

  if _yes "$F_FEATURE_ISSUE"; then
    _write "${B}/.github/ISSUE_TEMPLATE/feature_request.yml" << 'EOF'
name: 🚀 Feature Request
description: Suggest a new feature or improvement
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
    id: alternatives
    attributes:
      label: Alternatives considered

  - type: textarea
    id: context
    attributes:
      label: Additional context / references
EOF
    echo -e "  ${GREEN}✓${RESET} .github/ISSUE_TEMPLATE/feature_request.yml"
  fi

  if _yes "$F_QUESTION_ISSUE"; then
    _write "${B}/.github/ISSUE_TEMPLATE/question.yml" << 'EOF'
name: ❓ Question
description: Ask a question about the project
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
    _write "${B}/.github/ISSUE_TEMPLATE/config.yml" << 'EOF'
blank_issues_enabled: false
EOF
    echo -e "  ${GREEN}✓${RESET} .github/ISSUE_TEMPLATE/question.yml"
  fi

  if _yes "$F_PR_TEMPLATE"; then
    _write "${B}/.github/PULL_REQUEST_TEMPLATE.md" << 'EOF'
## 📋 Description

<!-- What does this PR do? Closes #? -->

## 🔄 Type of Change

- [ ] 🐛 Bug fix
- [ ] 🚀 New feature
- [ ] 💥 Breaking change
- [ ] ♻️  Refactor
- [ ] ⚡ Performance improvement
- [ ] 🔒 Security fix
- [ ] 📝 Documentation only
- [ ] 🧪 Tests only

## 🧪 Testing

- [ ] Tests added / updated
- [ ] All tests pass locally
- [ ] Manual testing completed

## ✅ Checklist

- [ ] Linting passes
- [ ] No debug statements left in code
- [ ] CHANGELOG updated under `[Unreleased]`
- [ ] Relevant documentation updated

## 🔗 Related Issues / PRs
EOF
    echo -e "  ${GREEN}✓${RESET} .github/PULL_REQUEST_TEMPLATE.md"
  fi

  if _yes "$F_CODEOWNERS"; then
    _write "${B}/.github/CODEOWNERS" << EOF
# Global — review required for all changes
* @${AUTHOR}
EOF
    echo -e "  ${GREEN}✓${RESET} .github/CODEOWNERS"
  fi

  if _yes "$F_DEPENDABOT"; then
    _write "${B}/.github/dependabot.yml" << EOF
version: 2
updates:
$( case "$TECH_LANG" in
  *"JavaScript"*|*"TypeScript"*)
    echo "  - package-ecosystem: \"npm\""
    echo "    directory: \"/\""
    echo "    schedule:"
    echo "      interval: \"weekly\""
    echo "      day: \"monday\""
    echo "    open-pull-requests-limit: 5"
    echo "    labels:"
    echo "      - \"dependencies\""
    echo "      - \"automated\""
    ;;
  "Python")
    echo "  - package-ecosystem: \"pip\""
    echo "    directory: \"/\""
    echo "    schedule:"
    echo "      interval: \"weekly\""
    ;;
  "Go")
    echo "  - package-ecosystem: \"gomod\""
    echo "    directory: \"/\""
    echo "    schedule:"
    echo "      interval: \"weekly\""
    ;;
  "Rust")
    echo "  - package-ecosystem: \"cargo\""
    echo "    directory: \"/\""
    echo "    schedule:"
    echo "      interval: \"weekly\""
    ;;
  "Dart")
    echo "  - package-ecosystem: \"pub\""
    echo "    directory: \"/\""
    echo "    schedule:"
    echo "      interval: \"weekly\""
    ;;
  *)
    echo "  # Configure your package manager here"
    echo "  # - package-ecosystem: \"npm\""
    echo "  #   directory: \"/\""
    echo "  #   schedule:"
    echo "  #     interval: \"weekly\""
    ;;
esac )
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "monthly"
EOF
    echo -e "  ${GREEN}✓${RESET} .github/dependabot.yml"
  fi

  # ════════════════════════════════════════════════════════════════
  # GitHub Actions Workflows (tech-stack aware)
  # ════════════════════════════════════════════════════════════════

  if _yes "$F_CI"; then
    _write "${B}/.github/workflows/ci.yml" << EOF
name: CI

on:
  push:
    branches: [main, master, develop]
  pull_request:
    branches: [main, master, develop]

jobs:
  lint-and-test:
    name: Lint & Test (${TECH_LANG})
    runs-on: $( [[ "$TECH_FRAMEWORK" == "iOS"* ]] && echo "macos-latest" || echo "ubuntu-latest" )

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup ${TECH_LANG}
        $( printf '%b' "${CI_SETUP_CMD}" | head -1 )
        $( printf '%b' "${CI_SETUP_CMD}" | tail -n +2 )

      - name: Install dependencies
        run: |
$( case "$TECH_LANG" in
  *"JavaScript"*|*"TypeScript"*) echo "          npm ci" ;;
  "Python") echo "          pip install -r requirements.txt" ;;
  "Go") echo "          go mod download" ;;
  "Rust") echo "          # cargo fetch is implicit" ;;
  "Dart") echo "          flutter pub get" ;;
  "Bash / Shell") echo "          # no dependencies to install" ;;
  *) echo "          # add install command here" ;;
esac )

      - name: Lint
        run: ${CI_LINT_CMD}

      - name: Test
        run: ${CI_TEST_CMD}
EOF
    echo -e "  ${GREEN}✓${RESET} .github/workflows/ci.yml"
  fi

  if _yes "$F_CD"; then
    _write "${B}/.github/workflows/cd.yml" << 'EOF'
name: CD — Deploy

on:
  push:
    branches: [main, master]

jobs:
  deploy:
    name: Deploy to Production
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

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
            git pull origin main
            # Add your restart commands here
            echo "✓ Deployment complete"
EOF
    echo -e "  ${GREEN}✓${RESET} .github/workflows/cd.yml"
  fi

  if _yes "$F_RELEASE"; then
    _write "${B}/.github/workflows/release.yml" << EOF
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
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get version from tag
        id: version
        run: echo "VERSION=\${GITHUB_REF#refs/tags/}" >> \$GITHUB_OUTPUT

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: \${{ steps.version.outputs.VERSION }}
          name: "Release \${{ steps.version.outputs.VERSION }}"
          body: |
            ## What's Changed in \${{ steps.version.outputs.VERSION }}

            See [CHANGELOG.md](CHANGELOG.md) for full details.

            ---
            **Full Changelog**: https://github.com/\${{ github.repository }}/commits/\${{ steps.version.outputs.VERSION }}
          draft: false
          prerelease: \${{ contains(steps.version.outputs.VERSION, '-') }}
          generate_release_notes: true
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
EOF
    echo -e "  ${GREEN}✓${RESET} .github/workflows/release.yml"
  fi

  # ════════════════════════════════════════════════════════════════
  # DONE
  # ════════════════════════════════════════════════════════════════
  echo ""
  local FILE_COUNT
  FILE_COUNT=$(find "${B}/.github" "${B}/README.md" "${B}/ARCHITECTURE.md" "${B}/CONTRIBUTING.md" \
    "${B}/CHANGELOG.md" "${B}/LICENSE.md" "${B}/SECURITY.md" "${B}/CODE_OF_CONDUCT.md" \
    "${B}/ABOUT.md" "${B}/NOTICE.md" "${B}/TRADEMARKS.md" \
    -type f 2>/dev/null | wc -l | tr -d ' ')

  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${GREEN}║   ✅  '${PROJECT_NAME}' docs generated successfully!         ${RESET}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${DIM}📄 Files generated : ${WHITE}${FILE_COUNT}${RESET}"
  echo -e "  ${DIM}📦 Stack           : ${WHITE}${MAIN_TECH}${RESET}"
  echo ""
  echo -e "${BOLD}${YELLOW}  ⚡ Next steps:${RESET}"
  echo -e "  ${DIM}1.${RESET} Review generated files and fill in project-specific details"
  echo -e "  ${DIM}2.${RESET} Replace ${CYAN}@${AUTHOR}${RESET} in CODEOWNERS with your real GitHub username"
  echo -e "  ${DIM}3.${RESET} Update ${CYAN}SERVER_HOST${RESET}, ${CYAN}SERVER_USER${RESET}, ${CYAN}SERVER_SSH_KEY${RESET} in GitHub Secrets for CD"
  echo -e "  ${DIM}4.${RESET} Tag a release: ${GREEN}git tag v1.0.0 && git push origin v1.0.0${RESET}"
  echo ""
}
