#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# mkflutter — Interactive Flutter Clean Architecture Scaffold Tool
#
# INSTALL:
#   echo 'source ~/.mkflutter.sh' >> ~/.bashrc
#   source ~/.bashrc
#
# USAGE:
#   mkflutter
# ─────────────────────────────────────────────────────────────────

mkflutter() {

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

  _mks() {
    mkdir -p "${B}/${1}"
  }

  _dart() {
    local FILE="${B}/${1}"
    mkdir -p "$(dirname "$FILE")"
    touch "$FILE"
  }

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

  # ════════════════════════════════════════════════════════════════
  # BANNER
  # ════════════════════════════════════════════════════════════════
  clear
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║       🐦  mkflutter — Flutter Clean Architecture Scaffold    ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  # ════════════════════════════════════════════════════════════════
  # STEP 0: Project Name
  # ════════════════════════════════════════════════════════════════
  # FIX: Correctly labelled as Step 0 (was "Step 1" in both name and SM sections)
  echo -e "${BOLD}${YELLOW}── Step 0: Project Name ──────────────────────────────────────${RESET}"

  CURRENT_DIR_NAME=$(basename "$(pwd)")

  # FIX: Re-run guard — warn and abort if pubspec.yaml already exists
  if [[ -f "./pubspec.yaml" ]]; then
    echo -e "  ${RED}⚠  pubspec.yaml already exists in this directory.${RESET}"
    echo -e "  ${DIM}  Running mkflutter here will overwrite generated files.${RESET}"
    local _OVERWRITE
    read -rp "  Continue anyway? [y/N]: " _OVERWRITE
    _OVERWRITE="${_OVERWRITE:-n}"
    _OVERWRITE="${_OVERWRITE,,}"
    [[ "$_OVERWRITE" != "y" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
    echo ""
  fi

  PROJECT_NAME=$(echo "$CURRENT_DIR_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9_' '_' | sed 's/^_//;s/_$//')

  if [[ ! "$PROJECT_NAME" =~ ^[a-z] ]]; then
    PROJECT_NAME="app_${PROJECT_NAME}"
  fi

  if [[ -z "$PROJECT_NAME" ]]; then
    PROJECT_NAME="flutter_app"
  fi

  # Application ID configuration
  _APP_SEGMENT=$(echo "$PROJECT_NAME" | tr '_' '' | tr -cd 'a-z0-9')
  [[ -z "$_APP_SEGMENT" ]] && _APP_SEGMENT="app"

  local _DEFAULT_APP_ID="com.example.${_APP_SEGMENT}"
  local _INPUT_APP_ID
  read -rp "  Enter Application ID [${_DEFAULT_APP_ID}]: " _INPUT_APP_ID
  _INPUT_APP_ID="${_INPUT_APP_ID:-$_DEFAULT_APP_ID}"

  APP_ID=$(echo "$_INPUT_APP_ID" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9.')

  echo -e "  ${GREEN}✓ Project name : ${CYAN}${PROJECT_NAME}${RESET}"
  echo -e "  ${GREEN}✓ Application ID: ${CYAN}${APP_ID}${RESET}"
  echo ""

  # ════════════════════════════════════════════════════════════════
  # STEP 1: State Management
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 1: State Management ──────────────────────────────────${RESET}"
  echo -e "  ${GREEN}1)${RESET} BLoC (flutter_bloc)          ${DIM}— Enterprise standard${RESET}"
  echo -e "  ${GREEN}2)${RESET} Riverpod                     ${DIM}— Modern, compile-safe${RESET}"
  echo -e "  ${GREEN}3)${RESET} GetX                         ${DIM}— All-in-one, fast${RESET}"
  echo -e "  ${GREEN}4)${RESET} Provider                     ${DIM}— Simple, official${RESET}"
  echo ""
  _choose "Choose" 1 4 SM_CHOICE
  echo ""

  case "$SM_CHOICE" in
    1) SM_LABEL="BLoC";     SM_DIR="bloc";        SM_FILES=(bloc event state) ;;
    2) SM_LABEL="Riverpod"; SM_DIR="providers";   SM_FILES=(provider notifier state) ;;
    3) SM_LABEL="GetX";     SM_DIR="controllers"; SM_FILES=(controller binding) ;;
    4) SM_LABEL="Provider"; SM_DIR="providers";   SM_FILES=(provider) ;;
  esac

  # ════════════════════════════════════════════════════════════════
  # STEP 2: Backend / API
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 2: Backend / API ─────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}1)${RESET} REST API (Dio)               ${DIM}— Standard HTTP${RESET}"
  echo -e "  ${GREEN}2)${RESET} REST API (http package)      ${DIM}— Lightweight${RESET}"
  echo -e "  ${GREEN}3)${RESET} Firebase only                ${DIM}— No custom backend${RESET}"
  echo -e "  ${GREEN}4)${RESET} GraphQL (graphql_flutter)    ${DIM}— GraphQL API${RESET}"
  echo -e "  ${GREEN}5)${RESET} REST + Firebase              ${DIM}— Both${RESET}"
  echo ""
  _choose "Choose" 1 5 API_CHOICE
  echo ""

  case "$API_CHOICE" in
    1) API_LABEL="REST (Dio)" ;;
    2) API_LABEL="REST (http)" ;;
    3) API_LABEL="Firebase" ;;
    4) API_LABEL="GraphQL" ;;
    5) API_LABEL="REST + Firebase" ;;
  esac

  # ════════════════════════════════════════════════════════════════
  # STEP 3: Local Storage
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 3: Local Storage ─────────────────────────────────────${RESET}"
  echo -e "  ${GREEN}1)${RESET} Hive                         ${DIM}— Fast, NoSQL${RESET}"
  echo -e "  ${GREEN}2)${RESET} SharedPreferences            ${DIM}— Simple key-value${RESET}"
  echo -e "  ${GREEN}3)${RESET} SQLite (sqflite)             ${DIM}— Relational${RESET}"
  echo -e "  ${GREEN}4)${RESET} Isar                         ${DIM}— Fast, type-safe${RESET}"
  echo -e "  ${GREEN}5)${RESET} None                         ${DIM}— No local storage${RESET}"
  echo ""
  _choose "Choose" 1 5 STORAGE_CHOICE
  echo ""

  case "$STORAGE_CHOICE" in
    1) STORAGE_LABEL="Hive" ;;
    2) STORAGE_LABEL="SharedPreferences" ;;
    3) STORAGE_LABEL="SQLite" ;;
    4) STORAGE_LABEL="Isar" ;;
    5) STORAGE_LABEL="None" ;;
  esac

  # ════════════════════════════════════════════════════════════════
  # STEP 4: Features (select what you need)
  # ════════════════════════════════════════════════════════════════
  echo -e "${BOLD}${YELLOW}── Step 4: Features (select what you need) ───────────────────${RESET}"
  echo -e "${DIM}  Press ENTER to accept default (y). Enter n to skip.${RESET}"
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Auth ]${RESET}"
  _ask "JWT Auth (login / register / refresh)"         F_JWT
  _ask "OAuth — Google / Apple Sign-In"                F_OAUTH
  _ask "Biometric Auth (fingerprint / face ID)"        F_BIOMETRIC
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Firebase ]${RESET}"
  _ask "Firebase Authentication"                        F_FIREBASE_AUTH
  _ask "Firebase Firestore"                             F_FIRESTORE
  _ask "Firebase Storage"                               F_FIREBASE_STORAGE
  _ask "Firebase Crashlytics"                           F_CRASHLYTICS
  _ask "Firebase Analytics"                             F_ANALYTICS
  _ask "Firebase Remote Config"                         F_REMOTE_CONFIG
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Notifications ]${RESET}"
  _ask "Push Notifications (FCM)"                      F_PUSH
  _ask "Local Notifications"                           F_LOCAL_NOTIF
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ UI / UX ]${RESET}"
  _ask "Dark / Light theme support"                    F_THEME
  _ask "Multi-language support (intl / easy_localization)" F_L10N
  _ask "Splash screen"                                 F_SPLASH
  _ask "Onboarding screens"                            F_ONBOARDING
  _ask "Bottom navigation bar"                         F_BOTTOM_NAV
  _ask "Drawer / side menu"                            F_DRAWER
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Media ]${RESET}"
  _ask "Image picker (gallery + camera)"               F_IMAGE_PICKER
  _ask "File picker"                                   F_FILE_PICKER
  _ask "Video player"                                  F_VIDEO
  _ask "Camera (camera package)"                       F_CAMERA
  _ask "PDF viewer"                                    F_PDF
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Device / System ]${RESET}"
  _ask "Location (geolocator)"                         F_LOCATION
  _ask "Maps (google_maps_flutter)"                    F_MAPS
  _ask "Contacts (contacts_service)"                   F_CONTACTS
  _ask "QR / Barcode scanner"                          F_QR
  _ask "Bluetooth (flutter_blue_plus)"                 F_BLUETOOTH
  _ask "Deep links / App links"                        F_DEEPLINK
  _ask "Share (share_plus)"                            F_SHARE
  _ask "Connectivity check"                            F_CONNECTIVITY
  _ask "Permissions handler"                           F_PERMISSIONS
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Payments ]${RESET}"
  _ask "Payment gateway (Razorpay / Stripe)"           F_PAYMENT
  _ask "In-App Purchases"                              F_IAP
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Data ]${RESET}"
  _ask "Charts (fl_chart)"                             F_CHARTS
  _ask "Excel / CSV export"                            F_EXCEL
  _ask "PDF generation"                                F_PDF_GEN
  _ask "QR code generator"                             F_QR_GEN
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ DI / Routing ]${RESET}"
  _ask "Dependency Injection (get_it + injectable)"    F_DI
  _ask "GoRouter for navigation"                       F_GOROUTER
  _ask "Auto Route (code gen routing)"                 F_AUTOROUTE
  echo ""

  echo -e "  ${BOLD}${MAGENTA}[ Dev / Quality ]${RESET}"
  _ask "Flavors (dev / staging / prod)"                F_FLAVORS
  _ask "Unit tests (mockito + bloc_test)"              F_UNIT_TEST
  _ask "Widget tests"                                  F_WIDGET_TEST
  _ask "Integration tests"                             F_INTEGRATION_TEST
  _ask "Logging (logger package)"                      F_LOGGING
  _ask "Crash reporting (Sentry)"                      F_SENTRY
  _ask "CI/CD — GitHub Actions (build + test)"         F_CICD
  _ask "GitHub Issue Templates"                        F_ISSUES
  _ask "GitHub PR Template"                            F_PR
  _ask "GitHub CODEOWNERS"                             F_CODEOWNERS
  _ask "CHANGELOG.md"                                  F_CHANGELOG
  echo ""

  # ════════════════════════════════════════════════════════════════
  # STEP 5: Summary + Confirm
  # ════════════════════════════════════════════════════════════════
  clear
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║              📋  Project Summary                             ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  Project        : ${GREEN}${PROJECT_NAME}${RESET}"
  echo -e "  Application ID : ${GREEN}${APP_ID}${RESET}"
  echo -e "  State Mgmt     : ${GREEN}${SM_LABEL}${RESET}"
  echo -e "  API / Backend  : ${GREEN}${API_LABEL}${RESET}"
  echo -e "  Local Storage  : ${GREEN}${STORAGE_LABEL}${RESET}"
  echo ""
  echo -e "  ${BOLD}Features:${RESET}"

  echo -e "  ${DIM}Auth:${RESET}"
  _yes "$F_JWT"       && echo -e "    ${GREEN}✓${RESET} JWT Auth"
  _yes "$F_OAUTH"     && echo -e "    ${GREEN}✓${RESET} OAuth (Google / Apple)"
  _yes "$F_BIOMETRIC" && echo -e "    ${GREEN}✓${RESET} Biometric Auth"

  echo -e "  ${DIM}Firebase:${RESET}"
  _yes "$F_FIREBASE_AUTH"    && echo -e "    ${GREEN}✓${RESET} Firebase Authentication"
  _yes "$F_FIRESTORE"        && echo -e "    ${GREEN}✓${RESET} Firestore"
  _yes "$F_FIREBASE_STORAGE" && echo -e "    ${GREEN}✓${RESET} Firebase Storage"
  _yes "$F_CRASHLYTICS"      && echo -e "    ${GREEN}✓${RESET} Crashlytics"
  _yes "$F_ANALYTICS"        && echo -e "    ${GREEN}✓${RESET} Analytics"
  _yes "$F_REMOTE_CONFIG"    && echo -e "    ${GREEN}✓${RESET} Remote Config"

  echo -e "  ${DIM}Notifications:${RESET}"
  _yes "$F_PUSH"        && echo -e "    ${GREEN}✓${RESET} Push Notifications (FCM)"
  _yes "$F_LOCAL_NOTIF" && echo -e "    ${GREEN}✓${RESET} Local Notifications"

  echo -e "  ${DIM}UI/UX:${RESET}"
  _yes "$F_THEME"      && echo -e "    ${GREEN}✓${RESET} Dark/Light Theme"
  _yes "$F_L10N"       && echo -e "    ${GREEN}✓${RESET} Multi-language"
  _yes "$F_SPLASH"     && echo -e "    ${GREEN}✓${RESET} Splash Screen"
  _yes "$F_ONBOARDING" && echo -e "    ${GREEN}✓${RESET} Onboarding"
  _yes "$F_BOTTOM_NAV" && echo -e "    ${GREEN}✓${RESET} Bottom Navigation"
  _yes "$F_DRAWER"     && echo -e "    ${GREEN}✓${RESET} Drawer Menu"

  echo -e "  ${DIM}Media:${RESET}"
  _yes "$F_IMAGE_PICKER" && echo -e "    ${GREEN}✓${RESET} Image Picker"
  _yes "$F_FILE_PICKER"  && echo -e "    ${GREEN}✓${RESET} File Picker"
  _yes "$F_VIDEO"        && echo -e "    ${GREEN}✓${RESET} Video Player"
  _yes "$F_CAMERA"       && echo -e "    ${GREEN}✓${RESET} Camera"
  _yes "$F_PDF"          && echo -e "    ${GREEN}✓${RESET} PDF Viewer"

  echo -e "  ${DIM}Device/System:${RESET}"
  _yes "$F_LOCATION"     && echo -e "    ${GREEN}✓${RESET} Location"
  _yes "$F_MAPS"         && echo -e "    ${GREEN}✓${RESET} Google Maps"
  _yes "$F_CONTACTS"     && echo -e "    ${GREEN}✓${RESET} Contacts"
  _yes "$F_QR"           && echo -e "    ${GREEN}✓${RESET} QR Scanner"
  _yes "$F_BLUETOOTH"    && echo -e "    ${GREEN}✓${RESET} Bluetooth"
  _yes "$F_DEEPLINK"     && echo -e "    ${GREEN}✓${RESET} Deep Links"
  _yes "$F_SHARE"        && echo -e "    ${GREEN}✓${RESET} Share"
  _yes "$F_CONNECTIVITY" && echo -e "    ${GREEN}✓${RESET} Connectivity"
  _yes "$F_PERMISSIONS"  && echo -e "    ${GREEN}✓${RESET} Permissions Handler"

  echo -e "  ${DIM}Payments:${RESET}"
  _yes "$F_PAYMENT" && echo -e "    ${GREEN}✓${RESET} Payment Gateway"
  _yes "$F_IAP"     && echo -e "    ${GREEN}✓${RESET} In-App Purchases"

  echo -e "  ${DIM}Data:${RESET}"
  _yes "$F_CHARTS"  && echo -e "    ${GREEN}✓${RESET} Charts"
  _yes "$F_EXCEL"   && echo -e "    ${GREEN}✓${RESET} Excel/CSV Export"
  _yes "$F_PDF_GEN" && echo -e "    ${GREEN}✓${RESET} PDF Generation"
  _yes "$F_QR_GEN"  && echo -e "    ${GREEN}✓${RESET} QR Code Generator"

  echo -e "  ${DIM}DI/Routing:${RESET}"
  _yes "$F_DI"        && echo -e "    ${GREEN}✓${RESET} GetIt + Injectable"
  _yes "$F_GOROUTER"  && echo -e "    ${GREEN}✓${RESET} GoRouter"
  _yes "$F_AUTOROUTE" && echo -e "    ${GREEN}✓${RESET} Auto Route"

  echo -e "  ${DIM}Dev/Quality:${RESET}"
  _yes "$F_FLAVORS"          && echo -e "    ${GREEN}✓${RESET} Flavors (dev/staging/prod)"
  _yes "$F_UNIT_TEST"        && echo -e "    ${GREEN}✓${RESET} Unit Tests"
  _yes "$F_WIDGET_TEST"      && echo -e "    ${GREEN}✓${RESET} Widget Tests"
  _yes "$F_INTEGRATION_TEST" && echo -e "    ${GREEN}✓${RESET} Integration Tests"
  _yes "$F_LOGGING"          && echo -e "    ${GREEN}✓${RESET} Logging"
  _yes "$F_SENTRY"           && echo -e "    ${GREEN}✓${RESET} Sentry"
  _yes "$F_CICD"             && echo -e "    ${GREEN}✓${RESET} GitHub Actions CI/CD"
  _yes "$F_ISSUES"           && echo -e "    ${GREEN}✓${RESET} GitHub Issue Templates"
  _yes "$F_PR"               && echo -e "    ${GREEN}✓${RESET} PR Template"
  _yes "$F_CODEOWNERS"       && echo -e "    ${GREEN}✓${RESET} CODEOWNERS"
  _yes "$F_CHANGELOG"        && echo -e "    ${GREEN}✓${RESET} CHANGELOG.md"

  echo ""
  local CONFIRM
  read -rp "  Create project? [y/n]: " CONFIRM
  CONFIRM="${CONFIRM:-y}"
  CONFIRM="${CONFIRM,,}"
  [[ "$CONFIRM" != "y" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
  echo ""

  # ════════════════════════════════════════════════════════════════
  # PRE-COMPUTE FLAGS FOR HEREDOC
  # ════════════════════════════════════════════════════════════════

  # ── Helper: emit a YAML dependency line only when non-empty ──────
  # FIX: All _PKG_* variables are built as arrays then joined, so the
  #      pubspec.yaml has no stray blank lines from unset variables.
  #      We accumulate lines into _DEPS_MAIN and _DEPS_DEV arrays and
  #      write them with a single printf at file-generation time.
  _DEPS_MAIN=()
  _DEPS_DEV=()

  _dep()  { [[ -n "$1" ]] && _DEPS_MAIN+=("$1"); }
  _devdep() { [[ -n "$1" ]] && _DEPS_DEV+=("$1"); }

  # ── State Management ─────────────────────────────────────────────
  _dep ""
  _dep "  # ------- State Management --------"
  case "$SM_CHOICE" in
    1) _dep "  flutter_bloc: ^8.1.3 # State management library"
       _dep "  equatable: ^2.0.5 # Value equality for objects" ;;
    2) _dep "  flutter_riverpod: ^2.4.9 # Reactive caching and data-binding"
       _dep "  riverpod_annotation: ^2.3.3 # Annotations for Riverpod" ;;
    3) _dep "  get: ^4.6.6 # Route, state, and dependency management" ;;
    4) _dep "  provider: ^6.1.1 # Dependency injection and state management" ;;
  esac

  # ── Network ──────────────────────────────────────────────────────
  if [[ "$API_CHOICE" != "3" ]]; then
    _dep ""
    _dep "  # ------- Network --------"
  fi
  if [[ "$API_CHOICE" == "1" || "$API_CHOICE" == "5" ]]; then
    _dep "  dio: ^5.4.0 # Powerful HTTP client for API calls"
    _dep "  retrofit: ^4.0.3 # Dio client code generator for APIs"
  fi
  [[ "$API_CHOICE" == "2" ]] && _dep "  http: ^1.1.0 # Basic HTTP client"
  [[ "$API_CHOICE" == "4" ]] && _dep "  graphql_flutter: ^5.1.2 # GraphQL client"

  # ── Local Storage ────────────────────────────────────────────────
  if [[ "$STORAGE_CHOICE" != "5" ]]; then
    _dep ""
    _dep "  # ------- Local Storage --------"
  fi
  case "$STORAGE_CHOICE" in
    1) _dep "  hive: ^2.2.3 # Lightweight NoSQL local database"
       _dep "  hive_flutter: ^1.1.0 # Hive extension for Flutter" ;;
    2) _dep "  shared_preferences: ^2.2.2 # Local key-value storage" ;;
    3) _dep "  sqflite: ^2.3.0 # SQLite plugin for local database"
       _dep "  path: ^1.8.3 # Path manipulation for database" ;;
    4) _dep "  isar: ^3.1.0 # Super fast NoSQL database"
       _dep "  isar_flutter_libs: ^3.1.0 # Core binaries for Isar" ;;
  esac

  # ── Firebase ─────────────────────────────────────────────────────
  local _NEEDS_FB_CORE=false
  ( _yes "$F_FIREBASE_AUTH" || _yes "$F_FIRESTORE" || _yes "$F_FIREBASE_STORAGE" \
    || _yes "$F_CRASHLYTICS" || _yes "$F_ANALYTICS" || _yes "$F_REMOTE_CONFIG" \
    || _yes "$F_PUSH" ) && _NEEDS_FB_CORE=true

  $_NEEDS_FB_CORE && _dep ""
  $_NEEDS_FB_CORE && _dep "  # ------- Firebase --------"
  $_NEEDS_FB_CORE && _dep "  firebase_core: ^2.24.2 # Required for any Firebase service"
  _yes "$F_FIREBASE_AUTH"    && _dep "  firebase_auth: ^4.16.0 # User authentication (Login/Signup)"
  _yes "$F_FIRESTORE"        && _dep "  cloud_firestore: ^4.15.5 # Firebase NoSQL database"
  _yes "$F_FIREBASE_STORAGE" && _dep "  firebase_storage: ^11.6.5 # Firebase cloud file storage"
  _yes "$F_CRASHLYTICS"      && _dep "  firebase_crashlytics: ^3.4.15 # App crash tracking"
  _yes "$F_ANALYTICS"        && _dep "  firebase_analytics: ^10.8.5 # User tracking & events analytics"
  _yes "$F_REMOTE_CONFIG"    && _dep "  firebase_remote_config: ^4.3.15 # Update app without app store"
  _yes "$F_PUSH"             && _dep "  firebase_messaging: ^14.7.15 # Push notifications"

  # ── Auth ─────────────────────────────────────────────────────────
  if _yes "$F_OAUTH" || _yes "$F_BIOMETRIC"; then
    _dep ""
    _dep "  # ------- Auth --------"
  fi
  _yes "$F_OAUTH"     && _dep "  google_sign_in: ^6.2.1 # Google login integration"
  _yes "$F_BIOMETRIC" && _dep "  local_auth: ^2.1.7 # Fingerprint & Face ID login"

  # ── Notifications ────────────────────────────────────────────────
  if _yes "$F_LOCAL_NOTIF"; then
    _dep ""
    _dep "  # ------- Notifications --------"
  fi
  _yes "$F_LOCAL_NOTIF" && _dep "  flutter_local_notifications: ^16.3.0 # On-device notifications"

  # ── UI/UX ────────────────────────────────────────────────────────
  if _yes "$F_SPLASH" || _yes "$F_L10N"; then
    _dep ""
    _dep "  # ------- UI/UX --------"
  fi
  _yes "$F_SPLASH" && _dep "  flutter_native_splash: ^2.3.8 # App launch screen handler"
  _yes "$F_L10N"   && _dep "  easy_localization: ^3.0.3 # Multi-language support"

  # ── Routing ──────────────────────────────────────────────────────
  if _yes "$F_GOROUTER" || _yes "$F_AUTOROUTE"; then
    _dep ""
    _dep "  # ------- Routing --------"
  fi
  _yes "$F_GOROUTER"  && _dep "  go_router: ^13.1.0 # Declarative routing/navigation"
  _yes "$F_AUTOROUTE" && _dep "  auto_route: ^7.8.4 # Code generated routing"

  # ── DI ───────────────────────────────────────────────────────────
  if _yes "$F_DI"; then
    _dep ""
    _dep "  # ------- Dependency Injection --------"
    _dep "  get_it: ^7.6.7 # Dependency injection (Service Locator)"
    _dep "  injectable: ^2.3.2 # Code generator for get_it"
  fi

  # ── Media ────────────────────────────────────────────────────────
  if _yes "$F_IMAGE_PICKER" || _yes "$F_FILE_PICKER" || _yes "$F_VIDEO" || _yes "$F_CAMERA" || _yes "$F_PDF"; then
    _dep ""
    _dep "  # ------- Media --------"
  fi
  _yes "$F_IMAGE_PICKER" && _dep "  image_picker: ^1.0.7 # Pick images from gallery or camera"
  _yes "$F_FILE_PICKER"  && _dep "  file_picker: ^6.1.1 # Select documents & files"
  if _yes "$F_VIDEO"; then
    _dep "  video_player: ^2.8.2 # Low-level video playing"
    _dep "  chewie: ^1.7.4 # Advanced video player UI"
  fi
  _yes "$F_CAMERA" && _dep "  camera: ^0.10.5+9 # Device camera controls"
  _yes "$F_PDF"    && _dep "  flutter_pdfview: ^1.3.2 # Show PDF files inside app"

  # ── Maps / Location ──────────────────────────────────────────────
  if _yes "$F_LOCATION" || _yes "$F_MAPS"; then
    _dep ""
    _dep "  # ------- Maps & Location --------"
  fi
  if _yes "$F_LOCATION"; then
    _dep "  geolocator: ^11.0.0 # Fetch current GPS location"
    _dep "  geocoding: ^3.0.0 # Convert coordinates to addresses"
  fi
  _yes "$F_MAPS" && _dep "  google_maps_flutter: ^2.5.3 # Google Maps integration"

  # ── Device ───────────────────────────────────────────────────────
  if _yes "$F_CONTACTS" || _yes "$F_QR" || _yes "$F_BLUETOOTH" || _yes "$F_DEEPLINK" || _yes "$F_SHARE" || _yes "$F_CONNECTIVITY" || _yes "$F_PERMISSIONS"; then
    _dep ""
    _dep "  # ------- Device --------"
  fi
  _yes "$F_CONTACTS"     && _dep "  flutter_contacts: ^1.1.7+1 # Read/write phone contacts"
  _yes "$F_QR"           && _dep "  mobile_scanner: ^3.5.5 # Scan QR codes and barcodes"
  _yes "$F_BLUETOOTH"    && _dep "  flutter_blue_plus: ^1.29.5 # Bluetooth Low Energy (BLE)"
  _yes "$F_DEEPLINK"     && _dep "  app_links: ^5.0.0 # Deep linking (handle URLs opening app)"
  _yes "$F_SHARE"        && _dep "  share_plus: ^7.2.2 # Native share dialog"
  _yes "$F_CONNECTIVITY" && _dep "  connectivity_plus: ^5.0.2 # Check if connected to internet"
  _yes "$F_PERMISSIONS"  && _dep "  permission_handler: ^11.2.0 # Request camera, storage, etc permissions"

  # ── Payments ─────────────────────────────────────────────────────
  if _yes "$F_PAYMENT" || _yes "$F_IAP"; then
    _dep ""
    _dep "  # ------- Payments --------"
  fi
  _yes "$F_PAYMENT" && _dep "  razorpay_flutter: ^1.3.6 # Razorpay payment gateway"
  _yes "$F_IAP"     && _dep "  in_app_purchase: ^3.1.13 # Store billing (IAP)"

  # ── Data ─────────────────────────────────────────────────────────
  if _yes "$F_CHARTS" || _yes "$F_EXCEL" || _yes "$F_PDF_GEN" || _yes "$F_QR_GEN"; then
    _dep ""
    _dep "  # ------- Data & Utilities --------"
  fi
  _yes "$F_CHARTS"  && _dep "  fl_chart: ^0.66.2 # Drawing interactive charts"
  _yes "$F_EXCEL"   && _dep "  excel: ^4.0.2 # Read & Write Excel files"
  if _yes "$F_PDF_GEN"; then
    _dep "  pdf: ^3.10.7 # Create PDF files programmatically"
    _dep "  printing: ^5.12.0 # Print PDFs from device"
  fi
  _yes "$F_QR_GEN" && _dep "  qr_flutter: ^4.1.0 # Generate & show QR codes"

  # ── Logging / Crash ──────────────────────────────────────────────
  if _yes "$F_LOGGING" || _yes "$F_SENTRY"; then
    _dep ""
    _dep "  # ------- Logging & Crash Reporting --------"
  fi
  _yes "$F_LOGGING" && _dep "  logger: ^2.1.0 # Beautiful console logs"
  _yes "$F_SENTRY"  && _dep "  sentry_flutter: ^7.14.0 # Sentry crash reporting"

  # ── Always-on utils ──────────────────────────────────────────────
  _dep ""
  _dep "  # ------- Core Utilities --------"
  _dep "  intl: ^0.19.0 # Date and number formatting"
  _dep "  dartz: ^0.10.1 # Functional programming (Either, Option)"
  _dep "  flutter_secure_storage: ^9.0.0 # Encrypted key-value storage (for tokens)"
  _dep "  cached_network_image: ^3.3.1 # Cache images from network"
  _dep "  flutter_screenutil: ^5.9.0 # Adapt UI to different screen sizes"
  _dep "  lottie: ^3.0.0 # Beautiful After Effects animations"

  # ── Dev dependencies ─────────────────────────────────────────────
  # FIX: build_runner is added only when at least one code-gen package is selected
  local _NEEDS_BUILD_RUNNER=false
  _yes "$F_DI"       && _NEEDS_BUILD_RUNNER=true
  _yes "$F_AUTOROUTE" && _NEEDS_BUILD_RUNNER=true
  [[ "$STORAGE_CHOICE" == "1" || "$STORAGE_CHOICE" == "4" ]] && _NEEDS_BUILD_RUNNER=true

  $_NEEDS_BUILD_RUNNER && _devdep "  build_runner: ^2.4.7 # Runs code generators"
  _yes "$F_DI"       && _devdep "  injectable_generator: ^2.4.1 # Code gen for injectable"
  _yes "$F_AUTOROUTE" && _devdep "  auto_route_generator: ^7.3.2 # Code gen for auto_route"
  [[ "$STORAGE_CHOICE" == "1" ]] && _devdep "  hive_generator: ^2.0.1 # Code gen for Hive"
  [[ "$STORAGE_CHOICE" == "4" ]] && _devdep "  isar_generator: ^3.1.0 # Code gen for Isar"
  if _yes "$F_UNIT_TEST"; then
    _devdep "  mockito: ^5.4.4 # Mock dependencies for testing"
    _devdep "  bloc_test: ^9.1.5 # Testing utilities for BLoC"
  fi

  # ── .env conditional lines ───────────────────────────────────────
  _ENV_MAPS="";    _yes "$F_MAPS"    && _ENV_MAPS="GOOGLE_MAPS_API_KEY="
  _ENV_PAYMENT=""; _yes "$F_PAYMENT" && _ENV_PAYMENT=$'RAZORPAY_KEY_ID=\nSTRIPE_PUBLISHABLE_KEY='
  _ENV_SENTRY="";  _yes "$F_SENTRY"  && _ENV_SENTRY="SENTRY_DSN="

  # ── assets/translations line ─────────────────────────────────────
  _ASSET_TRANSLATIONS=""
  _yes "$F_L10N" && _ASSET_TRANSLATIONS="    - assets/translations/"

  # ── README feature/route/config labels ───────────────────────────
  _README_FEATURES="auth, profile, settings"
  _yes "$F_PUSH"    && _README_FEATURES="${_README_FEATURES}, notifications"
  _yes "$F_PAYMENT" && _README_FEATURES="${_README_FEATURES}, payment"
  _yes "$F_MAPS"    && _README_FEATURES="${_README_FEATURES}, maps"

  _README_ROUTES="app_routes, app_pages"
  ( _yes "$F_GOROUTER" || _yes "$F_AUTOROUTE" ) && _README_ROUTES="${_README_ROUTES}, guards"

  _README_CONFIG="app_config, environment"
  _yes "$F_FLAVORS" && _README_CONFIG="${_README_CONFIG}, flavors (dev/staging/prod)"

  _README_MAIN=""
  if _yes "$F_FLAVORS"; then
    _README_MAIN="    main_dev.dart
    main_staging.dart
    main_prod.dart"
  fi

  _README_MK_DEV="";  _yes "$F_FLAVORS" && _README_MK_DEV='| `make run-dev` | Run dev flavor |'
  _README_MK_PROD=""; _yes "$F_FLAVORS" && _README_MK_PROD='| `make run-prod` | Run prod flavor |'

  # ── Detect Flutter / Dart SDK versions ───────────────────────────
  _SDK_MIN="3.0.0"
  _FLUTTER_VERSION="3.24.0"
  if command -v flutter &>/dev/null; then
    local _FL_FULL _DART_VER _DART_MAJOR _DART_MINOR
    _FL_FULL=$(flutter --version 2>/dev/null | grep -o 'Flutter [0-9]*\.[0-9]*\.[0-9]*' | head -1 | awk '{print $2}')
    _DART_VER=$(flutter --version --machine 2>/dev/null \
                | grep -o '"dartSdkVersion":"[^"]*"' | head -1 | cut -d'"' -f4 \
                | grep -o '^[0-9]*\.[0-9]*\.[0-9]*')
    [[ -n "$_FL_FULL"  ]] && _FLUTTER_VERSION="$_FL_FULL"
    if [[ -n "$_DART_VER" ]]; then
      _DART_MAJOR=$(echo "$_DART_VER" | cut -d. -f1)
      _DART_MINOR=$(echo "$_DART_VER" | cut -d. -f2)
      _SDK_MIN="${_DART_MAJOR}.${_DART_MINOR}.0"
    fi
  fi
  # FIX: SDK constraint written as plain string; surrounding quotes are part of YAML value
  _SDK_CONSTRAINT=">=${_SDK_MIN} <$(( $(echo "$_SDK_MIN" | cut -d. -f1) + 1 )).0.0"

  # ── Firebase Android BOM version ─────────────────────────────────
  # FIX: Pinned to a real released version (34.x line is current as of 2025)
  _FIREBASE_BOM_VERSION="33.7.0"

  # ════════════════════════════════════════════════════════════════
  # SCAFFOLD — directories
  # ════════════════════════════════════════════════════════════════
  local B="."

  echo -e "${BOLD}${CYAN}  🔨 Scaffolding Flutter project...${RESET}"
  echo ""

  mkdir -p "${B}/.github/workflows"
  _yes "$F_ISSUES" && mkdir -p "${B}/.github/ISSUE_TEMPLATE"

  mkdir -p \
    "${B}/assets/images/icons" \
    "${B}/assets/images/logo" \
    "${B}/assets/images/placeholders" \
    "${B}/assets/fonts" \
    "${B}/assets/animations" \
    "${B}/assets/json" \
    "${B}/assets/audio" \
    "${B}/assets/video"
  _yes "$F_L10N" && mkdir -p "${B}/assets/translations"

  mkdir -p \
    "${B}/lib/core/constants/enums" \
    "${B}/lib/core/errors" \
    "${B}/lib/core/network/api" \
    "${B}/lib/core/network/interceptors" \
    "${B}/lib/core/network/connectivity" \
    "${B}/lib/core/cache" \
    "${B}/lib/core/services" \
    "${B}/lib/core/theme" \
    "${B}/lib/core/utils/extensions" \
    "${B}/lib/core/utils/formatters" \
    "${B}/lib/core/utils/validators" \
    "${B}/lib/core/utils/helpers" \
    "${B}/lib/core/di" \
    "${B}/lib/core/resources"
  _yes "$F_LOGGING" && mkdir -p "${B}/lib/core/logger"

  for FEATURE in auth profile settings; do
    mkdir -p \
      "${B}/lib/features/${FEATURE}/data/datasources" \
      "${B}/lib/features/${FEATURE}/data/models" \
      "${B}/lib/features/${FEATURE}/data/repositories" \
      "${B}/lib/features/${FEATURE}/domain/entities" \
      "${B}/lib/features/${FEATURE}/domain/repositories" \
      "${B}/lib/features/${FEATURE}/domain/usecases" \
      "${B}/lib/features/${FEATURE}/presentation/${SM_DIR}" \
      "${B}/lib/features/${FEATURE}/presentation/pages" \
      "${B}/lib/features/${FEATURE}/presentation/widgets"
  done

  _yes "$F_PUSH" && mkdir -p \
    "${B}/lib/features/notifications/data/datasources" \
    "${B}/lib/features/notifications/data/models" \
    "${B}/lib/features/notifications/data/repositories" \
    "${B}/lib/features/notifications/domain/entities" \
    "${B}/lib/features/notifications/domain/repositories" \
    "${B}/lib/features/notifications/domain/usecases" \
    "${B}/lib/features/notifications/presentation/${SM_DIR}" \
    "${B}/lib/features/notifications/presentation/pages" \
    "${B}/lib/features/notifications/presentation/widgets"

  _yes "$F_PAYMENT" && mkdir -p \
    "${B}/lib/features/payment/data/datasources" \
    "${B}/lib/features/payment/data/models" \
    "${B}/lib/features/payment/data/repositories" \
    "${B}/lib/features/payment/domain/entities" \
    "${B}/lib/features/payment/domain/repositories" \
    "${B}/lib/features/payment/domain/usecases" \
    "${B}/lib/features/payment/presentation/${SM_DIR}" \
    "${B}/lib/features/payment/presentation/pages" \
    "${B}/lib/features/payment/presentation/widgets"

  _yes "$F_MAPS"       && mkdir -p \
    "${B}/lib/features/maps/presentation/pages" \
    "${B}/lib/features/maps/presentation/widgets"
  _yes "$F_CHARTS"     && mkdir -p \
    "${B}/lib/features/dashboard/presentation/pages" \
    "${B}/lib/features/dashboard/presentation/widgets"
  _yes "$F_ONBOARDING" && mkdir -p \
    "${B}/lib/features/onboarding/presentation/pages" \
    "${B}/lib/features/onboarding/presentation/widgets"
  _yes "$F_SPLASH"     && mkdir -p "${B}/lib/features/splash/presentation/pages"

  mkdir -p \
    "${B}/lib/shared/widgets/buttons" \
    "${B}/lib/shared/widgets/cards" \
    "${B}/lib/shared/widgets/dialogs" \
    "${B}/lib/shared/widgets/inputs" \
    "${B}/lib/shared/widgets/layouts" \
    "${B}/lib/shared/widgets/feedback" \
    "${B}/lib/shared/mixins"

  mkdir -p "${B}/lib/routes"
  ( _yes "$F_GOROUTER" || _yes "$F_AUTOROUTE" ) && mkdir -p "${B}/lib/routes/guards"

  mkdir -p "${B}/lib/config"
  _yes "$F_FLAVORS" && mkdir -p "${B}/lib/config/flavors"

  _yes "$F_UNIT_TEST" && mkdir -p \
    "${B}/test/unit/features/auth" \
    "${B}/test/unit/features/profile" \
    "${B}/test/unit/core" \
    "${B}/test/helpers" \
    "${B}/test/fixtures"
  _yes "$F_WIDGET_TEST"      && mkdir -p "${B}/test/widget/features" "${B}/test/widget/shared"
  _yes "$F_INTEGRATION_TEST" && mkdir -p "${B}/test/integration_test"

  # ════════════════════════════════════════════════════════════════
  # CREATE FILES
  # ════════════════════════════════════════════════════════════════

  for DIR in \
    "assets/images/icons" "assets/images/logo" "assets/images/placeholders" \
    "assets/fonts" "assets/animations" "assets/json" "assets/audio" "assets/video"
  do
    touch "${B}/${DIR}/.gitkeep"
  done
  _yes "$F_L10N" && touch "${B}/assets/translations/.gitkeep"

  _dart "lib/core/constants/app_features.dart"; cat > "${B}/lib/core/constants/app_features.dart" << EOF
// ── FEATURE FLAGS ────────────────────────────────────────────
abstract final class AppFeatures {

  // — UI / Theming —
  static const bool enableDarkMode          = true;
  static const bool enableSystemTheme       = true;
  static const bool enableCustomFonts       = true;
  static const bool enableAnimations        = true;
  static const bool enableHaptics           = true;
  static const bool enableSplashScreen      = true;
  static const bool showDebugBanner         = false;
  static const bool showPerformanceOverlay  = false;

  // — Auth —
  static const bool enableGoogleSignIn     = true;
  static const bool enableAppleSignIn      = true;
  static const bool enableEmailAuth        = true;
  static const bool enableGuestMode        = false;
  static const bool enableBiometricLock    = true;
  static const bool enableAutoLogout       = true;

  // — Notifications —
  static const bool enableNotifications      = true;
  static const bool enablePushNotifications  = true;
  static const bool enableLocalNotifications = true;
  static const bool enableEmailNotifications = false;
  static const bool enableInAppBanner        = true;
  static const bool enableNotificationBadge  = true;

  // — AI / Smart Features —
  static const bool enableAiSummary        = false;
  static const bool enableAiChat           = false;
  static const bool enableSmartSearch      = false;
  static const bool enableAutoTagging      = false;
  static const bool enableAiTranslation    = false;

  // — Storage / Sync —
  static const bool enableOfflineMode      = true;
  static const bool enableCloudSync        = false;
  static const bool enableGoogleDrive      = false;
  static const bool enableDropbox          = false;
  static const bool enableOneDrive         = false;
  static const bool enableAutoBackup       = false;
  static const bool enableLocalStorage     = true;

  // — Sharing & Export —
  static const bool enableShareSheet       = true;
  static const bool enableQrShare          = false;
  static const bool enableLinkShare        = false;
  static const bool enablePrint            = true;
  static const bool enableExportCsv        = false;
  static const bool enableExportExcel      = false;

  // — Analytics & Monitoring —
  static const bool enableAnalytics          = true;
  static const bool enableCrashReporting     = true;
  static const bool enablePerformanceMonitor = false;
  static const bool enableUserTracking       = false;
  static const bool enableHeatmaps           = false;
  static const bool enableABTesting          = false;

  // — Monetization —
  static const bool enableSubscription     = true;
  static const bool enableInAppPurchase    = true;
  static const bool enableFreeTier         = true;
  static const bool enableAds              = false;
  static const bool enableReferralProgram  = false;
  static const bool enablePromoCode        = false;

  // — Developer / QA —
  static const bool enableLogging          = false;
  static const bool enableNetworkLogger    = false;
  static const bool enableMockApi          = false;
  static const bool enableShakeToReport    = false;
  static const bool enableInspector        = false;

  // ── Computed helpers ──
  static bool get isAiEnabled    => enableAiSummary || enableAiChat;
  static bool get isCloudEnabled => enableCloudSync || enableGoogleDrive
                                  || enableDropbox  || enableOneDrive;
  static bool get isMonetized    => enableSubscription || enableInAppPurchase
                                  || enableAds;
}
EOF

  _dart "lib/core/constants/app_assets.dart"; cat > "${B}/lib/core/constants/app_assets.dart" << 'EOF'
  // ── 7. ASSETS ────────────────────────────────────────────────
abstract final class AppAssets {
  // — Base Paths —
  // ignore: unused_field
  static const String _fonts = 'assets/fonts';
  static const String _images = 'assets/images';
  static const String _icons = 'assets/images/icons';
  static const String _logo = 'assets/images/logo';
  static const String _placeholder = 'assets/images/placeholders';
  static const String _anim = 'assets/animations';
  static const String _audio = 'assets/audio';
  static const String _json = 'assets/json';
  static const String _translations = 'assets/translations';
  static const String _video = 'assets/video';

  // ── IMAGES ───────────────────────────────────────────────

  // Logo variants
  static const String logo = '$_logo/logo.png';

  // Onboarding
  static const String onboarding1 = '$_images/onboarding_1.png';

  // Placeholders
  static const String placeholderUser = '$_placeholder/ph_user.png';

  // Empty / Error States
  static const String emptyGeneral = '$_images/empty_general.png';

  // Illustrations
  static const String illSuccess = '$_images/ill_success.png';

  // ── ICONS (SVG) ──────────────────────────────────────────

  // Navigation
  static const String icHome = '$_icons/ic_home.svg';

  // Actions
  static const String icUpload = '$_icons/ic_upload.svg';

  // File Types
  static const String icPdf = '$_icons/ic_pdf.svg';

  // Status
  static const String icSuccess = '$_icons/ic_success.svg';

  // Auth / Social
  static const String icGoogle = '$_icons/ic_google.svg';

  // Premium
  static const String icCrown = '$_icons/ic_crown.svg';

  // ── ANIMATIONS (Lottie JSON) ─────────────────────────────

  static const String animLoading = '$_anim/loading.json';

  // ── AUDIO ────────────────────────────────────────────────

  static const String sfxSuccess = '$_audio/sfx_success.mp3';

  // ── JSON (Local Data) ────────────────────────────────────

  static const String jsonCountries = '$_json/countries.json';

  // ── TRANSLATIONS ─────────────────────────────────────────

  static const String transEn = '$_translations/en.json';

  // ── VIDEO ────────────────────────────────────────────────

  static const String videoIntro = '$_video/intro.mp4';

  // ── FONTS ────────────────────────────────────────────────
  // (pubspec.yaml mein register karo — yahan reference ke liye)
  static const String fontInter = 'Inter';
  static const String fontInterMedium = 'Inter-Medium';
  static const String fontInterSemiBold = 'Inter-SemiBold';
  static const String fontInterBold = 'Inter-Bold';
  static const String fontJetBrainsMono = 'JetBrainsMono';
}
EOF

  _dart "lib/core/constants/app_duration.dart"; cat > "${B}/lib/core/constants/app_duration.dart" << EOF
// ── DURATIONS (timeouts / debounce) ──────────────────────
abstract final class AppDurations {
  static const Duration searchDebounce     = Duration(milliseconds: 400);
  static const Duration inputDebounce      = Duration(milliseconds: 300);
  static const Duration buttonThrottle     = Duration(milliseconds: 500);
  static const Duration sessionTimeout     = Duration(minutes: 30);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const Duration otpExpiry          = Duration(minutes: 10);
  static const Duration splashDelay        = Duration(seconds: 2);
  static const Duration toastDuration      = Duration(seconds: 3);
  static const Duration longPressDelay     = Duration(milliseconds: 400);
  static const Duration doubleTapWindow    = Duration(milliseconds: 300);
  static const Duration autoScrollDelay    = Duration(milliseconds: 100);
}
EOF

  _dart "lib/core/constants/app_pagination.dart"; cat > "${B}/lib/core/constants/app_pagination.dart" << EOF
// ── PAGINATION ───────────────────────────────────────────
abstract final class AppPagination {
  static const int defaultPageSize  = 20;
  static const int smallPageSize    = 10;
  static const int largePageSize    = 50;
  static const int firstPage        = 1;
  static const int scrollThreshold  = 200;
  static const int maxOfflineItems  = 100;
}
EOF

  _dart "lib/core/constants/app_layout.dart"; cat > "${B}/lib/core/constants/app_layout.dart" << EOF
// ── UI / LAYOUT ───────────────────────────────────────────
import 'package:flutter/material.dart';

abstract final class AppLayout {

  // — Spacing Scale (8-pt grid) —
  static const double spaceXxs = 2.0;
  static const double spaceXs  = 4.0;
  static const double spaceSm  = 8.0;
  static const double spaceMd  = 16.0;
  static const double spaceLg  = 24.0;
  static const double spaceXl  = 32.0;
  static const double spaceXxl = 48.0;
  static const double space64  = 64.0;
  static const double space80  = 80.0;
  static const double space96  = 96.0;

  // — Insets / Padding (screen-level) —
  static const double screenPaddingH    = 20.0;
  static const double screenPaddingV    = 24.0;
  static const double contentPaddingH   = 16.0;
  static const double contentPaddingV   = 12.0;
  static const double cardPaddingH      = 16.0;
  static const double cardPaddingV      = 14.0;
  static const double listItemPaddingH  = 16.0;
  static const double listItemPaddingV  = 12.0;
  static const double sectionSpacing    = 32.0;
  static const double groupSpacing      = 16.0;

  // — Border Radius —
  static const double radiusXs   = 4.0;
  static const double radiusSm   = 6.0;
  static const double radiusMd   = 10.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 24.0;
  static const double radiusXxl  = 32.0;
  static const double radiusFull = 999.0;

  // — Elevation —
  static const double elevationNone = 0.0;
  static const double elevationXs   = 0.5;
  static const double elevationSm   = 1.0;
  static const double elevationMd   = 4.0;
  static const double elevationLg   = 8.0;
  static const double elevationXl   = 16.0;

  // — Border / Stroke —
  static const double borderThin     = 0.5;
  static const double borderNormal   = 1.0;
  static const double borderMedium   = 1.5;
  static const double borderThick    = 2.0;
  static const double dividerThickness = 0.5;

  // — Opacity —
  static const double opacityDisabled  = 0.38;
  static const double opacityHint      = 0.54;
  static const double opacitySubtle    = 0.70;
  static const double opacityOverlay   = 0.60;
  static const double opacityFull      = 1.00;

  // — App Bars —
  static const double appBarHeight         = 56.0;
  static const double appBarHeightLg       = 64.0;
  static const double appBarElevation      = 0.0;
  static const double appBarIconSize       = 24.0;
  static const double appBarTitleSpacing   = 16.0;

  // — Bottom Navigation —
  static const double bottomNavHeight      = 64.0;
  static const double bottomNavIconSize    = 24.0;
  static const double bottomNavLabelSize   = 11.0;
  static const double bottomNavElevation   = 8.0;

  // — Buttons —
  static const double buttonHeight         = 52.0;
  static const double buttonHeightSm       = 38.0;
  static const double buttonHeightXs       = 30.0;
  static const double buttonMinWidth       = 120.0;
  static const double buttonPaddingH       = 24.0;
  static const double buttonPaddingV       = 14.0;
  static const double buttonBorderWidth    = 1.5;
  static const double buttonIconSize       = 18.0;
  static const double buttonIconGap        = 8.0;

  // — Input Fields —
  static const double inputHeight          = 52.0;
  static const double inputHeightSm        = 44.0;
  static const double inputPaddingH        = 16.0;
  static const double inputPaddingV        = 14.0;
  static const double inputBorderWidth     = 1.0;
  static const double inputBorderFocused   = 1.5;
  static const double inputLabelSize       = 13.0;
  static const double inputHintSize        = 15.0;
  static const double inputHelperSize      = 12.0;
  static const double inputPrefixIconSize  = 20.0;

  // — Cards —
  static const double cardElevation        = 0.0;
  static const double cardBorderWidth      = 1.0;
  static const double cardMinHeight        = 72.0;

  // — List Items —
  static const double listItemHeight       = 64.0;
  static const double listItemHeightSm     = 48.0;
  static const double listItemHeightLg     = 80.0;
  static const double listTileLeadingSize  = 40.0;

  // — Chips / Badges —
  static const double chipHeight           = 32.0;
  static const double chipHeightSm         = 24.0;
  static const double chipPaddingH         = 12.0;
  static const double chipIconSize         = 16.0;
  static const double badgeSize            = 18.0;
  static const double badgeSizeSm          = 8.0;
  static const double badgePaddingH        = 6.0;

  // — Dialogs / Sheets —
  static const double dialogWidth          = 320.0;
  static const double dialogMaxWidth       = 480.0;
  static const double dialogPaddingH       = 24.0;
  static const double dialogPaddingV       = 20.0;
  static const double dialogBorderRadius   = radiusXl;
  static const double bottomSheetRadius    = radiusXl;
  static const double bottomSheetHandleW   = 40.0;
  static const double bottomSheetHandleH   = 4.0;
  static const double modalMaxHeightRatio  = 0.92;

  // — FAB —
  static const double fabSize              = 56.0;
  static const double fabSizeSm           = 40.0;
  static const double fabIconSize          = 24.0;
  static const double fabMarginB           = 16.0;
  static const double fabMarginR           = 16.0;

  // — Avatars —
  static const double avatarSizeXs = 24.0;
  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 44.0;
  static const double avatarSizeLg = 64.0;
  static const double avatarSizeXl = 96.0;

  // — Icons —
  static const double iconSizeXs   = 12.0;
  static const double iconSizeSm   = 16.0;
  static const double iconSizeMd   = 24.0;
  static const double iconSizeLg   = 32.0;
  static const double iconSizeXl   = 48.0;

  // — Images / Thumbnails —
  static const double thumbSizeSm  = 48.0;
  static const double thumbSizeMd  = 80.0;
  static const double thumbSizeLg  = 120.0;
  static const double thumbSizeXl  = 200.0;

  // — Drawer / Sidebar —
  static const double drawerWidth      = 280.0;
  static const double drawerWidthLg    = 320.0;
  static const double drawerHeaderH    = 160.0;

  // — Snackbar / Toast —
  static const double snackbarMaxWidth = 480.0;
  static const double snackbarPaddingH = 16.0;
  static const double snackbarPaddingV = 12.0;
  static const double snackbarRadius   = radiusMd;

  // — Skeleton / Shimmer —
  static const double skeletonRadiusSm = radiusSm;
  static const double skeletonRadiusMd = radiusMd;
  static const double skeletonLineH    = 14.0;
  static const double skeletonLineHSm  = 10.0;

  // — Responsive Breakpoints —
  static const double breakpointMobile  = 480.0;
  static const double breakpointTablet  = 768.0;
  static const double breakpointDesktop = 1024.0;
  static const double breakpointWide    = 1280.0;

  // — Computed Helpers —
  static EdgeInsets get screenPadding => const EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );
  static EdgeInsets get cardPadding => const EdgeInsets.symmetric(
    horizontal: cardPaddingH,
    vertical: cardPaddingV,
  );
  static EdgeInsets get listItemPadding => const EdgeInsets.symmetric(
    horizontal: listItemPaddingH,
    vertical: listItemPaddingV,
  );
  static BorderRadius get cardRadius  => BorderRadius.circular(radiusLg);
  static BorderRadius get buttonRadius => BorderRadius.circular(radiusMd);
  static BorderRadius get inputRadius  => BorderRadius.circular(radiusMd);
  static BorderRadius get chipRadius   => BorderRadius.circular(radiusFull);
  static BorderRadius get dialogRadius => BorderRadius.circular(radiusXl);

  static bool isMobile(double width)  => width < breakpointTablet;
  static bool isTablet(double width)  => width >= breakpointTablet && width < breakpointDesktop;
  static bool isDesktop(double width) => width >= breakpointDesktop;
}
EOF

  _dart "lib/core/constants/app_api.dart"; cat > "${B}/lib/core/constants/app_api.dart" << EOF
// ── API / NETWORK ─────────────────────────────────────────
abstract final class AppApi {
  static const String baseUrl    = 'https://api.rohit.bhure.com/v1';
  static const String cdnUrl     = 'https://cdn.rohit.bhure.com';
  static const String socketUrl  = 'wss://ws.rohit.bhure.com';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout    = Duration(seconds: 30);

  static const int maxRetries      = 3;
  static const int retryDelayMs    = 500;
  static const int maxPageSize     = 20;

  // Headers
  static const String headerAuth        = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerAccept      = 'Accept';
  static const String headerDeviceId    = 'X-Device-Id';
  static const String headerAppVersion  = 'X-App-Version';
  static const String headerPlatform    = 'X-Platform';
  static const String valueJson         = 'application/json';
  static const String valueBearer       = 'Bearer ';

  // Endpoints
  static const String endpointAuth      = '/auth';
  static const String endpointLogin     = '/auth/login';
  static const String endpointRegister  = '/auth/register';
  static const String endpointLogout    = '/auth/logout';
  static const String endpointRefresh   = '/auth/refresh';
  static const String endpointProfile   = '/user/profile';
  static const String endpointUpload    = '/upload';
  static const String endpointSettings  = '/settings';
}

EOF

  _dart "lib/core/constants/app_storage.dart"; cat > "${B}/lib/core/constants/app_storage.dart" << EOF
// ── STORAGE / CACHE KEYS ───────────────────────────────────
abstract final class AppStorage {
  // Auth
  static const String keyAuthToken     = 'auth_token';
  static const String keyRefreshToken  = 'refresh_token';
  static const String keyUserId        = 'user_id';
  static const String keyUserEmail     = 'user_email';

  // Preferences
  static const String keyOnboarded     = 'onboarded';
  static const String keyThemeMode     = 'theme_mode';
  static const String keyLocale        = 'locale';
  static const String keyFontScale     = 'font_scale';
  static const String keyPushEnabled   = 'push_enabled';
  static const String keyBiometric     = 'biometric_enabled';
  static const String keyLastSyncAt    = 'last_sync_at';
  static const String keyFirstLaunch   = 'first_launch';
  static const String keyLastVersion   = 'last_version';

  // Cache
  static const Duration cacheTtlShort  = Duration(minutes: 5);
  static const Duration cacheTtlMedium = Duration(hours: 1);
  static const Duration cacheTtlLong   = Duration(days: 7);
  static const Duration cacheTtlForever = Duration(days: 365);

  // File limits
  static const int maxFileSizeMb     = 50;
  static const int maxFileSizeBytes  = maxFileSizeMb * 1024 * 1024;
  static const int maxImageSizeMb    = 10;
  static const int maxCacheSizeMb    = 200;
  static const int maxRecentItems    = 20;
  static const int maxSearchHistory  = 10;
}

EOF

  _dart "lib/core/constants/app_typography.dart"; cat > "${B}/lib/core/constants/app_typography.dart" << EOF
// ── TYPOGRAPHY ────────────────────────────────────────────
import 'dart:ui';

abstract final class AppTypography {
  static const String fontFamily     = 'Inter';
  static const String fontFamilyMono = 'JetBrainsMono';

  // Font sizes
  static const double textXs   = 11.0;
  static const double textSm   = 13.0;
  static const double textMd   = 15.0;
  static const double textBase = 16.0;
  static const double textLg   = 17.0;
  static const double textXl   = 20.0;
  static const double textXxl  = 24.0;
  static const double textXxxl = 30.0;
  static const double textD1   = 36.0;
  static const double textD2   = 48.0;

  // Font weights
  static const FontWeight weightLight    = FontWeight.w300;
  static const FontWeight weightRegular  = FontWeight.w400;
  static const FontWeight weightMedium   = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold     = FontWeight.w700;
  static const FontWeight weightExtrabold= FontWeight.w800;

  // Line heights
  static const double lineHeightTight   = 1.2;
  static const double lineHeightNormal  = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // Letter spacing
  static const double trackingTight  = -0.5;
  static const double trackingNormal =  0.0;
  static const double trackingWide   =  0.5;
  static const double trackingWidest =  1.5;
  static const double trackingCaps   =  2.0;   // ALL CAPS labels
}

EOF

  _dart "lib/core/constants/app_anim.dart"; cat > "${B}/lib/core/constants/app_anim.dart" << EOF
// ── ANIMATION ─────────────────────────────────────────────
import 'package:flutter/material.dart';

abstract final class AppAnim {
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast    = Duration(milliseconds: 200);
  static const Duration medium  = Duration(milliseconds: 350);
  static const Duration slow    = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 800);

  static const Curve easeIn    = Curves.easeIn;
  static const Curve easeOut   = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring    = Curves.elasticOut;
  static const Curve bounce    = Curves.bounceOut;
  static const Curve decelerate= Curves.decelerate;

  static const Duration pageTransition      = medium;
  static const Curve    pageTransitionCurve = easeInOut;
  static const Duration shimmer            = Duration(milliseconds: 1200);
  static const Duration splashDelay        = Duration(seconds: 2);
  static const Duration snackbarDuration   = Duration(seconds: 3);
  static const Duration tooltipDelay       = Duration(milliseconds: 500);
  static const Duration debounce           = Duration(milliseconds: 400);
}
EOF

  _dart "lib/core/constants/app_durations.dart"; cat > "${B}/lib/core/constants/app_durations.dart" << EOF
// ── DURATIONS (timeouts / debounce) ──────────────────────
abstract final class AppDurations {
  static const Duration searchDebounce    = Duration(milliseconds: 400);
  static const Duration inputDebounce     = Duration(milliseconds: 300);
  static const Duration buttonThrottle    = Duration(milliseconds: 500);
  static const Duration sessionTimeout    = Duration(minutes: 30);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const Duration otpExpiry         = Duration(minutes: 10);
  static const Duration splashDelay       = Duration(seconds: 2);
  static const Duration toastDuration     = Duration(seconds: 3);
  static const Duration longPressDelay    = Duration(milliseconds: 400);
  static const Duration doubleTapWindow   = Duration(milliseconds: 300);
  static const Duration autoScrollDelay   = Duration(milliseconds: 100);
}
EOF

  _dart "lib/core/constants/app_routes.dart"; cat > "${B}/lib/core/constants/app_routes.dart" << EOF
abstract final class AppRoutes {
  static const String splash        = '/';
  static const String onboarding    = '/onboarding';
  static const String login         = '/login';
  static const String register      = '/register';
  static const String forgotPass    = '/forgot-password';
  static const String resetPass     = '/reset-password';
  static const String verifyOtp     = '/verify-otp';
  static const String home          = '/home';
  static const String search        = '/search';
  static const String notifications = '/notifications';
  static const String profile       = '/profile';
  static const String editProfile   = '/profile/edit';
  static const String settings      = '/settings';
  static const String appearance    = '/settings/appearance';
  static const String subscription  = '/subscription';
  static const String paywall       = '/paywall';
  static const String webview       = '/webview';
  static const String privacyPolicy = '/privacy';
  static const String terms         = '/terms';
  static const String about         = '/about';
}

EOF

  _dart "lib/core/constants/app_regex.dart"; cat > "${B}/lib/core/constants/app_regex.dart" << EOF
abstract final class AppRegex {
  static final RegExp email    = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false);
  static final RegExp phone    = RegExp(r'^\+?[0-9]{7,15}$');
  static final RegExp url      = RegExp(r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&/=]*)');
  static final RegExp username = RegExp(r'^[a-zA-Z0-9_.]{3,20}$');
  static final RegExp otp      = RegExp(r'^\d{4,6}$');
  static final RegExp pincode  = RegExp(r'^\d{6}$');
  static final RegExp numeric  = RegExp(r'^\d+$');
  static final RegExp alpha    = RegExp(r'^[a-zA-Z]+$');
  static final RegExp alphaNum = RegExp(r'^[a-zA-Z0-9]+$');

  // Password: min 8 chars, 1 upper, 1 lower, 1 digit
  static final RegExp passwordWeak   = RegExp(r'^.{6,}$');
  static final RegExp passwordStrong = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

  // Helpers
  static bool isValidEmail(String v)    => email.hasMatch(v.trim());
  static bool isValidPhone(String v)    => phone.hasMatch(v.trim());
  static bool isValidUrl(String v)      => url.hasMatch(v.trim());
  static bool isValidUsername(String v) => username.hasMatch(v.trim());
  static bool isValidOtp(String v)      => otp.hasMatch(v.trim());
  static bool isStrongPassword(String v)=> passwordStrong.hasMatch(v);
}
EOF

  _dart "lib/core/constants/app_constants.dart"; cat > "${B}/lib/core/constants/app_constants.dart" << EOF
export 'app_meta.dart';
export 'app_api.dart';
export 'app_storage.dart';
export 'app_layout.dart';
export 'app_typography.dart';
export 'app_anim.dart';
export 'app_assets.dart';
export 'app_routes.dart';
export 'app_features.dart';
export 'app_regex.dart';
export 'app_durations.dart';
export 'app_pagination.dart';
EOF

  _dart "lib/core/constants/app_meta.dart"; cat > "${B}/lib/core/constants/app_meta.dart" << EOF
// ─────────────────────────────────────────────────────────────
// APP CONSTANTS  –  Single source of truth for all app-wide
// configuration. UI/logic code sirf yahan se values le.
// ─────────────────────────────────────────────────────────────

// ── APPLICATION METADATA ──────────────────────────────────
abstract final class AppMeta {
  static const String name        = '${PROJECT_NAME}';
  static const String tagline     = '';
  static const String packageName = '${APP_ID}';
  static const String version     = '1.0.0';
//static const String semVer      = '$version+$buildNumber';

  static const String supportEmail  = '';
  static const String privacyUrl    = '';
  static const String termsUrl      = '';
  static const String websiteUrl    = '';
  static const String playStoreUrl  =
      'https://play.google.com/store/apps/details?id=${APP_ID}';
//static const String appStoreUrl   =
//    'https://apps.apple.com/app/flitpdf/id000000000';

// ── Social links ────────────────────────────────────────────
  static const String twitterUrl   = '';
  static const String instagramUrl = '';
  static const String linkedinUrl  = '';
  static const String youtubeUrl   = '';
}
EOF

  _dart "lib/core/constants/app_colors.dart"; cat > "${B}/lib/core/constants/app_colors.dart" << EOF
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// 1. RAW PALETTE  –  single source of truth
//    only change hex values.
// ─────────────────────────────────────────────
abstract final class _Palette {
  // Red ramp
  static const Color red300 = Color(0xFFFF6F60);
  static const Color red500 = Color(0xFFE53935);
  static const Color red900 = Color(0xFFB71C1C);

  // Orange ramp
  static const Color orange200 = Color(0xFFFFAB91);
  static const Color orange400 = Color(0xFFFF8A65);
  static const Color orange700 = Color(0xFFD84315);

  // Slate ramp  (neutral / grey)
  static const Color slate50  = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Absolute
  static const Color white = Color(0xFFFFFFFF);
  // ignore: unused_field
  static const Color black = Color(0xFF000000);

  // Semantic ramp
  static const Color emerald500 = Color(0xFF10B981);
  static const Color amber500   = Color(0xFFF59E0B);
  static const Color rose500    = Color(0xFFEF4444);
  static const Color blue500    = Color(0xFF3B82F6);
}

// ─────────────────────────────────────────────
// 2. SEMANTIC TOKENS  –  context-aware aliases
//    UI code use this, do not use direct _Palette
// ─────────────────────────────────────────────
abstract final class AppColors {
  AppColors._();

  // — Brand —
  static const Color primary      = _Palette.red500;
  static const Color primaryLight = _Palette.red300;
  static const Color primaryDark  = _Palette.red900;

  static const Color secondary      = _Palette.orange400;
  static const Color secondaryLight = _Palette.orange200;
  static const Color secondaryDark  = _Palette.orange700;

  // — Surface (Light) —
  static const Color background = _Palette.white;
  static const Color surface    = _Palette.white;
  static const Color card       = _Palette.white;

  // — Surface (Dark) —
  static const Color backgroundDark = _Palette.slate900;
  static const Color surfaceDark    = _Palette.slate800;
  static const Color cardDark       = _Palette.slate800;

  // — Text (Light) —
  static const Color textPrimary   = _Palette.slate800;
  static const Color textSecondary = _Palette.slate500;
  static const Color textDisabled  = _Palette.slate400;
  static const Color textLight     = _Palette.white;

  // — Text (Dark) —
  static const Color textPrimaryDark   = _Palette.slate100;
  static const Color textSecondaryDark = _Palette.slate400;
  static const Color textDisabledDark  = _Palette.slate500;

  // — Semantic —
  static const Color success = _Palette.emerald500;
  static const Color warning = _Palette.amber500;
  static const Color error   = _Palette.rose500;
  static const Color info    = _Palette.blue500;

  // — Borders & Dividers —
  static const Color border      = _Palette.slate200;
  static const Color borderDark  = _Palette.slate800;
  static const Color divider     = _Palette.slate100;
  static const Color dividerDark = _Palette.slate800;

  // — Elevation / Special —
  static const Color shadow      = Color(0x0D000000); // 5 % black
  static const Color shadowDark  = Color(0x33000000); // 20 % black
  static const Color glassLight  = Color(0x1AFFFFFF); // 10 % white
  static const Color glassDark   = Color(0x0DFFFFFF); // 5 % white

  // — Grey scale (utility) —
  static const Color grey50  = _Palette.slate50;
  static const Color grey100 = _Palette.slate100;
  static const Color grey200 = _Palette.slate200;
  static const Color grey300 = _Palette.slate300;
  static const Color grey400 = _Palette.slate400;
  static const Color grey500 = _Palette.slate500;
}

// ─────────────────────────────────────────────
// 3. THEME HELPER  –  return correct token
//    based on current brightness (light/dark mode).
//    Usage:  AppColorScheme.of(context).surface
// ─────────────────────────────────────────────
class AppColorScheme {
  const AppColorScheme._({required this.brightness});

  factory AppColorScheme.of(BuildContext context) {
    return AppColorScheme._(
      brightness: Theme.of(context).brightness,
    );
  }

  final Brightness brightness;
  bool get _isDark => brightness == Brightness.dark;

  Color get background  => _isDark ? AppColors.backgroundDark  : AppColors.background;
  Color get surface     => _isDark ? AppColors.surfaceDark      : AppColors.surface;
  Color get card        => _isDark ? AppColors.cardDark         : AppColors.card;

  Color get textPrimary   => _isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
  Color get textSecondary => _isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textDisabled  => _isDark ? AppColors.textDisabledDark  : AppColors.textDisabled;

  Color get border   => _isDark ? AppColors.borderDark  : AppColors.border;
  Color get divider  => _isDark ? AppColors.dividerDark : AppColors.divider;
  Color get shadow   => _isDark ? AppColors.shadowDark  : AppColors.shadow;
  Color get glass    => _isDark ? AppColors.glassDark   : AppColors.glassLight;

  // Semantic
  Color get primary       => AppColors.primary;
  Color get primaryLight  => AppColors.primaryLight;
  Color get primaryDark   => AppColors.primaryDark;
  Color get secondary     => AppColors.secondary;
  Color get success       => AppColors.success;
  Color get warning       => AppColors.warning;
  Color get error         => AppColors.error;
  Color get info          => AppColors.info;
}
EOF


# ── 1. THEME ENUM ────────────────────────────────────────────
_dart "lib/core/constants/enums/app_theme_mode.dart"; cat > "${B}/lib/core/constants/enums/app_theme_mode.dart" << EOF
enum AppThemeMode {
  light,
  dark,
  system;

  bool get isLight  => this == AppThemeMode.light;
  bool get isDark   => this == AppThemeMode.dark;
  bool get isSystem => this == AppThemeMode.system;

  String get label => switch (this) {
    AppThemeMode.light  => 'Light',
    AppThemeMode.dark   => 'Dark',
    AppThemeMode.system => 'System',
  };
}
EOF

# ── 2. AUTH ENUMS ────────────────────────────────────────────
_dart "lib/core/constants/enums/auth_status.dart"; cat > "${B}/lib/core/constants/enums/auth_status.dart" << EOF
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error;

  bool get isAuthenticated   => this == AuthStatus.authenticated;
  bool get isUnauthenticated => this == AuthStatus.unauthenticated;
  bool get isLoading         => this == AuthStatus.loading;
  bool get isError           => this == AuthStatus.error;
}
EOF

_dart "lib/core/constants/enums/auth_provider.dart"; cat > "${B}/lib/core/constants/enums/auth_provider.dart" << EOF
enum AuthProvider {
  email,
  google,
  apple,
  phone,
  guest;

  String get label => switch (this) {
    AuthProvider.email  => 'Email',
    AuthProvider.google => 'Google',
    AuthProvider.apple  => 'Apple',
    AuthProvider.phone  => 'Phone',
    AuthProvider.guest  => 'Guest',
  };

  bool get isSocial => this == AuthProvider.google || this == AuthProvider.apple;
  bool get isGuest  => this == AuthProvider.guest;
}
EOF

_dart "lib/core/constants/enums/otp_type.dart"; cat > "${B}/lib/core/constants/enums/otp_type.dart" << EOF
enum OtpType {
  emailVerification,
  phoneVerification,
  passwordReset,
  twoFactor;
}
EOF

# ── 3. USER ENUMS ────────────────────────────────────────────
_dart "lib/core/constants/enums/user_role.dart"; cat > "${B}/lib/core/constants/enums/user_role.dart" << EOF
enum UserRole {
  guest,
  free,
  pro,
  admin;

  bool get isPro   => this == UserRole.pro || this == UserRole.admin;
  bool get isAdmin => this == UserRole.admin;
  bool get isGuest => this == UserRole.guest;
  bool get isFree  => this == UserRole.free;

  String get label => switch (this) {
    UserRole.guest => 'Guest',
    UserRole.free  => 'Free',
    UserRole.pro   => 'Pro',
    UserRole.admin => 'Admin',
  };
}
EOF

_dart "lib/core/constants/enums/user_status.dart"; cat > "${B}/lib/core/constants/enums/user_status.dart" << EOF
enum UserStatus {
  active,
  inactive,
  banned,
  pendingVerification;

  bool get isActive   => this == UserStatus.active;
  bool get isBanned   => this == UserStatus.banned;
  bool get isPending  => this == UserStatus.pendingVerification;
  bool get isInactive => this == UserStatus.inactive;
}
EOF

_dart "lib/core/constants/enums/gender.dart"; cat > "${B}/lib/core/constants/enums/gender.dart" << EOF
enum Gender {
  male,
  female,
  other,
  preferNotToSay;

  String get label => switch (this) {
    Gender.male           => 'Male',
    Gender.female         => 'Female',
    Gender.other          => 'Other',
    Gender.preferNotToSay => 'Prefer not to say',
  };
}
EOF

# ── 4. API / NETWORK ENUMS ───────────────────────────────────
_dart "lib/core/constants/enums/api_status.dart"; cat > "${B}/lib/core/constants/enums/api_status.dart" << EOF
enum ApiStatus {
  initial,
  loading,
  success,
  failure,
  empty;

  bool get isInitial => this == ApiStatus.initial;
  bool get isLoading => this == ApiStatus.loading;
  bool get isSuccess => this == ApiStatus.success;
  bool get isFailure => this == ApiStatus.failure;
  bool get isEmpty   => this == ApiStatus.empty;
  bool get isDone    => isSuccess || isFailure;
}
EOF

_dart "lib/core/constants/enums/network_status.dart"; cat > "${B}/lib/core/constants/enums/network_status.dart" << EOF
enum NetworkStatus {
  online,
  offline,
  limited;

  bool get isOnline  => this == NetworkStatus.online;
  bool get isOffline => this == NetworkStatus.offline;
  bool get isLimited => this == NetworkStatus.limited;
}
EOF

_dart "lib/core/constants/enums/http_method.dart"; cat > "${B}/lib/core/constants/enums/http_method.dart" << EOF
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete;

  String get value => name.toUpperCase();
}
EOF

_dart "lib/core/constants/enums/api_error_type.dart"; cat > "${B}/lib/core/constants/enums/api_error_type.dart" << EOF
enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  unknown;

  bool get isUnauthorized => this == ApiErrorType.unauthorized;
  bool get isNetwork      => this == ApiErrorType.network;
  bool get isServer       => this == ApiErrorType.server;
}
EOF

# ── 5. FILE ENUMS ────────────────────────────────────────────
_dart "lib/core/constants/enums/file_type.dart"; cat > "${B}/lib/core/constants/enums/file_type.dart" << EOF
enum FileType {
  pdf,
  docx,
  doc,
  txt,
  image,
  video,
  audio,
  other;

  String get extension => switch (this) {
    FileType.pdf   => 'pdf',
    FileType.docx  => 'docx',
    FileType.doc   => 'doc',
    FileType.txt   => 'txt',
    FileType.image => 'png',
    FileType.video => 'mp4',
    FileType.audio => 'mp3',
    FileType.other => '',
  };

  bool get isDocument => this == FileType.pdf  ||
                         this == FileType.docx ||
                         this == FileType.doc  ||
                         this == FileType.txt;

  bool get isMedia    => this == FileType.image ||
                         this == FileType.video ||
                         this == FileType.audio;
}
EOF

_dart "lib/core/constants/enums/sort_order.dart"; cat > "${B}/lib/core/constants/enums/sort_order.dart" << EOF
enum SortOrder {
  nameAsc,
  nameDesc,
  dateAsc,
  dateDesc,
  sizeAsc,
  sizeDesc;

  String get label => switch (this) {
    SortOrder.nameAsc  => 'Name (A–Z)',
    SortOrder.nameDesc => 'Name (Z–A)',
    SortOrder.dateAsc  => 'Oldest first',
    SortOrder.dateDesc => 'Newest first',
    SortOrder.sizeAsc  => 'Smallest first',
    SortOrder.sizeDesc => 'Largest first',
  };
}
EOF

_dart "lib/core/constants/enums/view_mode.dart"; cat > "${B}/lib/core/constants/enums/view_mode.dart" << EOF
enum ViewMode {
  grid,
  list;

  bool get isGrid => this == ViewMode.grid;
  bool get isList => this == ViewMode.list;
}
EOF

# ── 6. UPLOAD / DOWNLOAD ENUMS ───────────────────────────────
_dart "lib/core/constants/enums/upload_status.dart"; cat > "${B}/lib/core/constants/enums/upload_status.dart" << EOF
enum UploadStatus {
  idle,
  picking,
  uploading,
  processing,
  completed,
  failed,
  cancelled;

  bool get isActive    => this == UploadStatus.uploading ||
                          this == UploadStatus.processing;
  bool get isCompleted => this == UploadStatus.completed;
  bool get isFailed    => this == UploadStatus.failed;
  bool get isIdle      => this == UploadStatus.idle;
}
EOF

_dart "lib/core/constants/enums/download_status.dart"; cat > "${B}/lib/core/constants/enums/download_status.dart" << EOF
enum DownloadStatus {
  idle,
  downloading,
  completed,
  failed,
  cancelled;

  bool get isActive    => this == DownloadStatus.downloading;
  bool get isCompleted => this == DownloadStatus.completed;
  bool get isFailed    => this == DownloadStatus.failed;
}
EOF

# ── 7. NOTIFICATION ENUMS ────────────────────────────────────
_dart "lib/core/constants/enums/notification_type.dart"; cat > "${B}/lib/core/constants/enums/notification_type.dart" << EOF
enum NotificationType {
  general,
  upload,
  download,
  payment,
  security,
  update,
  promotion,
  reminder;

  String get label => switch (this) {
    NotificationType.general   => 'General',
    NotificationType.upload    => 'Upload',
    NotificationType.download  => 'Download',
    NotificationType.payment   => 'Payment',
    NotificationType.security  => 'Security',
    NotificationType.update    => 'Update',
    NotificationType.promotion => 'Promotion',
    NotificationType.reminder  => 'Reminder',
  };
}
EOF

_dart "lib/core/constants/enums/notification_priority.dart"; cat > "${B}/lib/core/constants/enums/notification_priority.dart" << EOF
enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  bool get isUrgent => this == NotificationPriority.urgent;
  bool get isHigh   => this == NotificationPriority.high;
}
EOF

# ── 8. SUBSCRIPTION / PAYMENT ENUMS ─────────────────────────
_dart "lib/core/constants/enums/subscription_plan.dart"; cat > "${B}/lib/core/constants/enums/subscription_plan.dart" << EOF
enum SubscriptionPlan {
  free,
  monthly,
  yearly,
  lifetime;

  bool get isPaid => this != SubscriptionPlan.free;
  bool get isFree => this == SubscriptionPlan.free;

  String get label => switch (this) {
    SubscriptionPlan.free     => 'Free',
    SubscriptionPlan.monthly  => 'Monthly',
    SubscriptionPlan.yearly   => 'Yearly',
    SubscriptionPlan.lifetime => 'Lifetime',
  };
}
EOF

_dart "lib/core/constants/enums/payment_status.dart"; cat > "${B}/lib/core/constants/enums/payment_status.dart" << EOF
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled;

  bool get isCompleted  => this == PaymentStatus.completed;
  bool get isFailed     => this == PaymentStatus.failed;
  bool get isPending    => this == PaymentStatus.pending;
  bool get isRefunded   => this == PaymentStatus.refunded;
}
EOF

_dart "lib/core/constants/enums/payment_method.dart"; cat > "${B}/lib/core/constants/enums/payment_method.dart" << EOF
enum PaymentMethod {
  card,
  upi,
  netBanking,
  wallet,
  cod;

  String get label => switch (this) {
    PaymentMethod.card       => 'Credit / Debit Card',
    PaymentMethod.upi        => 'UPI',
    PaymentMethod.netBanking => 'Net Banking',
    PaymentMethod.wallet     => 'Wallet',
    PaymentMethod.cod        => 'Cash on Delivery',
  };
}
EOF

# ── 9. UI STATE ENUMS ────────────────────────────────────────
_dart "lib/core/constants/enums/page_state.dart"; cat > "${B}/lib/core/constants/enums/page_state.dart" << EOF
enum PageState {
  initial,
  loading,
  loaded,
  empty,
  error,
  loadingMore;

  bool get isInitial    => this == PageState.initial;
  bool get isLoading    => this == PageState.loading;
  bool get isLoaded     => this == PageState.loaded;
  bool get isEmpty      => this == PageState.empty;
  bool get isError      => this == PageState.error;
  bool get isLoadingMore => this == PageState.loadingMore;
  bool get showContent  => isLoaded || isLoadingMore;
}
EOF

_dart "lib/core/constants/enums/snackbar_type.dart"; cat > "${B}/lib/core/constants/enums/snackbar_type.dart" << EOF
enum SnackbarType {
  success,
  error,
  warning,
  info;

  bool get isSuccess => this == SnackbarType.success;
  bool get isError   => this == SnackbarType.error;
}
EOF

_dart "lib/core/constants/enums/dialog_type.dart"; cat > "${B}/lib/core/constants/enums/dialog_type.dart" << EOF
enum DialogType {
  info,
  success,
  warning,
  error,
  confirm,
  custom;

  bool get isConfirm => this == DialogType.confirm;
  bool get isError   => this == DialogType.error;
}
EOF

_dart "lib/core/constants/enums/button_state.dart"; cat > "${B}/lib/core/constants/enums/button_state.dart" << EOF
enum ButtonState {
  idle,
  loading,
  success,
  error,
  disabled;

  bool get isLoading  => this == ButtonState.loading;
  bool get isDisabled => this == ButtonState.disabled;
  bool get isSuccess  => this == ButtonState.success;
  bool get isIdle     => this == ButtonState.idle;
}
EOF

# ── 10. LOCALE ENUM ──────────────────────────────────────────
_dart "lib/core/constants/enums/app_locale.dart"; cat > "${B}/lib/core/constants/enums/app_locale.dart" << EOF
enum AppLocale {
  en,
  hi,
  ar,
  fr,
  es,
  de,
  zh;

  String get code => name;

  String get label => switch (this) {
    AppLocale.en => 'English',
    AppLocale.hi => 'हिन्दी',
    AppLocale.ar => 'العربية',
    AppLocale.fr => 'Français',
    AppLocale.es => 'Español',
    AppLocale.de => 'Deutsch',
    AppLocale.zh => '中文',
  };

  bool get isRtl => this == AppLocale.ar;
}
EOF

# ── 11. PERMISSION ENUMS ─────────────────────────────────────
_dart "lib/core/constants/enums/app_permission.dart"; cat > "${B}/lib/core/constants/enums/app_permission.dart" << EOF
enum AppPermission {
  camera,
  gallery,
  storage,
  microphone,
  location,
  notification,
  contacts,
  biometric;

  String get label => switch (this) {
    AppPermission.camera       => 'Camera',
    AppPermission.gallery      => 'Gallery',
    AppPermission.storage      => 'Storage',
    AppPermission.microphone   => 'Microphone',
    AppPermission.location     => 'Location',
    AppPermission.notification => 'Notification',
    AppPermission.contacts     => 'Contacts',
    AppPermission.biometric    => 'Biometric',
  };
}
EOF

_dart "lib/core/constants/enums/permission_status.dart"; cat > "${B}/lib/core/constants/enums/permission_status.dart" << EOF
enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted;

  bool get isGranted           => this == PermissionStatus.granted;
  bool get isDenied            => this == PermissionStatus.denied;
  bool get isPermanentlyDenied => this == PermissionStatus.permanentlyDenied;
  bool get needsRequest        => this == PermissionStatus.denied;
  bool get needsSettings       => this == PermissionStatus.permanentlyDenied;
}
EOF

# ── 12. ENVIRONMENT ENUM ─────────────────────────────────────
_dart "lib/core/constants/enums/app_environment.dart"; cat > "${B}/lib/core/constants/enums/app_environment.dart" << EOF
enum AppEnvironment {
  dev,
  staging,
  prod;

  bool get isDev     => this == AppEnvironment.dev;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProd    => this == AppEnvironment.prod;

  String get label => switch (this) {
    AppEnvironment.dev     => 'Development',
    AppEnvironment.staging => 'Staging',
    AppEnvironment.prod    => 'Production',
  };
}
EOF

# ── BARREL EXPORT ────────────────────────────────────────────
_dart "lib/core/constants/enums/app_enums.dart"; cat > "${B}/lib/core/constants/enums/app_enums.dart" << EOF
// ── Barrel export ────────────────────
export 'app_theme_mode.dart';
export 'auth_status.dart';
export 'auth_provider.dart';
export 'otp_type.dart';
export 'user_role.dart';
export 'user_status.dart';
export 'gender.dart';
export 'api_status.dart';
export 'network_status.dart';
export 'http_method.dart';
export 'api_error_type.dart';
export 'file_type.dart';
export 'sort_order.dart';
export 'view_mode.dart';
export 'upload_status.dart';
export 'download_status.dart';
export 'notification_type.dart';
export 'notification_priority.dart';
export 'subscription_plan.dart';
export 'payment_status.dart';
export 'payment_method.dart';
export 'page_state.dart';
export 'snackbar_type.dart';
export 'dialog_type.dart';
export 'button_state.dart';
export 'app_locale.dart';
export 'app_permission.dart';
export 'permission_status.dart';
export 'app_environment.dart';
EOF

  _dart "lib/core/errors/exceptions.dart"

  _dart "lib/core/errors/failures.dart"
  _dart "lib/core/errors/error_messages.dart"

  if [[ "$API_CHOICE" == "1" || "$API_CHOICE" == "5" ]]; then
    _dart "lib/core/network/api/api_client.dart"
    _dart "lib/core/network/api/api_endpoints.dart"
    _dart "lib/core/network/interceptors/auth_interceptor.dart"
    _dart "lib/core/network/interceptors/logging_interceptor.dart"
  fi
  if [[ "$API_CHOICE" == "3" || "$API_CHOICE" == "5" ]]; then
    _dart "lib/core/network/api/api_firebase.dart"
  fi
  _yes "$F_CONNECTIVITY" && _dart "lib/core/network/connectivity/connectivity_service.dart"

# ── 1. CACHE KEYS ────────────────────────────────────────────
_dart "lib/core/cache/cache_keys.dart"; cat > "${B}/lib/core/cache/cache_keys.dart" << EOF
// ─────────────────────────────────────────────────────────────
// CacheKeys
//
// Single source of truth for all cache key strings used
// throughout the application.
//
// Rules:
//   - Never use raw strings for cache keys anywhere in the codebase.
//   - Always reference a constant or helper method from this class.
//   - Key format:  cache:<domain>:<identifier>
// ─────────────────────────────────────────────────────────────

abstract final class CacheKeys {

  // ── Authentication ────────────────────────────────────────

  /// JWT access token issued by the server.
  static const String authToken     = 'cache:auth:token';

  /// Long-lived refresh token used to obtain a new access token.
  static const String refreshToken  = 'cache:auth:refresh_token';

  /// Unique identifier of the currently authenticated user.
  static const String userId        = 'cache:auth:user_id';

  /// Email address of the currently authenticated user.
  static const String userEmail     = 'cache:auth:user_email';

  /// ISO-8601 timestamp at which the current session expires.
  static const String sessionExpiry = 'cache:auth:session_expiry';

  // ── User / Profile ────────────────────────────────────────

  /// Full user profile object serialised as JSON.
  static const String userProfile   = 'cache:user:profile';

  /// User-defined application settings serialised as JSON.
  static const String userSettings  = 'cache:user:settings';

  /// Lightweight user preferences (theme, locale, notifications).
  static const String userPrefs     = 'cache:user:prefs';

  /// Remote URL or local path of the user avatar image.
  static const String userAvatar    = 'cache:user:avatar';

  // ── Application State ─────────────────────────────────────

  /// Whether the user has completed the onboarding flow.
  static const String onboarded     = 'cache:app:onboarded';

  /// Persisted theme mode: light | dark | system.
  static const String themeMode     = 'cache:app:theme_mode';

  /// BCP-47 locale code selected by the user (e.g. "en", "hi").
  static const String locale        = 'cache:app:locale';

  /// Whether this is the very first launch of the application.
  static const String firstLaunch   = 'cache:app:first_launch';

  /// Semver string of the last app version that was launched.
  static const String lastVersion   = 'cache:app:last_version';

  /// ISO-8601 timestamp of the last successful data sync.
  static const String lastSyncAt    = 'cache:app:last_sync_at';

  // ── Notifications ─────────────────────────────────────────

  /// Whether the user has granted push-notification permission.
  static const String pushEnabled   = 'cache:notif:push_enabled';

  /// Timestamp of the last notification the user has viewed.
  static const String lastNotifSeen = 'cache:notif:last_seen';

  // ── Subscription ──────────────────────────────────────────

  /// Active subscription plan identifier (free | monthly | yearly | lifetime).
  static const String subPlan       = 'cache:sub:plan';

  /// ISO-8601 expiry date of the active subscription.
  static const String subExpiry     = 'cache:sub:expiry';

  /// Current subscription status (active | expired | cancelled).
  static const String subStatus     = 'cache:sub:status';

  // ── Search ────────────────────────────────────────────────

  /// JSON-encoded list of recent search query strings.
  static const String searchHistory = 'cache:search:history';

  /// JSON-encoded list of recently accessed file identifiers.
  static const String recentFiles   = 'cache:files:recent';

  // ── Dynamic Key Builders ──────────────────────────────────
  // Use these factory methods when the key depends on a runtime value.

  /// Cache key for a single file identified by [id].
  static String file(String id)     => 'cache:file:\$id';

  /// Cache key for a single document identified by [id].
  static String document(String id) => 'cache:doc:\$id';

  /// Cache key for a paginated page at the given route [name].
  static String page(String name)   => 'cache:page:\$name';

  /// Cache key for a query result identified by its [hash].
  static String query(String hash)  => 'cache:query:\$hash';

  /// Cache key for a remote image identified by its [url].
  static String image(String url)   => 'cache:img:\$url';

  /// Cache key for a user record identified by [id].
  static String userById(String id) => 'cache:user:\$id';
}
EOF

# ── 2. CACHE POLICY ──────────────────────────────────────────
_dart "lib/core/cache/cache_policy.dart"; cat > "${B}/lib/core/cache/cache_policy.dart" << EOF
// ─────────────────────────────────────────────────────────────
// CachePolicy
//
// Defines the time-to-live (TTL) and fetch strategy for each
// category of cached data.
//
// Usage:
//   await CacheManager.instance.setJson(
//     CacheKeys.userProfile,
//     data,
//     policy: CachePolicy.userProfile,
//   );
// ─────────────────────────────────────────────────────────────

// ── Cache Strategy ───────────────────────────────────────────

/// Determines the source of data and the order in which sources
/// are consulted when reading a cached value.
enum CacheStrategy {
  /// Return data from cache only. Never contact the network.
  /// Suitable for fully offline scenarios.
  cacheOnly,

  /// Always fetch from the network. Never read from cache.
  /// Suitable for data that must always be current.
  networkOnly,

  /// Return cached data when available and unexpired;
  /// otherwise fall back to the network.
  /// Best for data that rarely changes.
  cacheFirst,

  /// Always attempt the network first.
  /// Fall back to cached data only on failure.
  /// Best for frequently updated data.
  networkFirst,

  /// Immediately return stale cached data (if present),
  /// then trigger a background revalidation.
  /// Best for feeds where instant display matters more than freshness.
  staleWhileRevalidate,
}

// ── Cache Policy ─────────────────────────────────────────────

/// Encapsulates the caching rules applied to a single cache entry.
class CachePolicy {
  const CachePolicy({
    required this.ttl,
    this.strategy = CacheStrategy.cacheFirst,
    this.maxStaleAge,
    this.encrypt = false,
  });

  /// Maximum age of a cached value before it is considered expired.
  /// Use [Duration.zero] to disable TTL (the entry never expires).
  final Duration ttl;

  /// The fetch strategy applied when reading this entry.
  final CacheStrategy strategy;

  /// Only relevant for [CacheStrategy.staleWhileRevalidate].
  /// The maximum age of stale data that may still be served while
  /// a background refresh is in progress.
  final Duration? maxStaleAge;

  /// When true, the value is encrypted before being written to disk.
  /// Enable for tokens, personal data, or any sensitive content.
  final bool encrypt;

  /// Returns true when this policy has a finite TTL.
  bool get isExpirable => ttl != Duration.zero;

  // ── Predefined Policies ───────────────────────────────────

  /// Short-lived, encrypted policy for authentication tokens.
  static const CachePolicy auth = CachePolicy(
    ttl:      Duration(hours: 1),
    strategy: CacheStrategy.cacheFirst,
    encrypt:  true,
  );

  /// Medium-lived policy for the user profile.
  /// The network is tried first to ensure reasonable freshness.
  static const CachePolicy userProfile = CachePolicy(
    ttl:      Duration(hours: 6),
    strategy: CacheStrategy.networkFirst,
  );

  /// Long-lived policy for application settings and preferences.
  static const CachePolicy settings = CachePolicy(
    ttl:      Duration(days: 30),
    strategy: CacheStrategy.cacheFirst,
  );

  /// Policy for feeds and lists where instant display is preferred.
  static const CachePolicy feed = CachePolicy(
    ttl:         Duration(minutes: 10),
    strategy:    CacheStrategy.staleWhileRevalidate,
    maxStaleAge: Duration(hours: 1),
  );

  /// Short-lived policy for search results.
  static const CachePolicy search = CachePolicy(
    ttl:      Duration(minutes: 5),
    strategy: CacheStrategy.networkFirst,
  );

  /// Long-lived policy for images and other media assets.
  static const CachePolicy media = CachePolicy(
    ttl:      Duration(days: 7),
    strategy: CacheStrategy.cacheFirst,
  );

  /// Policy for static reference data that almost never changes
  /// (country lists, currency tables, FAQ content, etc.).
  static const CachePolicy staticData = CachePolicy(
    ttl:      Duration(days: 365),
    strategy: CacheStrategy.cacheFirst,
  );

  /// Bypass policy — data is never read from or written to the cache.
  static const CachePolicy noCache = CachePolicy(
    ttl:      Duration.zero,
    strategy: CacheStrategy.networkOnly,
  );

  /// Short-lived encrypted policy scoped to the current user session.
  static const CachePolicy session = CachePolicy(
    ttl:      Duration(hours: 12),
    strategy: CacheStrategy.cacheFirst,
    encrypt:  true,
  );

  // ── Utilities ─────────────────────────────────────────────

  /// Returns a copy of this policy with the specified fields replaced.
  CachePolicy copyWith({
    Duration?      ttl,
    CacheStrategy? strategy,
    Duration?      maxStaleAge,
    bool?          encrypt,
  }) {
    return CachePolicy(
      ttl:         ttl         ?? this.ttl,
      strategy:    strategy    ?? this.strategy,
      maxStaleAge: maxStaleAge ?? this.maxStaleAge,
      encrypt:     encrypt     ?? this.encrypt,
    );
  }
}
EOF

# ── 3. CACHE MANAGER ─────────────────────────────────────────
_dart "lib/core/cache/cache_manager.dart"; cat > "${B}/lib/core/cache/cache_manager.dart" << EOF
// ─────────────────────────────────────────────────────────────
// CacheManager
//
// A thin, policy-aware wrapper around SharedPreferences.
// Handles reading, writing, expiry checking, and invalidation
// of cached values throughout the application.
//
// Lifecycle:
//   Call [init] once at application startup before invoking
//   any other method on this class.
//
// Example:
//   // Initialise once in main.dart
//   await CacheManager.instance.init();
//
//   // Write a value
//   await CacheManager.instance.setJson(
//     CacheKeys.userProfile,
//     user.toJson(),
//     policy: CachePolicy.userProfile,
//   );
//
//   // Read a value
//   final json = CacheManager.instance.getJson(CacheKeys.userProfile);
//
//   // Remove a specific entry
//   await CacheManager.instance.remove(CacheKeys.userProfile);
//
//   // Remove all entries whose keys start with a prefix
//   await CacheManager.instance.removeWhere('cache:file:');
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_policy.dart';

// ── Internal Entry Model ──────────────────────────────────────

/// Wraps a cached payload with its expiry timestamp.
/// Instances are serialised to JSON and stored in SharedPreferences.
class _CacheEntry {
  const _CacheEntry({
    required this.data,
    required this.expiresAt,
  });

  /// The cached payload (a raw string or a JSON-encoded string).
  final String data;

  /// The point in time after which this entry is stale.
  final DateTime expiresAt;

  /// Returns true when [DateTime.now] has passed [expiresAt].
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'data':      data,
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory _CacheEntry.fromJson(Map<String, dynamic> json) => _CacheEntry(
    data:      json['data']      as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}

// ── Cache Manager ─────────────────────────────────────────────

class CacheManager {
  CacheManager._();

  /// The application-wide singleton instance.
  static final CacheManager instance = CacheManager._();

  SharedPreferences? _prefs;

  // ── Initialisation ────────────────────────────────────────

  /// Initialises the underlying [SharedPreferences] instance.
  ///
  /// Must be awaited once before any other method is called,
  /// typically at the top of [main].
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(
      _prefs != null,
      'CacheManager.init() must be called before accessing the cache.',
    );
    return _prefs!;
  }

  // ── Write Operations ──────────────────────────────────────

  /// Stores a [String] value under [key] with the given [policy].
  Future<void> setString(
    String key,
    String value, {
    CachePolicy policy = CachePolicy.session,
  }) async {
    final entry = _CacheEntry(
      data:      value,
      expiresAt: DateTime.now().add(policy.ttl),
    );
    await _p.setString(key, jsonEncode(entry.toJson()));
  }

  /// Stores a JSON-serialisable [Map] under [key] with the given [policy].
  Future<void> setJson(
    String key,
    Map<String, dynamic> value, {
    CachePolicy policy = CachePolicy.session,
  }) async {
    await setString(key, jsonEncode(value), policy: policy);
  }

  /// Stores a [bool] value under [key].
  ///
  /// Boolean values carry no TTL and persist until explicitly removed.
  Future<void> setBool(String key, {required bool value}) async {
    await _p.setBool(key, value);
  }

  /// Stores an [int] value under [key].
  Future<void> setInt(String key, int value) async {
    await _p.setInt(key, value);
  }

  /// Stores a [List<String>] under [key] with the given [policy].
  Future<void> setStringList(
    String key,
    List<String> value, {
    CachePolicy policy = CachePolicy.session,
  }) async {
    await setString(key, jsonEncode(value), policy: policy);
  }

  // ── Read Operations ───────────────────────────────────────

  /// Returns the cached [String] for [key].
  ///
  /// Returns null when the entry does not exist or has expired.
  /// Expired entries are removed automatically.
  String? getString(String key) {
    final raw = _p.getString(key);
    if (raw == null) return null;

    try {
      final entry = _CacheEntry.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (entry.isExpired) {
        remove(key);
        return null;
      }
      return entry.data;
    } catch (_) {
      // Value was stored as a plain string without a TTL wrapper.
      return raw;
    }
  }

  /// Returns the cached [Map] for [key].
  ///
  /// Returns null when the entry is absent, expired, or cannot be decoded.
  Map<String, dynamic>? getJson(String key) {
    final raw = getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Returns the cached [bool] for [key], or [defaultValue] when absent.
  bool getBool(String key, {bool defaultValue = false}) =>
      _p.getBool(key) ?? defaultValue;

  /// Returns the cached [int] for [key], or [defaultValue] when absent.
  int getInt(String key, {int defaultValue = 0}) =>
      _p.getInt(key) ?? defaultValue;

  /// Returns the cached [List<String>] for [key].
  ///
  /// Returns null when the entry is absent, expired, or cannot be decoded.
  List<String>? getStringList(String key) {
    final raw = getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return null;
    }
  }

  /// Returns true when a valid, unexpired entry exists for [key].
  bool has(String key) => getString(key) != null;

  // ── Invalidation ──────────────────────────────────────────

  /// Removes the single entry stored under [key].
  Future<void> remove(String key) async {
    await _p.remove(key);
  }

  /// Removes all entries whose keys begin with [prefix].
  ///
  /// Example — remove every file cache entry:
  ///   await CacheManager.instance.removeWhere('cache:file:');
  Future<void> removeWhere(String prefix) async {
    final keys = _p.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      await _p.remove(k);
    }
  }

  /// Scans all stored entries and removes those that have expired.
  ///
  /// Call this periodically (e.g. on app resume) to reclaim storage
  /// and keep SharedPreferences lean.
  Future<void> evictExpired() async {
    final keys = _p.getKeys().toList();
    for (final key in keys) {
      final raw = _p.getString(key);
      if (raw == null) continue;
      try {
        final entry = _CacheEntry.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (entry.isExpired) await _p.remove(key);
      } catch (_) {
        // Entry is a plain value with no TTL wrapper — leave it untouched.
      }
    }
  }

  /// Removes every key from SharedPreferences.
  ///
  /// Use with caution — this erases all persisted data,
  /// not only cache entries.
  Future<void> clearAll() async => _p.clear();

  /// Removes only entries that follow the "cache:" naming convention,
  /// leaving other SharedPreferences values (device settings, etc.) intact.
  Future<void> clearCache() async => removeWhere('cache:');
}
EOF

# ── BARREL EXPORT ────────────────────────────────────────────
_dart "lib/core/cache/cache.dart"; cat > "${B}/lib/core/cache/cache.dart" << EOF
// ─────────────────────────────────────────────────────────────
// Cache barrel export.
//
// Import this single file to access all cache utilities.
//
// Usage:
//   import 'package:your_app/core/cache/cache.dart';
// ─────────────────────────────────────────────────────────────

export 'cache_keys.dart';
export 'cache_policy.dart';
export 'cache_manager.dart';
EOF



  _dart "lib/core/services/navigation_service.dart"
  _dart "lib/core/services/storage_service.dart"
  _yes "$F_PUSH"          && _dart "lib/core/services/notification_service.dart"
  _yes "$F_ANALYTICS"     && _dart "lib/core/services/analytics_service.dart"
  _yes "$F_SHARE"         && _dart "lib/core/services/share_service.dart"
  _yes "$F_PERMISSIONS"   && _dart "lib/core/services/permission_service.dart"
  _yes "$F_LOCAL_NOTIF"   && _dart "lib/core/services/local_notification_service.dart"
  _yes "$F_SENTRY"        && _dart "lib/core/services/crash_reporting_service.dart"
  _yes "$F_REMOTE_CONFIG" && _dart "lib/core/services/remote_config_service.dart"

  _dart "lib/core/theme/app_theme.dart"
  _yes "$F_THEME" && _dart "lib/core/theme/light_theme.dart"
  _yes "$F_THEME" && _dart "lib/core/theme/dark_theme.dart"

  _dart "lib/core/utils/extensions/context_ext.dart"
  _dart "lib/core/utils/extensions/string_ext.dart"
  _dart "lib/core/utils/extensions/date_time_ext.dart"
  _dart "lib/core/utils/extensions/list_ext.dart"
  _dart "lib/core/utils/formatters/date_formatter.dart"
  _dart "lib/core/utils/formatters/number_formatter.dart"
  _dart "lib/core/utils/validators/email_validator.dart"
  _dart "lib/core/utils/validators/input_validators.dart"
  _dart "lib/core/utils/helpers/helper.dart"
  _dart "lib/core/utils/helpers/permission_helper.dart"

  _yes "$F_DI" && _dart "lib/core/di/injection_container.dart"
  _yes "$F_DI" && _dart "lib/core/di/injection_container.config.dart"

  if _yes "$F_LOGGING"; then
    _dart "lib/core/logger/app_logger.dart"
    _dart "lib/core/logger/log_printer.dart"
  fi

  _dart "lib/core/resources/color_manager.dart"
  _dart "lib/core/resources/font_manager.dart"
  _dart "lib/core/resources/image_manager.dart"
  _dart "lib/core/resources/value_manager.dart"

  _dart "lib/features/auth/data/datasources/auth_local_datasource.dart"
  _dart "lib/features/auth/data/datasources/auth_remote_datasource.dart"
  _dart "lib/features/auth/data/models/user_model.dart"
  _dart "lib/features/auth/data/models/login_request_model.dart"
  _dart "lib/features/auth/data/repositories/auth_repository_impl.dart"
  _dart "lib/features/auth/domain/entities/user_entity.dart"
  _dart "lib/features/auth/domain/repositories/auth_repository.dart"
  _dart "lib/features/auth/domain/usecases/login_usecase.dart"
  _dart "lib/features/auth/domain/usecases/register_usecase.dart"
  _dart "lib/features/auth/domain/usecases/logout_usecase.dart"
  _dart "lib/features/auth/domain/usecases/refresh_token_usecase.dart"
  _dart "lib/features/auth/presentation/pages/login_screen.dart"
  _dart "lib/features/auth/presentation/pages/register_screen.dart"
  _dart "lib/features/auth/presentation/pages/forgot_password_screen.dart"
  _dart "lib/features/auth/presentation/widgets/auth_button.dart"
  _dart "lib/features/auth/presentation/widgets/auth_text_field.dart"
  for F in "${SM_FILES[@]}"; do
    _dart "lib/features/auth/presentation/${SM_DIR}/auth_${F}.dart"
  done
  _yes "$F_OAUTH"     && _dart "lib/features/auth/domain/usecases/oauth_login_usecase.dart"
  _yes "$F_BIOMETRIC" && _dart "lib/features/auth/domain/usecases/biometric_auth_usecase.dart"

  _dart "lib/features/profile/data/datasources/profile_remote_datasource.dart"
  _dart "lib/features/profile/data/models/profile_model.dart"
  _dart "lib/features/profile/data/repositories/profile_repository_impl.dart"
  _dart "lib/features/profile/domain/entities/profile_entity.dart"
  _dart "lib/features/profile/domain/repositories/profile_repository.dart"
  _dart "lib/features/profile/domain/usecases/get_profile_usecase.dart"
  _dart "lib/features/profile/domain/usecases/update_profile_usecase.dart"
  _dart "lib/features/profile/presentation/pages/profile_screen.dart"
  _dart "lib/features/profile/presentation/pages/edit_profile_screen.dart"
  _dart "lib/features/profile/presentation/widgets/profile_header.dart"
  for F in "${SM_FILES[@]}"; do
    _dart "lib/features/profile/presentation/${SM_DIR}/profile_${F}.dart"
  done

  _dart "lib/features/settings/presentation/pages/settings_screen.dart"
  _dart "lib/features/settings/presentation/pages/about_app_screen.dart"
  _dart "lib/features/settings/presentation/pages/privacy_policy_screen.dart"
  _dart "lib/features/settings/presentation/pages/terms_of_service_screen.dart"
  _dart "lib/features/settings/presentation/widgets/settings_tile.dart"
  _yes "$F_THEME" && _dart "lib/features/settings/presentation/widgets/theme_switch.dart"
  for F in "${SM_FILES[@]}"; do
    _dart "lib/features/settings/presentation/${SM_DIR}/settings_${F}.dart"
  done

  if _yes "$F_PUSH"; then
    _dart "lib/features/notifications/data/datasources/notification_remote_datasource.dart"
    _dart "lib/features/notifications/data/models/notification_model.dart"
    _dart "lib/features/notifications/data/repositories/notification_repository_impl.dart"
    _dart "lib/features/notifications/domain/entities/notification_entity.dart"
    _dart "lib/features/notifications/domain/repositories/notification_repository.dart"
    _dart "lib/features/notifications/domain/usecases/get_notifications_usecase.dart"
    _dart "lib/features/notifications/domain/usecases/mark_read_usecase.dart"
    _dart "lib/features/notifications/presentation/pages/notifications_screen.dart"
    _dart "lib/features/notifications/presentation/widgets/notification_tile.dart"
    for F in "${SM_FILES[@]}"; do
      _dart "lib/features/notifications/presentation/${SM_DIR}/notification_${F}.dart"
    done
  fi

  if _yes "$F_PAYMENT"; then
    _dart "lib/features/payment/data/datasources/payment_remote_datasource.dart"
    _dart "lib/features/payment/data/models/payment_model.dart"
    _dart "lib/features/payment/data/repositories/payment_repository_impl.dart"
    _dart "lib/features/payment/domain/entities/payment_entity.dart"
    _dart "lib/features/payment/domain/repositories/payment_repository.dart"
    _dart "lib/features/payment/domain/usecases/initiate_payment_usecase.dart"
    _dart "lib/features/payment/domain/usecases/verify_payment_usecase.dart"
    _dart "lib/features/payment/presentation/pages/payment_screen.dart"
    _dart "lib/features/payment/presentation/widgets/payment_card.dart"
    for F in "${SM_FILES[@]}"; do
      _dart "lib/features/payment/presentation/${SM_DIR}/payment_${F}.dart"
    done
  fi

  if _yes "$F_MAPS"; then
    _dart "lib/features/maps/presentation/pages/map_screen.dart"
    _dart "lib/features/maps/presentation/widgets/map_widget.dart"
  fi

  if _yes "$F_CHARTS"; then
    _dart "lib/features/dashboard/presentation/pages/dashboard_screen.dart"
    _dart "lib/features/dashboard/presentation/widgets/chart_widget.dart"
    _dart "lib/features/dashboard/presentation/widgets/stats_card.dart"
  fi

  if _yes "$F_ONBOARDING"; then
    _dart "lib/features/onboarding/presentation/pages/onboarding_screen.dart"
    _dart "lib/features/onboarding/presentation/widgets/onboarding_page.dart"
  fi

  _yes "$F_SPLASH" && _dart "lib/features/splash/presentation/pages/splash_screen.dart"

  _dart "lib/shared/widgets/buttons/primary_button.dart"
  _dart "lib/shared/widgets/buttons/secondary_button.dart"
  _dart "lib/shared/widgets/buttons/icon_text_button.dart"
  _dart "lib/shared/widgets/cards/base_card.dart"
  _dart "lib/shared/widgets/dialogs/loading_dialog.dart"
  _dart "lib/shared/widgets/dialogs/error_dialog.dart"
  _dart "lib/shared/widgets/dialogs/success_dialog.dart"
  _dart "lib/shared/widgets/dialogs/confirm_dialog.dart"
  _dart "lib/shared/widgets/inputs/custom_text_field.dart"
  _dart "lib/shared/widgets/inputs/search_bar.dart"
  _dart "lib/shared/widgets/inputs/dropdown_field.dart"
  _dart "lib/shared/widgets/layouts/custom_app_bar.dart"
  _yes "$F_BOTTOM_NAV" && _dart "lib/shared/widgets/layouts/bottom_nav_bar.dart"
  _yes "$F_DRAWER"     && _dart "lib/shared/widgets/layouts/drawer_menu.dart"
  _dart "lib/shared/widgets/feedback/error_widget.dart"
  _dart "lib/shared/widgets/feedback/loading_widget.dart"
  _dart "lib/shared/widgets/feedback/empty_state_widget.dart"
  _dart "lib/shared/widgets/feedback/snackbar_utils.dart"
  _dart "lib/shared/mixins/validation_mixin.dart"
  _dart "lib/shared/mixins/loading_mixin.dart"

  _dart "lib/routes/app_routes.dart"
  _dart "lib/routes/app_pages.dart"
  if _yes "$F_GOROUTER" || _yes "$F_AUTOROUTE"; then
    _dart "lib/routes/guards/auth_guard.dart"
    _dart "lib/routes/guards/role_guard.dart"
  fi

  _dart "lib/config/app_config.dart"
  _dart "lib/config/environment.dart"
  if _yes "$F_FLAVORS"; then
    _dart "lib/config/flavors/dev_config.dart"
    _dart "lib/config/flavors/staging_config.dart"
    _dart "lib/config/flavors/prod_config.dart"
  fi

  _dart "lib/app.dart"
  _dart "lib/main.dart"
  _yes "$F_FLAVORS" && _dart "lib/main_dev.dart"
  _yes "$F_FLAVORS" && _dart "lib/main_staging.dart"
  _yes "$F_FLAVORS" && _dart "lib/main_prod.dart"

  if _yes "$F_UNIT_TEST"; then
    _dart "test/unit/features/auth/auth_usecase_test.dart"
    for F in "${SM_FILES[@]}"; do
      _dart "test/unit/features/auth/auth_${F}_test.dart"
    done
    _dart "test/unit/features/profile/profile_usecase_test.dart"
    _dart "test/unit/core/validators_test.dart"
    _dart "test/helpers/test_helpers.dart"
    _dart "test/helpers/mock_data.dart"
    touch "${B}/test/fixtures/user_fixture.json"
    touch "${B}/test/fixtures/auth_fixture.json"
  fi

  if _yes "$F_WIDGET_TEST"; then
    _dart "test/widget/features/auth_widget_test.dart"
    _dart "test/widget/shared/shared_widgets_test.dart"
  fi

  if _yes "$F_INTEGRATION_TEST"; then
    _dart "test/integration_test/app_test.dart"
    _dart "test/integration_test/auth_flow_test.dart"
  fi

  # ════════════════════════════════════════════════════════════════
  # ROOT CONFIG FILES
  # ════════════════════════════════════════════════════════════════

  # ── pubspec.yaml ─────────────────────────────────────────────────
  # FIX: Dependencies written from arrays — no stray blank lines from unset variables.
  #      SDK constraint written without embedded literal quotes.
  {
    cat << EOF
name: ${PROJECT_NAME}
description: Flutter app — ${SM_LABEL} | ${API_LABEL} | ${STORAGE_LABEL}
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '${_SDK_CONSTRAINT}'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

EOF
    for line in "${_DEPS_MAIN[@]}"; do printf '%s\n' "$line"; done
    cat << 'EOF'

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/images/icons/
    - assets/images/logo/
    - assets/images/placeholders/
    - assets/fonts/
    - assets/animations/
    - assets/json/
EOF
    [[ -n "$_ASSET_TRANSLATIONS" ]] && printf '%s\n' "$_ASSET_TRANSLATIONS"
    cat << 'EOF'

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
EOF
    for line in "${_DEPS_DEV[@]}"; do printf '%s\n' "$line"; done
  } > "${B}/pubspec.yaml"

  # Guard — if pubspec somehow ended up without name: field, inject it
  if ! grep -q "^name:" "${B}/pubspec.yaml"; then
    sed -i "1s/^/name: ${PROJECT_NAME}\n/" "${B}/pubspec.yaml"
    echo -e "  ${YELLOW}⚠ name: field was missing — auto-injected.${RESET}"
  fi

  # ── analysis_options.yaml ────────────────────────────────────────
  cat > "${B}/analysis_options.yaml" << 'EOF'
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.config.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_single_quotes: true
    always_declare_return_types: true
    avoid_print: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    sort_child_properties_last: true
EOF

  # ── .gitignore ───────────────────────────────────────────────────
  cat > "${B}/.gitignore" << 'EOF'
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
*.g.dart
*.freezed.dart
*.config.dart

# Android
**/android/**/gradle-wrapper.jar
**/android/.gradle
**/android/captures/
**/android/gradlew
**/android/gradlew.bat
**/android/local.properties
**/android/**/GeneratedPluginRegistrant.java
**/android/key.properties
*.jks

# iOS
**/ios/**/*.mode1v3
**/ios/**/*.mode2v3
**/ios/**/*.moved-aside
**/ios/**/*.pbxuser
**/ios/**/*.perspectivev3
**/ios/.generated/
**/ios/Flutter/.last_build_id
**/ios/Flutter/App.framework
**/ios/Flutter/Flutter.framework
**/ios/Flutter/Flutter.podspec
**/ios/Flutter/Generated.xcconfig
**/ios/Flutter/ephemeral/
**/ios/Flutter/app.flx
**/ios/Flutter/app.zip
**/ios/Flutter/flutter_assets/
**/ios/ServiceDefinitions.json
**/ios/Runner/GeneratedPluginRegistrant.*
Podfile.lock

# macOS
**/macos/Flutter/GeneratedPluginRegistrant.swift
**/macos/Flutter/ephemeral/

# Coverage
coverage/
*.lcov

# Env
.env
*.env

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.iml
EOF

  # ── .env.example ─────────────────────────────────────────────────
  {
    cat << EOF
# ─── App ──────────────────────────────────────────
APP_NAME=${PROJECT_NAME}
APP_ENV=development
BASE_URL=https://api.example.com/v1

# ─── Firebase ─────────────────────────────────────
FIREBASE_PROJECT_ID=
FIREBASE_API_KEY=
EOF
    if [[ -n "$_ENV_MAPS" ]]; then
      printf '\n# ─── Maps ─────────────────────────────────────────\n'
      printf '%s\n' "$_ENV_MAPS"
    fi
    if [[ -n "$_ENV_PAYMENT" ]]; then
      printf '\n# ─── Payment ──────────────────────────────────────\n'
      printf '%s\n' "$_ENV_PAYMENT"
    fi
    if [[ -n "$_ENV_SENTRY" ]]; then
      printf '\n# ─── Sentry ───────────────────────────────────────\n'
      printf '%s\n' "$_ENV_SENTRY"
    fi
  } > "${B}/.env.example"
  cp "${B}/.env.example" "${B}/.env"

  # ── Makefile ─────────────────────────────────────────────────────
  cat > "${B}/Makefile" << 'MAKEOF'
.PHONY: help run build build-ios test test-coverage clean gen gen-watch setup-local

help:
	@echo "Available commands:"
	@echo "  make run              - Run debug build"
	@echo "  make build            - Build release APK"
	@echo "  make build-ios        - Build iOS release"
	@echo "  make test             - Run all tests"
	@echo "  make test-coverage    - Run tests with coverage"
	@echo "  make clean            - Clean build cache"
	@echo "  make gen              - Run build_runner"
	@echo "  make gen-watch        - Watch mode code generation"
	@echo "  make setup-local      - Generate android/local.properties from env"

setup-local:
	@if [ -z "$$ANDROID_HOME" ]; then \
		echo "⚠  ANDROID_HOME is not set. Set it first:"; \
		echo "   export ANDROID_HOME=/home/rohit/Android/Sdk"; \
		exit 1; \
	fi
	@if [ -z "$$FLUTTER_ROOT" ]; then \
		echo "⚠  FLUTTER_ROOT is not set. Set it first:"; \
		echo "   export FLUTTER_ROOT=/home/rohit/flutter"; \
		exit 1; \
	fi
	@echo "sdk.dir=$$ANDROID_HOME"            > android/local.properties
	@echo "flutter.sdk=$$FLUTTER_ROOT"       >> android/local.properties
	@echo "flutter.buildMode=debug"          >> android/local.properties
	@echo "flutter.versionName=1.0.0"        >> android/local.properties
	@echo "flutter.versionCode=1"            >> android/local.properties
	@echo "✓ android/local.properties generated"

run:
	flutter run

build:
	flutter build apk --release

build-ios:
	flutter build ios --release

test:
	flutter test

test-coverage:
	flutter test --coverage

clean:
	flutter clean
	flutter pub get

gen:
	flutter pub run build_runner build --delete-conflicting-outputs

gen-watch:
	flutter pub run build_runner watch --delete-conflicting-outputs
MAKEOF

  # Append flavor targets if enabled
  if _yes "$F_FLAVORS"; then
    cat >> "${B}/Makefile" << 'EOF'

run-dev:
	flutter run --flavor dev --target lib/main_dev.dart

run-staging:
	flutter run --flavor staging --target lib/main_staging.dart

run-prod:
	flutter run --flavor prod --target lib/main_prod.dart

build-dev:
	flutter build apk --flavor dev --target lib/main_dev.dart

build-prod:
	flutter build apk --flavor prod --target lib/main_prod.dart --release
EOF
  fi

  # ── GitHub Actions CI/CD ─────────────────────────────────────────
  if _yes "$F_CICD"; then
    cat > "${B}/.github/workflows/ci.yml" << EOF
name: Flutter CI

on:
  push:
    branches: [master, develop]
  pull_request:
    branches: [master, develop]

jobs:
  test:
    name: Analyze & Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '${_FLUTTER_VERSION}'
          channel: 'stable'
          cache: true
      - name: Install dependencies
        run: flutter pub get
      - name: Run code generation
        run: flutter pub run build_runner build --delete-conflicting-outputs
        continue-on-error: true
      - name: Analyze
        run: flutter analyze
      - name: Run tests
        run: flutter test --coverage
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  build-android:
    name: Build Android
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '${_FLUTTER_VERSION}'
          channel: 'stable'
          cache: true
      - name: Install dependencies
        run: flutter pub get
      - name: Build APK
        run: flutter build apk --debug
EOF

    cat > "${B}/.github/workflows/android-release.yml" << EOF
name: Android Release Build

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  build-android:
    name: Build & Release Android APK
    runs-on: ubuntu-latest
    if: github.ref_type == 'tag'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          ref: master

      - name: Extract version from tag
        id: version
        run: |
          TAG=\${GITHUB_REF#refs/tags/}
          VERSION=\${TAG#v}
          BUILD_NUMBER=\$(date +%s)
          echo "tag=\$TAG"                                    >> \$GITHUB_OUTPUT
          echo "version=\$VERSION"                           >> \$GITHUB_OUTPUT
          echo "build_number=\$BUILD_NUMBER"                 >> \$GITHUB_OUTPUT
          echo "apk_name=${PROJECT_NAME}-v\${VERSION}.apk"  >> \$GITHUB_OUTPUT

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '${_FLUTTER_VERSION}'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Build Release APK
        run: |
          flutter build apk --release \\
            --build-name=\${{ steps.version.outputs.version }} \\
            --build-number=\${{ steps.version.outputs.build_number }}

      - name: Rename APK
        run: |
          mv build/app/outputs/flutter-apk/app-release.apk \\
             build/app/outputs/flutter-apk/\${{ steps.version.outputs.apk_name }}

      - name: Upload APK to GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: \${{ steps.version.outputs.tag }}
          name: Release \${{ steps.version.outputs.tag }}
          files: build/app/outputs/flutter-apk/\${{ steps.version.outputs.apk_name }}
          generate_release_notes: true
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
EOF

    cat > "${B}/.github/workflows/cd.yml" << EOF
name: Flutter CD

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  build-and-release:
    name: Build & Release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '${_FLUTTER_VERSION}'
          channel: 'stable'
          cache: true
      - name: Install dependencies
        run: flutter pub get
      - name: Build APK Release
        run: flutter build apk --release
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: build/app/outputs/flutter-apk/app-release.apk
          generate_release_notes: true
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
EOF
  fi

  # ── GitHub Issue Templates ────────────────────────────────────────
  if _yes "$F_ISSUES"; then
    cat > "${B}/.github/ISSUE_TEMPLATE/bug_report.yml" << 'EOF'
name: 🐛 Bug Report
description: Report a bug or crash
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
  - type: input
    id: flutter-version
    attributes:
      label: Flutter version
      placeholder: "flutter --version"
  - type: dropdown
    id: platform
    attributes:
      label: Platform
      options: [Android, iOS, Web, macOS, Windows, Linux]
    validations:
      required: true
  - type: dropdown
    id: severity
    attributes:
      label: Severity
      options:
        - Critical (crash / data loss)
        - High (major feature broken)
        - Medium (partial breakage)
        - Low (cosmetic)
    validations:
      required: true
EOF

    cat > "${B}/.github/ISSUE_TEMPLATE/feature_request.yml" << 'EOF'
name: 🚀 Feature Request
description: Suggest a new feature
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
    id: mockups
    attributes:
      label: Mockups / screenshots
EOF

    cat > "${B}/.github/ISSUE_TEMPLATE/config.yml" << 'EOF'
blank_issues_enabled: false
EOF
  fi

  # ── PR Template ──────────────────────────────────────────────────
  if _yes "$F_PR"; then
    cat > "${B}/.github/PULL_REQUEST_TEMPLATE.md" << 'EOF'
## 📋 Description

<!-- What does this PR do? Closes #? -->

## 🔄 Type of Change

- [ ] 🐛 Bug fix
- [ ] 🚀 New feature
- [ ] 💥 Breaking change
- [ ] 🎨 UI / UX improvement
- [ ] ♻️  Refactor
- [ ] 📝 Documentation
- [ ] 🧪 Tests only

## 🧪 Testing

- [ ] Unit tests added / updated
- [ ] Widget tests added / updated
- [ ] Tested on Android
- [ ] Tested on iOS
- [ ] All tests pass (`flutter test`)

## ✅ Checklist

- [ ] `flutter analyze` passes
- [ ] No debug `print()` statements left
- [ ] `.env.example` updated if new env vars added
- [ ] CHANGELOG updated

## 📸 Screenshots

| Before | After |
|--------|-------|
|        |       |

## 🔗 Related Issues / PRs
EOF
  fi

  # ── CODEOWNERS ───────────────────────────────────────────────────
  if _yes "$F_CODEOWNERS"; then
    cat > "${B}/.github/CODEOWNERS" << 'EOF'
# Global
* @your-username

# Core
lib/core/ @your-username
lib/features/auth/ @your-username
EOF
  fi

  # ── CHANGELOG ────────────────────────────────────────────────────
  if _yes "$F_CHANGELOG"; then
    cat > "${B}/CHANGELOG.md" << EOF
# Changelog

All notable changes to **${PROJECT_NAME}** will be documented here.

## [Unreleased]

## [1.0.0] - $(date +%Y-%m-%d)
### Added
- Initial Flutter clean architecture scaffold
- ${SM_LABEL} state management
- ${API_LABEL} integration
- ${STORAGE_LABEL} local storage
EOF
  fi

  # ── dependabot.yml ───────────────────────────────────────────────
  cat > "${B}/.github/dependabot.yml" << 'EOF'
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
EOF

  # ── TRADEMARKS.md ────────────────────────────────────────────────
  cat > "${B}/TRADEMARKS.md" << EOF
# Trademarks and Branding

${PROJECT_NAME} is open source, but open source code does not automatically grant branding rights.

## What the MIT License Covers

The [MIT License](LICENSE) applies to the source code and repository documentation unless a file says otherwise.

## What Is Reserved

The following are reserved and are not granted for general reuse by the MIT License:

- The \`${PROJECT_NAME}\` project name when used to imply official status
- The ${PROJECT_NAME} logo, app icon, and branded visual identity
- Any presentation that suggests endorsement by the original maintainers

## What You May Do

- Fork the repository
- Modify the code
- Share your changes under the MIT License terms
- Credit ${PROJECT_NAME} as the upstream project

## What You May Not Do

- Ship a modified build as if it were the official ${PROJECT_NAME} project
- Reuse the official name, icon, or branding in a way that confuses users
- Remove required copyright or license notices

If you want to use the official branding for a special case, request permission from "rohitbhure.cse@gmail.com".
EOF

  # ── SECURITY.md ──────────────────────────────────────────────────
  cat > "${B}/SECURITY.md" << 'EOF'
# Security Policy

## Supported Versions

Security fixes are prioritized for:

- The latest code on "master"
- The most recent public release, if one exists

## Reporting a Vulnerability

Please report security issues privately by email to "rohitbhure.cse@gmail.com".

When possible, include:

- A clear description of the issue
- Steps to reproduce it
- The affected version, branch, or commit
- Any proof-of-concept details needed to verify the report safely

## Please Do Not

- Do not open a public GitHub issue for a security vulnerability
- Do not include secrets, private tokens, or personal data in reports

## Response Expectations

We will review reports, validate impact, and work toward a fix as quickly as time permits.
EOF

  cat > "${B}/NOTICE.md" << EOF
${PROJECT_NAME}
Copyright (c) $(date +%Y) Rohit Bhure

This repository's source code and documentation are licensed under the MIT License unless otherwise noted.

The ${PROJECT_NAME} name, logo, app icon, and branding are reserved and may not be used to imply endorsement or official project status for modified forks or redistributions.

See LICENSE and TRADEMARKS.md for details.
EOF

  # ── LICENSE.md ───────────────────────────────────────────────────
  cat > "${B}/LICENSE.md" << EOF
MIT License

Copyright (c) $(date +%Y) Rohit Bhure

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

  # ── CONTRIBUTING.md ──────────────────────────────────────────────
  cat > "${B}/CONTRIBUTING.md" << EOF
# Contributing to ${PROJECT_NAME}

Thank you for helping improve ${PROJECT_NAME}.

## Ways to Contribute

- Report bugs with clear reproduction steps
- Propose focused feature requests
- Improve docs, onboarding, and developer setup
- Submit code changes with tests or manual verification notes
- Help review UX, accessibility, and performance issues

## Before You Start

- Check existing issues and pull requests before opening a new one
- Use the GitHub issue templates so reports stay actionable
- For larger changes, open an issue first to align on scope

## Development Setup

\`\`\`bash
flutter pub get
flutter run
\`\`\`

## Pull Request Guidelines

- Keep pull requests focused and easy to review
- Update documentation when behavior or setup changes
- Add tests when practical, or explain the manual verification you performed
- Avoid unrelated formatting-only churn
- Never commit secrets, keystores, or production-only credentials

## Coding Expectations

- Follow the existing Flutter and Dart style already used in the repo
- Prefer small, readable changes over broad rewrites
- Preserve existing license and attribution notices

## Contribution Licensing

By submitting a contribution, you agree that your work will be licensed under the repository's MIT License.

## Attribution and Branding

You are welcome to fork and extend the codebase, but please do not present a modified version as the official ${PROJECT_NAME} project. Use distinct branding for redistributed forks and preserve upstream attribution.

See [TRADEMARKS.md](TRADEMARKS.md) for branding rules.
EOF

  # ── CODE_OF_CONDUCT.md ───────────────────────────────────────────
  cat > "${B}/CODE_OF_CONDUCT.md" << EOF
# Code of Conduct

## Our Commitment

${PROJECT_NAME} is committed to a welcoming, respectful, and constructive community.

## Expected Behavior

- Be respectful and professional
- Assume good intent, and discuss ideas without attacking people
- Offer constructive feedback with enough context to be useful
- Welcome questions from new contributors
- Respect project boundaries, maintainers' time, and community decisions

## Unacceptable Behavior

- Harassment, discrimination, or hateful conduct
- Personal attacks, insults, or intimidation
- Deliberate disruption, trolling, or bad-faith engagement
- Sharing private information without permission
- Misrepresenting your work, identity, or affiliation with the project

## Reporting

Report unacceptable behavior privately to "rohitbhure.cse@gmail.com".

## Enforcement

Project maintainers may remove comments, reject contributions, restrict participation, or take other appropriate action in response to behavior that violates this Code of Conduct.
EOF

  # ── README.md ────────────────────────────────────────────────────
  # FIX: Table built with printf to produce real newlines (not \n literals)
  _readme_dep_table() {
    printf '| Package | Purpose |\n'
    printf '|---------|----------|\n'
    case "$SM_CHOICE" in
      1) printf '| `flutter_bloc` | State management (BLoC) |\n'
         printf '| `equatable` | Value equality |\n' ;;
      2) printf '| `flutter_riverpod` | State management (Riverpod) |\n' ;;
      3) printf '| `get` | State management, routing & DI (GetX) |\n' ;;
      4) printf '| `provider` | State management (Provider) |\n' ;;
    esac
    if [[ "$API_CHOICE" == "1" || "$API_CHOICE" == "5" ]]; then
      printf '| `dio` | HTTP client |\n'
      printf '| `retrofit` | REST API code generation |\n'
    fi
    [[ "$API_CHOICE" == "2" ]] && printf '| `http` | HTTP client (lightweight) |\n'
    [[ "$API_CHOICE" == "4" ]] && printf '| `graphql_flutter` | GraphQL API client |\n'
    case "$STORAGE_CHOICE" in
      1) printf '| `hive` | Fast NoSQL local storage |\n' ;;
      2) printf '| `shared_preferences` | Simple key-value storage |\n' ;;
      3) printf '| `sqflite` | SQLite relational database |\n' ;;
      4) printf '| `isar` | Fast type-safe local database |\n' ;;
    esac
    _yes "$F_FIREBASE_AUTH" && printf '| `firebase_auth` | Firebase Authentication |\n'
    _yes "$F_FIRESTORE"     && printf '| `cloud_firestore` | Firestore database |\n'
    _yes "$F_PUSH"          && printf '| `firebase_messaging` | Push notifications (FCM) |\n'
    _yes "$F_ANALYTICS"     && printf '| `firebase_analytics` | Analytics |\n'
    _yes "$F_CRASHLYTICS"   && printf '| `firebase_crashlytics` | Crash reporting |\n'
    _yes "$F_OAUTH"         && printf '| `google_sign_in` | Google Sign-In |\n'
    _yes "$F_GOROUTER"      && printf '| `go_router` | Declarative navigation |\n'
    _yes "$F_AUTOROUTE"     && printf '| `auto_route` | Code-gen routing |\n'
    if _yes "$F_DI"; then
      printf '| `get_it` | Service locator (DI) |\n'
      printf '| `injectable` | DI code generation |\n'
    fi
    _yes "$F_IMAGE_PICKER" && printf '| `image_picker` | Camera & gallery picker |\n'
    _yes "$F_LOCATION"     && printf '| `geolocator` | GPS location |\n'
    _yes "$F_MAPS"         && printf '| `google_maps_flutter` | Maps integration |\n'
    _yes "$F_PAYMENT"      && printf '| `razorpay_flutter` | Payment gateway |\n'
    _yes "$F_CHARTS"       && printf '| `fl_chart` | Charts & graphs |\n'
    _yes "$F_LOGGING"      && printf '| `logger` | Structured logging |\n'
    _yes "$F_SENTRY"       && printf '| `sentry_flutter` | Error & crash tracking |\n'
    _yes "$F_SPLASH"       && printf '| `flutter_native_splash` | Native splash screen |\n'
    _yes "$F_L10N"         && printf '| `easy_localization` | Internationalization |\n'
    printf '| `dartz` | Functional programming (Either) |\n'
    printf '| `flutter_secure_storage` | Encrypted key-value storage |\n'
    printf '| `cached_network_image` | Cached network images |\n'
    printf '| `flutter_screenutil` | Responsive screen utilities |\n'
  }

  {
    cat << EOF
# ${PROJECT_NAME}

> Flutter App — **${SM_LABEL}** | **${API_LABEL}** | **${STORAGE_LABEL}**

[![Flutter](https://img.shields.io/badge/Flutter-${_FLUTTER_VERSION}-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE.md)

---

## 🚀 Quick Start

\`\`\`bash
git clone <repo-url>
cd ${PROJECT_NAME}
cp .env.example .env
export ANDROID_HOME=/home/rohit/Android/Sdk
export FLUTTER_ROOT=/home/rohit/flutter
make setup-local
flutter pub get
flutter run
\`\`\`

---

## 🏗️ Architecture

Built on **Clean Architecture** principles with **${SM_LABEL}** state management.
See [ARCHITECTURE.md](ARCHITECTURE.md) for a full technical breakdown.

\`\`\`
lib/
├── core/           # constants, errors, network, cache, services, theme, utils, di
├── features/       # ${_README_FEATURES}
│   └── <feature>/
│       ├── data/           # datasources · models · repository_impl
│       ├── domain/         # entities · repository interfaces · usecases
│       └── presentation/   # ${SM_DIR}/ · pages/ · widgets/
├── shared/         # reusable widgets, mixins
├── routes/         # ${_README_ROUTES}
├── config/         # ${_README_CONFIG}
├── app.dart
└── main.dart
${_README_MAIN}
\`\`\`

**Data flow:** User Interaction → ${SM_LABEL} → UseCase → Repository → DataSource → API/DB

---

## 📦 Key Dependencies

EOF
    _readme_dep_table
    cat << EOF

---

## 🛠️ Commands

| Command | Description |
|---|---|
| \`make setup-local\` | Generate \`android/local.properties\` from env vars |
| \`make run\` | Run debug build |
| \`make build\` | Build release APK |
| \`make build-ios\` | Build iOS release |
| \`make test\` | Run all tests |
| \`make test-coverage\` | Run tests with coverage report |
| \`make clean\` | Clean build cache + pub get |
| \`make gen\` | Run build_runner (code generation) |
| \`make gen-watch\` | Watch mode for code generation |
${_README_MK_DEV}
${_README_MK_PROD}

---

## 🧪 Testing

\`\`\`bash
flutter test                  # all tests
flutter test --coverage       # with coverage
\`\`\`

---

## 🔒 Security

- Secrets are stored in \`.env\` (not committed — see \`.gitignore\`)
- Use \`flutter_secure_storage\` for sensitive on-device data
- Firebase keys loaded via environment variables

---

## 📄 License

MIT — see [LICENSE.md](LICENSE.md)

> Branding rights are reserved — see [TRADEMARKS.md](TRADEMARKS.md)
EOF
  } > "${B}/README.md"

  # ── ARCHITECTURE.md ──────────────────────────────────────────────
  # FIX: Multi-line sections built with printf so newlines are real, not \n literals.
  _ARCH_DI_LABEL=""
  case "$SM_CHOICE" in
    1) _ARCH_DI_LABEL="BLoC + Cubit via flutter_bloc" ;;
    2) _ARCH_DI_LABEL="Riverpod providers (compile-time safe)" ;;
    3) _ARCH_DI_LABEL="GetX — built-in DI with Get.put / Get.find" ;;
    4) _ARCH_DI_LABEL="Provider — ChangeNotifier / InheritedWidget" ;;
  esac
  _yes "$F_DI" && _ARCH_DI_LABEL="${_ARCH_DI_LABEL} + get_it / injectable"

  _ARCH_ERR="Services return \`Either<Failure, T>\` (dartz) so callers handle errors explicitly."
  _yes "$F_SENTRY"      && _ARCH_ERR="${_ARCH_ERR} Sentry captures unhandled exceptions automatically."
  _yes "$F_CRASHLYTICS" && _ARCH_ERR="${_ARCH_ERR} Firebase Crashlytics records fatal crashes."

  _ARCH_TEST=""
  _yes "$F_UNIT_TEST"        && _ARCH_TEST="${_ARCH_TEST}- **Unit tests**: \`test/unit/\` — mockito mocks, business logic
"
  _yes "$F_WIDGET_TEST"      && _ARCH_TEST="${_ARCH_TEST}- **Widget tests**: \`test/widget/\` — UI component rendering
"
  _yes "$F_INTEGRATION_TEST" && _ARCH_TEST="${_ARCH_TEST}- **Integration tests**: \`test/integration_test/\` — full E2E flows
"
  [[ -z "$_ARCH_TEST" ]] && _ARCH_TEST="_(No test targets were enabled during scaffold. Add them manually under \`test/\`.)_"

  {
    cat << EOF
# ${PROJECT_NAME} — Architecture

This document describes the architecture and design decisions for **${PROJECT_NAME}**,
a Flutter application built with **Clean Architecture** and **${SM_LABEL}** state management.

---

## Overview

${PROJECT_NAME} follows Clean Architecture principles with a feature-based folder organization.
Concerns are separated into three layers — **domain**, **data**, and **presentation** — so
business logic stays independent of UI and infrastructure details.

---

## 📁 Project Structure

\`\`\`
lib/
├── core/                        # Cross-cutting concerns
│   ├── constants/               # App colors, strings, dimensions, enums
│   ├── errors/                  # Exception & Failure types
│   ├── network/                 # API client, interceptors, connectivity
│   ├── cache/                   # Cache manager, keys, policy
│   ├── services/                # Navigation, storage, notifications …
│   ├── theme/                   # Material ThemeData (light/dark)
│   ├── utils/                   # Extensions, formatters, validators, helpers
│   ├── di/                      # Dependency injection setup
│   └── resources/               # Color, font, image, value managers
│
├── features/                    # Feature modules (${_README_FEATURES})
│   └── <feature_name>/
│       ├── data/
│       │   ├── datasources/     # Remote & local data sources
│       │   ├── models/          # DTO / JSON models (extend entities)
│       │   └── repositories/    # Repository implementations
│       ├── domain/
│       │   ├── entities/        # Pure business objects
│       │   ├── repositories/    # Repository abstractions (interfaces)
│       │   └── usecases/        # Single-responsibility use-case classes
│       └── presentation/
│           ├── ${SM_DIR}/       # ${SM_LABEL} state management files
│           ├── pages/           # Screen widgets
│           └── widgets/         # Feature-scoped UI components
│
├── shared/                      # Shared across features
│   ├── widgets/
│   │   ├── buttons/
│   │   ├── cards/
│   │   ├── dialogs/
│   │   ├── inputs/
│   │   ├── layouts/
│   │   └── feedback/
│   └── mixins/                  # ValidationMixin, LoadingMixin …
│
├── routes/                      # Route names, page map, guards
├── config/                      # AppConfig, Environment
├── app.dart                     # Root MaterialApp / GetMaterialApp
└── main.dart                    # App entry point
${_README_MAIN}
\`\`\`

---

## 🔵 Layer Descriptions

### Core Layer (\`lib/core/\`)

Contains fundamental code used throughout the entire app:

| Sub-folder | Responsibility |
|---|---|
| \`constants/\` | App-wide colors, strings, dimensions, enums |
| \`errors/\` | \`AppException\` hierarchy + \`Failure\` sealed classes |
| \`network/\` | HTTP client (${API_LABEL}), auth/logging interceptors, connectivity |
| \`cache/\` | Abstract cache manager, TTL policy, cache keys |
| \`services/\` | NavigationService, StorageService, and feature services |
| \`theme/\` | Light & dark \`ThemeData\` |
| \`utils/\` | Extensions (String, DateTime, List, BuildContext), formatters, validators |
| \`di/\` | Service-locator bootstrap (injection_container.dart) |
| \`resources/\` | Typed managers for colors, fonts, images, spacing values |

### Features Layer (\`lib/features/\`)

Each feature is **self-contained** and follows the Clean Architecture triangle:

\`\`\`
Presentation  →  Domain  ←  Data
\`\`\`

- **Domain** has zero Flutter/external-library imports — pure Dart.
- **Data** implements domain repository interfaces and talks to APIs/DBs.
- **Presentation** depends on domain (use cases) and renders UI via ${SM_LABEL}.

### Shared Layer (\`lib/shared/\`)

Generic UI building blocks and mixins reused across features.
No business logic lives here — only presentation helpers.

---

## ⚡ Technology Stack

| Category | Choice |
|---|---|
| Framework | Flutter ${_FLUTTER_VERSION} |
| Language | Dart (SDK ${_SDK_CONSTRAINT}) |
| State Management | ${SM_LABEL} |
| API / Backend | ${API_LABEL} |
| Local Storage | ${STORAGE_LABEL} |
| Dependency Injection | ${_ARCH_DI_LABEL} |

---

## 🔄 Data Flow

\`\`\`
User Interaction
      │
      ▼
  UI Widget  (\`presentation/pages/\`)
      │
      ▼
  ${SM_LABEL}  (\`presentation/${SM_DIR}/\`)
      │
      ▼
  UseCase  (\`domain/usecases/\`)
      │
      ▼
  Repository Interface  (\`domain/repositories/\`)
      │
      ▼
  Repository Impl  (\`data/repositories/\`)  ←──►  Remote DataSource
                                                ←──►  Local DataSource
\`\`\`

---

## 🧩 Architecture Patterns

### Use-Case Pattern (Domain)

\`\`\`dart
class LoginUsecase {
  final AuthRepository _repository;
  const LoginUsecase(this._repository);

  Future<Either<Failure, UserEntity>> call(LoginParams params) =>
      _repository.login(params.email, params.password);
}
\`\`\`

### Repository Pattern (Data)

\`\`\`dart
abstract interface class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final AuthLocalDatasource  _local;
  // ...
}
\`\`\`

### ${SM_LABEL} State Pattern (Presentation)

\`\`\`dart
EOF

    case "$SM_CHOICE" in
      1) cat << 'EOF'
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUsecase _loginUsecase;
  AuthBloc(this._loginUsecase) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }
  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _loginUsecase(LoginParams(email: event.email, password: event.password));
    result.fold((f) => emit(AuthError(f.message)), (user) => emit(AuthSuccess(user)));
  }
}
EOF
         ;;
      2) cat << 'EOF'
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<UserEntity?> build() => const AsyncValue.data(null);

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await ref.read(loginUsecaseProvider)(
        LoginParams(email: email, password: password));
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      AsyncValue.data,
    );
  }
}
EOF
         ;;
      3) cat << 'EOF'
class AuthController extends GetxController {
  final LoginUsecase _loginUsecase;
  AuthController(this._loginUsecase);

  final RxBool isLoading = false.obs;
  final Rx<UserEntity?> user = Rx<UserEntity?>(null);

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    final result = await _loginUsecase(LoginParams(email: email, password: password));
    result.fold(
      (failure) => Get.snackbar('Error', failure.message),
      (u) { user.value = u; Get.offAllNamed('/home'); },
    );
    isLoading.value = false;
  }
}
EOF
         ;;
      4) cat << 'EOF'
class AuthProvider extends ChangeNotifier {
  final LoginUsecase _loginUsecase;
  AuthProvider(this._loginUsecase);

  bool isLoading = false;
  UserEntity? user;

  Future<void> login(String email, String password) async {
    isLoading = true; notifyListeners();
    final result = await _loginUsecase(LoginParams(email: email, password: password));
    result.fold((failure) => null, (u) => user = u);
    isLoading = false; notifyListeners();
  }
}
EOF
         ;;
    esac

    cat << EOF
\`\`\`

---

## 💉 Dependency Injection

${_ARCH_DI_LABEL}

\`\`\`dart
Future<void> setupDI() async {
  sl.registerLazySingleton(() => StorageService());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton(() => LoginUsecase(sl()));
}
\`\`\`

---

## 🧭 Navigation

EOF

    if _yes "$F_GOROUTER"; then
      cat << 'EOF'
Navigation uses **GoRouter** (declarative, deep-link friendly):

```dart
final router = GoRouter(routes: [
  GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
]);

context.go('/home');
```
EOF
    elif _yes "$F_AUTOROUTE"; then
      cat << 'EOF'
Navigation uses **AutoRoute** (code-generation powered):

```dart
@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [AutoRoute(page: HomeRoute.page, initial: true)];
}

context.router.push(const HomeRoute());
```
EOF
    else
      cat << 'EOF'
Navigation uses named routes registered in `lib/routes/app_pages.dart`:

```dart
Navigator.pushNamed(context, AppRoutes.home);
Navigator.pushNamed(context, AppRoutes.profile, arguments: userId);
```
EOF
    fi

    cat << EOF

---

## 🛡️ Error Handling

${_ARCH_ERR}

\`\`\`dart
Future<Either<Failure, UserEntity>> login(String email, String password) async {
  try {
    final user = await _remote.login(email, password);
    return Right(user.toEntity());
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  }
}
\`\`\`

---

## 🧪 Testing

${_ARCH_TEST}
\`\`\`bash
flutter test                        # run all tests
flutter test --coverage             # with coverage report
flutter test test/unit/             # unit tests only
flutter test test/widget/           # widget tests only
\`\`\`

---

## ⚡ Performance Considerations

1. **Lazy singletons** — services registered as \`registerLazySingleton\` to avoid eager init
2. **Image caching** — \`cached_network_image\` for remote assets
3. **Const widgets** — \`const\` constructors used everywhere possible
4. **Dispose** — controllers properly disposed; no memory leaks
EOF

    if _yes "$F_CICD"; then
      cat << 'EOF'

---

## ⚙️ CI / CD

GitHub Actions workflows are in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | push / PR to master·develop | Analyze, test, build debug APK |
| `android-release.yml` | push tag `v*.*.*` | Build & upload signed release APK |
| `cd.yml` | push tag `v*.*.*` | GitHub Release with APK asset |
EOF
    fi

    if _yes "$F_FLAVORS"; then
      cat << 'EOF'

---

## 🎨 Flavors

| Flavor | Entry point | Command |
|---|---|---|
| dev | `lib/main_dev.dart` | `make run-dev` |
| staging | `lib/main_staging.dart` | `make run-staging` |
| prod | `lib/main_prod.dart` | `make run-prod` |

Flavor config lives in `lib/config/flavors/`.
EOF
    fi

    cat << 'EOF'

---

## 🔒 Security

- No secrets committed — `.env` is in `.gitignore`
- Sensitive data stored via `flutter_secure_storage` (AES / Keychain)
- Firebase keys loaded from environment; `google-services.json` excluded from VCS
- `android/key.properties` and `*.jks` excluded from VCS

---

## 🚧 Future Improvements

- Complete feature module separation where still partial
- Increase unit-test coverage to ≥ 80%
- Add golden / screenshot tests for critical widgets
- Integrate automated release via Fastlane or Codemagic
EOF
  } > "${B}/ARCHITECTURE.md"

  # ── ABOUT.md ──────────────────────────────────────────────────────
  cat > "${B}/ABOUT.md" << EOF
# About ${PROJECT_NAME}

**Last Updated:** $(date +"%B %d, %Y")

${PROJECT_NAME} is an open-source Flutter application built with **Clean Architecture**
and **${SM_LABEL}** state management. The project is designed to be maintainable,
testable, and easy to extend.

## Stack at a Glance

| Category       | Choice              |
|----------------|---------------------|
| Framework      | Flutter ${_FLUTTER_VERSION}     |
| State Mgmt     | ${SM_LABEL}         |
| API / Backend  | ${API_LABEL}        |
| Local Storage  | ${STORAGE_LABEL}    |
| App ID         | ${APP_ID}           |

## What ${PROJECT_NAME} Offers

$(
  echo "- Clean Architecture scaffold (data / domain / presentation)"
  _yes "$F_JWT"           && echo "- JWT authentication (login / register / refresh)"
  _yes "$F_OAUTH"         && echo "- OAuth — Google / Apple Sign-In"
  _yes "$F_BIOMETRIC"     && echo "- Biometric authentication (fingerprint / face ID)"
  _yes "$F_FIREBASE_AUTH" && echo "- Firebase Authentication"
  _yes "$F_FIRESTORE"     && echo "- Cloud Firestore integration"
  _yes "$F_PUSH"          && echo "- Push notifications via FCM"
  _yes "$F_LOCAL_NOTIF"   && echo "- Local notifications"
  _yes "$F_THEME"         && echo "- Dark / Light theme support"
  _yes "$F_L10N"          && echo "- Multi-language support (internationalization)"
  _yes "$F_SPLASH"        && echo "- Native splash screen"
  _yes "$F_ONBOARDING"    && echo "- Onboarding screens"
  _yes "$F_IMAGE_PICKER"  && echo "- Image picker (camera + gallery)"
  _yes "$F_FILE_PICKER"   && echo "- File picker"
  _yes "$F_PDF"           && echo "- PDF viewer"
  _yes "$F_PDF_GEN"       && echo "- PDF generation"
  _yes "$F_QR"            && echo "- QR / Barcode scanner"
  _yes "$F_QR_GEN"        && echo "- QR code generator"
  _yes "$F_LOCATION"      && echo "- Location services (GPS)"
  _yes "$F_MAPS"          && echo "- Google Maps integration"
  _yes "$F_PAYMENT"       && echo "- Payment gateway integration"
  _yes "$F_IAP"           && echo "- In-App Purchases"
  _yes "$F_CHARTS"        && echo "- Charts and data visualisation"
  _yes "$F_BLUETOOTH"     && echo "- Bluetooth (flutter_blue_plus)"
  _yes "$F_DEEPLINK"      && echo "- Deep links / App links"
  _yes "$F_CONNECTIVITY"  && echo "- Connectivity monitoring"
  _yes "$F_FLAVORS"       && echo "- Multi-flavor builds (dev / staging / prod)"
  _yes "$F_CICD"          && echo "- GitHub Actions CI/CD pipeline"
)

## Open Source

${PROJECT_NAME} welcomes community contributions. If you want to fix bugs, improve
performance, expand tooling, or polish the user experience, pull requests and
well-scoped issues are encouraged.

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.
See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community expectations.

## Attribution and Branding

The source code is released under the MIT License, but the **${PROJECT_NAME}** name,
logo, icon, and branding are reserved. Forks and modified redistributions should
use distinct branding and should not present themselves as the official project.

See [LICENSE.md](LICENSE.md) and [TRADEMARKS.md](TRADEMARKS.md) for details.

## Contact

Questions, feedback, and collaboration inquiries can be sent to \`rohitbhure.cse@gmail.com\`.
EOF

  # ════════════════════════════════════════════════════════════════
  # ANDROID FILES
  # ════════════════════════════════════════════════════════════════

  # ── android/build.gradle.kts ─────────────────────────────────────
  # FIX: Firebase Crashlytics plugin NOT applied at root level unconditionally.
  #      It is applied conditionally inside app/build.gradle.kts only when
  #      google-services.json is present. The root file is now plugin-free.
  cat > "${B}/android/build.gradle.kts" << 'EOF'
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects { project.evaluationDependsOn(":app") }

tasks.register<Delete>("cleanBuild") { delete(rootProject.layout.buildDirectory) }
EOF

  # ── android/settings.gradle.kts ──────────────────────────────────
  # FIX: Plugin versions corrected to real stable releases (Kotlin 2.0.21, AGP 8.5.2).
  #      These are the latest stable as of late 2024 / early 2025.
  cat > "${B}/android/settings.gradle.kts" << 'EOF'
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
}

include(":app")
EOF

  # ── android/app/build.gradle.kts ─────────────────────────────────
  cat > "${B}/android/app/build.gradle.kts" << EOF
import java.util.Properties

// ─── Application identity ────────────────────────────────────────
val appId = "${APP_ID}"

// ─── Firebase BOM version — update here only ─────────────────────
val firebaseBomVersion = "${_FIREBASE_BOM_VERSION}"

// ─── Signing ─────────────────────────────────────────────────────
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val releaseKeystoreFile = project.file("upload-keystore.jks")
val hasReleaseSigning = keystorePropertiesFile.exists() && releaseKeystoreFile.exists()
val hasGoogleServicesConfig = project.file("google-services.json").exists()

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// FIX: Firebase plugins applied conditionally inside app module, not globally.
if (hasGoogleServicesConfig) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = appId
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = appId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseKeystoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    if (hasGoogleServicesConfig) {
        implementation(platform("com.google.firebase:firebase-bom:\$firebaseBomVersion"))
        implementation("com.google.firebase:firebase-analytics")
        implementation("com.google.firebase:firebase-crashlytics")
    }
}
EOF

  # ── android/local.properties ─────────────────────────────────────
  cat > "${B}/android/local.properties" << 'EOF'
# ─────────────────────────────────────────────────────────────────
# This file is machine-specific and is excluded from version control.
# DO NOT commit this file.
#
# Run `make setup-local` to auto-generate from environment variables:
#   export ANDROID_HOME=/home/rohit/Android/Sdk
#   export FLUTTER_ROOT=/home/rohit/flutter
#   make setup-local
#
# Or fill in the values manually below:
# ─────────────────────────────────────────────────────────────────
sdk.dir=/home/rohit/Android/Sdk
flutter.sdk=/home/rohit/flutter
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
EOF

  # ════════════════════════════════════════════════════════════════
  # DONE
  # ════════════════════════════════════════════════════════════════
  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${GREEN}║   ✅  '${PROJECT_NAME}' scaffolded successfully!             ${RESET}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  local DIR_COUNT FILE_COUNT
  DIR_COUNT=$(find "${B}" -type d | wc -l | tr -d ' ')
  FILE_COUNT=$(find "${B}" -type f | wc -l | tr -d ' ')

  echo -e "  ${DIM}📁 Folders : ${WHITE}${DIR_COUNT}${RESET}"
  echo -e "  ${DIM}📄 Files   : ${WHITE}${FILE_COUNT}${RESET}"
  echo -e "  ${DIM}📦 App ID  : ${WHITE}${APP_ID}${RESET}"
  echo ""

  echo -e "${BOLD}${YELLOW}  ⚡ Next steps:${RESET}"
  echo -e "  ${GREEN}export ANDROID_HOME=/home/rohit/Android/Sdk${RESET}"
  echo -e "  ${GREEN}export FLUTTER_ROOT=/home/rohit/flutter${RESET}"
  echo -e "  ${GREEN}make setup-local${RESET}"
  echo -e "  ${GREEN}flutter pub get${RESET}"
  $_NEEDS_BUILD_RUNNER && echo -e "  ${GREEN}flutter pub run build_runner build --delete-conflicting-outputs${RESET}"
  echo -e "  ${GREEN}flutter run${RESET}"
  echo ""
  if _yes "$F_FLAVORS"; then
    echo -e "  ${YELLOW}🎨 Flavors:${RESET}"
    echo -e "  ${GREEN}make run-dev${RESET}       ${DIM}# development${RESET}"
    echo -e "  ${GREEN}make run-staging${RESET}   ${DIM}# staging${RESET}"
    echo -e "  ${GREEN}make run-prod${RESET}      ${DIM}# production${RESET}"
    echo ""
  fi
}
