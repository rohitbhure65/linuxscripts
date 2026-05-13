#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# ftools — Interactive Flutter Toolkit
#
# INSTALL:
#   cp .ftools.sh ~/.ftools.sh
#   echo 'source ~/.ftools.sh' >> ~/.bashrc
#   source ~/.bashrc
#
# USAGE:
#   ftools                  → Interactive TUI menu
#   fhelp                   → Show cheatsheet
#
# QUICK ALIASES (no menu needed):
#   fr    → pub get + run
#   frr   → pub get + run --release
#   frc   → clean + pub get + run
#   frrc  → clean + pub get + run --release
#   fba   → pub get + build appbundle
#   fbar  → pub get + build appbundle --release
#   fbac  → clean + pub get + build appbundle
#   fbarc → clean + pub get + build appbundle --release
# ─────────────────────────────────────────────────────────────────


# =================================================================
# COLORS
# =================================================================

_fc() {
  R='\033[0;31m';    LR='\033[1;31m'
  G='\033[0;32m';    LG='\033[1;32m'
  Y='\033[1;33m';    LY='\033[0;33m'
  B='\033[0;34m';    LB='\033[1;34m'
  M='\033[0;35m';    LM='\033[1;35m'
  C='\033[0;36m';    LC='\033[1;36m'
  W='\033[1;37m';    DIM='\033[2m'
  BOLD='\033[1m';    RESET='\033[0m'

  # Flutter brand color (blue-ish cyan)
  FL="${LC}"
}


# =================================================================
# GUARD: must be inside a Flutter project
# =================================================================

_check_flutter() {
  if ! command -v flutter &>/dev/null; then
    _fc
    echo -e "${LR}  ✗ Flutter not found in PATH.${RESET}"
    echo -e "${DIM}  Install Flutter and make sure it's in your PATH.${RESET}"
    return 1
  fi
  return 0
}

_check_flutter_project() {
  if [[ ! -f "pubspec.yaml" ]]; then
    _fc
    echo -e "${LR}  ✗ No pubspec.yaml found.${RESET}"
    echo -e "${DIM}  Run this from inside a Flutter project directory.${RESET}"
    return 1
  fi
  return 0
}


# =================================================================
# QUICK STATUS BAR
# =================================================================

_flutter_status_bar() {
  _fc

  local PROJECT_NAME="—"
  local FLUTTER_VER="—"
  local IN_PROJECT=false

  if [[ -f "pubspec.yaml" ]]; then
    PROJECT_NAME=$(grep '^name:' pubspec.yaml 2>/dev/null | awk '{print $2}')
    IN_PROJECT=true
  fi

  FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')

  if $IN_PROJECT; then
    echo -e "  ${DIM}Project: ${W}${BOLD}${PROJECT_NAME}${RESET}  ${DIM}│  Flutter: ${LC}${FLUTTER_VER}${RESET}  ${DIM}│  ${LG}✓ Inside Flutter project${RESET}"
  else
    echo -e "  ${DIM}Flutter: ${LC}${FLUTTER_VER}${RESET}  ${DIM}│  ${Y}⚠  Not inside a Flutter project${RESET}"
  fi
}


# =================================================================
# PLATFORM HELPERS
# =================================================================

_pick_platforms() {
  _fc
  echo ""
  echo -e "  ${BOLD}${Y}  Select platforms (space-separated numbers):${RESET}"
  echo -e "  ${LC}  1)${RESET} android"
  echo -e "  ${LC}  2)${RESET} ios"
  echo -e "  ${LC}  3)${RESET} web"
  echo -e "  ${LC}  4)${RESET} linux"
  echo -e "  ${LC}  5)${RESET} macos"
  echo -e "  ${LC}  6)${RESET} windows"
  echo ""
  read -rp "  Enter numbers (e.g. 1 2): " PLAT_INPUT

  SELECTED_PLATFORMS=""
  for NUM in $PLAT_INPUT; do
    case "$NUM" in
      1) SELECTED_PLATFORMS+="android,"  ;;
      2) SELECTED_PLATFORMS+="ios,"      ;;
      3) SELECTED_PLATFORMS+="web,"      ;;
      4) SELECTED_PLATFORMS+="linux,"    ;;
      5) SELECTED_PLATFORMS+="macos,"    ;;
      6) SELECTED_PLATFORMS+="windows,"  ;;
    esac
  done

  # Remove trailing comma
  SELECTED_PLATFORMS="${SELECTED_PLATFORMS%,}"
  echo "$SELECTED_PLATFORMS"
}


# =================================================================
# SECTION A: PROJECT SETUP
# =================================================================

_flutter_create() {
  _fc
  _check_flutter || return 1

  echo ""
  echo -e "${BOLD}${LC}  ── Create New Flutter Project ─────────────────────────────────${RESET}"
  echo ""

  read -rp "  Project name: " PNAME
  if [[ -z "$PNAME" ]]; then
    echo -e "${LR}  ✗ Project name cannot be empty.${RESET}"
    return 1
  fi

  # Validate project name (snake_case, no spaces)
  if [[ ! "$PNAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo -e "${LR}  ✗ Invalid name. Use lowercase letters, numbers, underscores only. Must start with a letter.${RESET}"
    return 1
  fi

  echo ""
  echo -e "  ${BOLD}${Y}  Platform preset:${RESET}"
  echo -e "  ${LC}  1)${RESET} Android only          ${DIM}(recommended for most projects)${RESET}"
  echo -e "  ${LC}  2)${RESET} Android + iOS"
  echo -e "  ${LC}  3)${RESET} All platforms"
  echo -e "  ${LC}  4)${RESET} Custom selection"
  echo ""
  read -rp "  Choose [1-4]: " POPT

  local PLATFORMS
  case "$POPT" in
    1) PLATFORMS="android" ;;
    2) PLATFORMS="android,ios" ;;
    3) PLATFORMS="android,ios,web,linux,macos,windows" ;;
    4) PLATFORMS=$(_pick_platforms) ;;
    *) PLATFORMS="android" ;;
  esac

  if [[ -z "$PLATFORMS" ]]; then
    echo -e "${LR}  ✗ No platforms selected.${RESET}"
    return 1
  fi

  echo ""
  read -rp "  Organization (e.g. com.yourname) [com.example]: " ORG
  ORG="${ORG:-com.example}"

  echo ""
  echo -e "  ${DIM}Running: flutter create --platforms ${PLATFORMS} --org ${ORG} ${PNAME}${RESET}"
  echo ""

  flutter create --platforms "$PLATFORMS" --org "$ORG" "$PNAME"

  if [[ $? -eq 0 ]]; then
    echo ""
    echo -e "${LG}  ✓ Project '${PNAME}' created with platforms: ${PLATFORMS}${RESET}"
    echo ""
    read -rp "  Open project directory now? (y/n): " OPENDIR
    [[ "$OPENDIR" == "y" || "$OPENDIR" == "Y" ]] && cd "$PNAME" && echo -e "${LC}  Moved into ${PNAME}/${RESET}"
  fi
}

_flutter_config_platforms() {
  _fc
  _check_flutter || return 1

  echo ""
  echo -e "${BOLD}${LC}  ── Configure Enabled Platforms ────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${DIM}Current Flutter config:${RESET}"
  flutter config 2>/dev/null | grep -E "enable" | while read -r LINE; do
    if echo "$LINE" | grep -q "true"; then
      echo -e "    ${LG}✓ ${LINE}${RESET}"
    else
      echo -e "    ${LR}✗ ${LINE}${RESET}"
    fi
  done
  echo ""

  echo -e "  ${BOLD}${Y}  What do you want to do?${RESET}"
  echo -e "  ${LC}  1)${RESET} Enable Android only      ${DIM}(disable all others)${RESET}"
  echo -e "  ${LC}  2)${RESET} Enable Android + iOS     ${DIM}(disable all others)${RESET}"
  echo -e "  ${LC}  3)${RESET} Enable ALL platforms"
  echo -e "  ${LC}  4)${RESET} Disable ALL platforms"
  echo -e "  ${LC}  5)${RESET} Custom enable/disable"
  echo ""
  read -rp "  Choose [1-5]: " COPT

  case "$COPT" in
    1)
      flutter config --no-enable-web
      flutter config --no-enable-ios
      flutter config --no-enable-linux-desktop
      flutter config --no-enable-macos-desktop
      flutter config --no-enable-windows-desktop
      echo -e "${LG}  ✓ Only Android enabled.${RESET}"
      ;;
    2)
      flutter config --enable-ios
      flutter config --no-enable-web
      flutter config --no-enable-linux-desktop
      flutter config --no-enable-macos-desktop
      flutter config --no-enable-windows-desktop
      echo -e "${LG}  ✓ Android + iOS enabled.${RESET}"
      ;;
    3)
      flutter config --enable-android
      flutter config --enable-ios
      flutter config --enable-web
      flutter config --enable-linux-desktop
      flutter config --enable-macos-desktop
      flutter config --enable-windows-desktop
      echo -e "${LG}  ✓ All platforms enabled.${RESET}"
      ;;
    4)
      flutter config --no-enable-android
      flutter config --no-enable-ios
      flutter config --no-enable-web
      flutter config --no-enable-linux-desktop
      flutter config --no-enable-macos-desktop
      flutter config --no-enable-windows-desktop
      echo -e "${LR}  ✓ All platforms disabled.${RESET}"
      ;;
    5)
      echo ""
      echo -e "  ${Y}  Enable or disable each platform:${RESET}"
      local PLATFORMS_LIST=("android" "ios" "web" "linux-desktop" "macos-desktop" "windows-desktop")
      for PLAT in "${PLATFORMS_LIST[@]}"; do
        read -rp "  ${PLAT} [e=enable / d=disable / s=skip]: " PACT
        case "$PACT" in
          e) flutter config "--enable-${PLAT}"    && echo -e "${LG}    ✓ Enabled ${PLAT}${RESET}"  ;;
          d) flutter config "--no-enable-${PLAT}" && echo -e "${LR}    ✓ Disabled ${PLAT}${RESET}" ;;
          *) echo -e "${DIM}    Skipped ${PLAT}${RESET}" ;;
        esac
      done
      ;;
    *)
      echo -e "${LR}  ✗ Invalid option.${RESET}"
      ;;
  esac

  echo ""
  echo -e "  ${DIM}Updated config:${RESET}"
  flutter config 2>/dev/null | grep -E "enable" | while read -r LINE; do
    if echo "$LINE" | grep -q "true"; then
      echo -e "    ${LG}✓ ${LINE}${RESET}"
    else
      echo -e "    ${LR}✗ ${LINE}${RESET}"
    fi
  done
}


# =================================================================
# SECTION B: RUN
# =================================================================

_flutter_run_menu() {
  _fc
  _check_flutter || return 1
  _check_flutter_project || return 1

  echo ""
  echo -e "${BOLD}${LC}  ── Run ────────────────────────────────────────────────────────${RESET}"
  echo ""

  # Show connected devices
  echo -e "  ${DIM}Connected devices:${RESET}"
  flutter devices 2>/dev/null | tail -n +2 | while read -r LINE; do
    [[ -z "$LINE" ]] && continue
    echo -e "    ${LC}${LINE}${RESET}"
  done
  echo ""

  echo -e "  ${LG}  1)${RESET}  Run (debug)                ${DIM}-- flutter run${RESET}"
  echo -e "  ${LG}  2)${RESET}  Run (release)              ${DIM}-- flutter run --release${RESET}"
  echo -e "  ${LG}  3)${RESET}  Run (profile)              ${DIM}-- flutter run --profile${RESET}"
  echo -e "  ${Y}   4)${RESET}  Run with clean first       ${DIM}-- flutter clean && pub get && run${RESET}"
  echo -e "  ${Y}   5)${RESET}  Run release with clean     ${DIM}-- flutter clean && pub get && run --release${RESET}"
  echo -e "  ${LC}  6)${RESET}  Run on specific device     ${DIM}-- flutter run -d <device>${RESET}"
  echo -e "  ${LC}  7)${RESET}  Hot reload only            ${DIM}-- (press r in running session)${RESET}"
  echo ""
  read -rp "  Choose [1-6]: " ROPT

  case "$ROPT" in
    1)
      flutter pub get && flutter run
      ;;
    2)
      flutter pub get && flutter run --release
      ;;
    3)
      flutter pub get && flutter run --profile
      ;;
    4)
      flutter clean && flutter pub get && flutter run
      ;;
    5)
      flutter clean && flutter pub get && flutter run --release
      ;;
    6)
      read -rp "  Device ID: " DEV_ID
      [[ -z "$DEV_ID" ]] && return
      flutter pub get && flutter run -d "$DEV_ID"
      ;;
    *)
      echo -e "${LR}  ✗ Invalid option.${RESET}"
      ;;
  esac
}


# =================================================================
# SECTION C: BUILD
# =================================================================

_flutter_build_menu() {
  _fc
  _check_flutter || return 1
  _check_flutter_project || return 1

  echo ""
  echo -e "${BOLD}${LC}  ── Build ──────────────────────────────────────────────────────${RESET}"
  echo ""
  echo -e "${BOLD}${Y}  ━━ ANDROID ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "  ${LG}  1)${RESET}  Build APK (debug)          ${DIM}-- flutter build apk${RESET}"
  echo -e "  ${LG}  2)${RESET}  Build APK (release)        ${DIM}-- flutter build apk --release${RESET}"
  echo -e "  ${LG}  3)${RESET}  Build APK split by ABI     ${DIM}-- flutter build apk --split-per-abi${RESET}"
  echo -e "  ${LG}  4)${RESET}  Build App Bundle           ${DIM}-- flutter build appbundle${RESET}"
  echo -e "  ${LG}  5)${RESET}  Build App Bundle (release) ${DIM}-- flutter build appbundle --release${RESET}"
  echo ""
  echo -e "${BOLD}${Y}  ━━ WITH CLEAN ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "  ${Y}   6)${RESET}  Clean + Build APK release  ${DIM}-- clean && pub get && build apk --release${RESET}"
  echo -e "  ${Y}   7)${RESET}  Clean + Build AAB release  ${DIM}-- clean && pub get && build appbundle --release${RESET}"
  echo -e "  ${Y}   8)${RESET}  Clean + Build APK split    ${DIM}-- clean && pub get && build apk --split-per-abi${RESET}"
  echo ""
  echo -e "${BOLD}${Y}  ━━ WEB ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "  ${LC}  9)${RESET}  Build Web                  ${DIM}-- flutter build web${RESET}"
  echo -e "  ${LC} 10)${RESET}  Build Web (release)        ${DIM}-- flutter build web --release${RESET}"
  echo ""
  read -rp "  Choose [1-10]: " BOPT

  local PRE_BUILD=""
  local BUILD_CMD=""

  case "$BOPT" in
    1)  BUILD_CMD="flutter pub get && flutter build apk" ;;
    2)  BUILD_CMD="flutter pub get && flutter build apk --release" ;;
    3)  BUILD_CMD="flutter pub get && flutter build apk --split-per-abi" ;;
    4)  BUILD_CMD="flutter pub get && flutter build appbundle" ;;
    5)  BUILD_CMD="flutter pub get && flutter build appbundle --release" ;;
    6)  BUILD_CMD="flutter clean && flutter pub get && flutter build apk --release" ;;
    7)  BUILD_CMD="flutter clean && flutter pub get && flutter build appbundle --release" ;;
    8)  BUILD_CMD="flutter clean && flutter pub get && flutter build apk --split-per-abi" ;;
    9)  BUILD_CMD="flutter pub get && flutter build web" ;;
    10) BUILD_CMD="flutter pub get && flutter build web --release" ;;
    *)  echo -e "${LR}  ✗ Invalid option.${RESET}" && return ;;
  esac

  echo ""
  echo -e "  ${DIM}Running: ${BUILD_CMD}${RESET}"
  echo ""
  eval "$BUILD_CMD"

  if [[ $? -eq 0 ]]; then
    echo ""
    echo -e "${LG}  ✓ Build completed successfully!${RESET}"

    # Show output location
    if [[ "$BOPT" -le 3 || "$BOPT" -eq 6 || "$BOPT" -eq 8 ]]; then
      echo -e "  ${DIM}APK location: ${W}build/app/outputs/flutter-apk/${RESET}"
    elif [[ "$BOPT" -eq 4 || "$BOPT" -eq 5 || "$BOPT" -eq 7 ]]; then
      echo -e "  ${DIM}AAB location: ${W}build/app/outputs/bundle/release/${RESET}"
    elif [[ "$BOPT" -ge 9 ]]; then
      echo -e "  ${DIM}Web location: ${W}build/web/${RESET}"
    fi
  else
    echo ""
    echo -e "${LR}  ✗ Build failed. Try running with clean (option 6/7/8).${RESET}"
  fi
}


# =================================================================
# SECTION D: PACKAGES
# =================================================================

_flutter_packages() {
  _fc
  _check_flutter || return 1
  _check_flutter_project || return 1

  echo ""
  echo -e "${BOLD}${LC}  ── Package Manager ────────────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${LG}  1)${RESET}  pub get                    ${DIM}-- flutter pub get${RESET}"
  echo -e "  ${LG}  2)${RESET}  pub upgrade                ${DIM}-- flutter pub upgrade${RESET}"
  echo -e "  ${LG}  3)${RESET}  pub outdated               ${DIM}-- flutter pub outdated${RESET}"
  echo -e "  ${LG}  4)${RESET}  Add a package              ${DIM}-- flutter pub add <pkg>${RESET}"
  echo -e "  ${LG}  5)${RESET}  Remove a package           ${DIM}-- flutter pub remove <pkg>${RESET}"
  echo -e "  ${LC}  6)${RESET}  pub deps (tree)            ${DIM}-- flutter pub deps${RESET}"
  echo -e "  ${LC}  7)${RESET}  pub publish (dry run)      ${DIM}-- flutter pub publish --dry-run${RESET}"
  echo ""
  read -rp "  Choose [1-7]: " POPT

  case "$POPT" in
    1) flutter pub get ;;
    2) flutter pub upgrade ;;
    3) flutter pub outdated ;;
    4)
      read -rp "  Package name: " PKG
      [[ -z "$PKG" ]] && return
      flutter pub add "$PKG" && echo -e "${LG}  ✓ Added: ${PKG}${RESET}"
      ;;
    5)
      read -rp "  Package name to remove: " PKG
      [[ -z "$PKG" ]] && return
      flutter pub remove "$PKG" && echo -e "${LR}  ✓ Removed: ${PKG}${RESET}"
      ;;
    6) flutter pub deps ;;
    7) flutter pub publish --dry-run ;;
    *) echo -e "${LR}  ✗ Invalid option.${RESET}" ;;
  esac
}


# =================================================================
# SECTION E: DOCTOR & DIAGNOSTICS
# =================================================================

_flutter_doctor() {
  _fc
  _check_flutter || return 1

  echo ""
  echo -e "${BOLD}${LC}  ── Diagnostics ─────────────────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${LG}  1)${RESET}  flutter doctor             ${DIM}-- Basic health check${RESET}"
  echo -e "  ${LG}  2)${RESET}  flutter doctor -v          ${DIM}-- Verbose health check${RESET}"
  echo -e "  ${LC}  3)${RESET}  flutter --version          ${DIM}-- Flutter version info${RESET}"
  echo -e "  ${LC}  4)${RESET}  flutter devices            ${DIM}-- List connected devices${RESET}"
  echo -e "  ${LC}  5)${RESET}  flutter emulators          ${DIM}-- List available emulators${RESET}"
  echo -e "  ${LC}  6)${RESET}  Launch an emulator         ${DIM}-- flutter emulators --launch <id>${RESET}"
  echo -e "  ${Y}   7)${RESET}  flutter analyze            ${DIM}-- Static code analysis${RESET}"
  echo -e "  ${Y}   8)${RESET}  flutter test               ${DIM}-- Run all tests${RESET}"
  echo ""
  read -rp "  Choose [1-8]: " DOPT

  case "$DOPT" in
    1) flutter doctor ;;
    2) flutter doctor -v ;;
    3) flutter --version ;;
    4) flutter devices ;;
    5) flutter emulators ;;
    6)
      echo -e "${DIM}  Available emulators:${RESET}"
      flutter emulators 2>/dev/null
      echo ""
      read -rp "  Emulator ID to launch: " EMU_ID
      [[ -z "$EMU_ID" ]] && return
      flutter emulators --launch "$EMU_ID"
      ;;
    7) flutter analyze ;;
    8)
      _check_flutter_project || return 1
      flutter test
      ;;
    *) echo -e "${LR}  ✗ Invalid option.${RESET}" ;;
  esac
}


# =================================================================
# SECTION F: CLEAN & MAINTENANCE
# =================================================================

_flutter_clean_menu() {
  _fc
  _check_flutter || return 1
  _check_flutter_project || return 1

  echo ""
  echo -e "${BOLD}${LC}  ── Clean & Maintenance ─────────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${Y}   1)${RESET}  flutter clean              ${DIM}-- Remove build artifacts${RESET}"
  echo -e "  ${LG}  2)${RESET}  flutter clean + pub get    ${DIM}-- Full fresh reset${RESET}"
  echo -e "  ${M}   3)${RESET}  Invalidate Dart cache      ${DIM}-- dart pub cache repair${RESET}"
  echo -e "  ${M}   4)${RESET}  flutter upgrade            ${DIM}-- Upgrade Flutter itself${RESET}"
  echo -e "  ${M}   5)${RESET}  flutter channel            ${DIM}-- Show current channel${RESET}"
  echo -e "  ${M}   6)${RESET}  Switch Flutter channel     ${DIM}-- stable / beta / master${RESET}"
  echo ""
  read -rp "  Choose [1-6]: " COPT

  case "$COPT" in
    1)
      flutter clean && echo -e "${LG}  ✓ Clean done.${RESET}"
      ;;
    2)
      flutter clean && flutter pub get && echo -e "${LG}  ✓ Clean + pub get done.${RESET}"
      ;;
    3)
      dart pub cache repair && echo -e "${LG}  ✓ Dart cache repaired.${RESET}"
      ;;
    4)
      flutter upgrade
      ;;
    5)
      flutter channel
      ;;
    6)
      echo -e "  ${LC}  1)${RESET} stable   ${LC}  2)${RESET} beta   ${LC}  3)${RESET} master"
      read -rp "  Channel [1-3]: " CH
      case "$CH" in
        1) flutter channel stable  && flutter upgrade ;;
        2) flutter channel beta    && flutter upgrade ;;
        3) flutter channel master  && flutter upgrade ;;
        *) echo -e "${LR}  ✗ Invalid.${RESET}" ;;
      esac
      ;;
    *) echo -e "${LR}  ✗ Invalid option.${RESET}" ;;
  esac
}


# =================================================================
# SECTION G: CODE GENERATION
# =================================================================

_flutter_codegen() {
  _fc
  _check_flutter || return 1
  _check_flutter_project || return 1

  echo ""
  echo -e "${BOLD}${LC}  ── Code Generation ─────────────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${LG}  1)${RESET}  build_runner once          ${DIM}-- dart run build_runner build${RESET}"
  echo -e "  ${LG}  2)${RESET}  build_runner watch         ${DIM}-- dart run build_runner watch${RESET}"
  echo -e "  ${Y}   3)${RESET}  build_runner clean+build   ${DIM}-- build_runner build --delete-conflicting${RESET}"
  echo -e "  ${LC}  4)${RESET}  flutter_gen (assets)       ${DIM}-- dart run flutter_gen${RESET}"
  echo -e "  ${LC}  5)${RESET}  freezed codegen            ${DIM}-- build_runner build (freezed)${RESET}"
  echo ""
  read -rp "  Choose [1-5]: " GOPT

  case "$GOPT" in
    1) dart run build_runner build ;;
    2) dart run build_runner watch ;;
    3) dart run build_runner build --delete-conflicting-outputs ;;
    4) dart run flutter_gen ;;
    5) dart run build_runner build --delete-conflicting-outputs ;;
    *) echo -e "${LR}  ✗ Invalid option.${RESET}" ;;
  esac
}


# =================================================================
# SECTION H: LOCALIZATION
# =================================================================

_flutter_l10n() {
  _fc
  _check_flutter || return 1
  _check_flutter_project || return 1

  echo ""
  echo -e "${BOLD}${LC}  ── Localization (l10n) ─────────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${LG}  1)${RESET}  Generate l10n files        ${DIM}-- flutter gen-l10n${RESET}"
  echo -e "  ${LC}  2)${RESET}  Check l10n config          ${DIM}-- show l10n.yaml${RESET}"
  echo ""
  read -rp "  Choose [1-2]: " LOPT

  case "$LOPT" in
    1) flutter gen-l10n && echo -e "${LG}  ✓ l10n files generated.${RESET}" ;;
    2)
      if [[ -f "l10n.yaml" ]]; then
        cat l10n.yaml
      else
        echo -e "${LR}  ✗ l10n.yaml not found in project root.${RESET}"
      fi
      ;;
    *) echo -e "${LR}  ✗ Invalid.${RESET}" ;;
  esac
}


# =================================================================
# QUICK COMMANDS (standalone functions)
# =================================================================

flutter-only-android() {
  _fc
  echo -e "${Y}  Disabling all platforms except Android...${RESET}"
  flutter config --no-enable-web
  flutter config --no-enable-ios
  flutter config --no-enable-linux-desktop
  flutter config --no-enable-macos-desktop
  flutter config --no-enable-windows-desktop
  echo -e "${LG}  ✓ Done! Run 'flutter config' to verify.${RESET}"
}

flutter-create-android() {
  _fc
  if [[ -z "$1" ]]; then
    echo -e "${LR}  ✗ Please provide a project name.${RESET}"
    echo -e "${DIM}  Usage: flutter-create-android my_app${RESET}"
  else
    flutter create --platforms android "$1"
    echo -e "${LG}  ✓ Created Android-only project: $1${RESET}"
  fi
}

flutter-create-android-ios() {
  _fc
  if [[ -z "$1" ]]; then
    echo -e "${LR}  ✗ Please provide a project name.${RESET}"
    echo -e "${DIM}  Usage: flutter-create-android-ios my_app${RESET}"
  else
    flutter create --platforms android,ios "$1"
    echo -e "${LG}  ✓ Created Android + iOS project: $1${RESET}"
  fi
}


# =================================================================
# QUICK ALIASES
# =================================================================

# Run
alias fr='flutter pub get && flutter run'
alias frr='flutter pub get && flutter run --release'
alias frp='flutter pub get && flutter run --profile'
alias frc='flutter clean && flutter pub get && flutter run'
alias frrc='flutter clean && flutter pub get && flutter run --release'

# Build APK
alias fba='flutter pub get && flutter build apk'
alias fbar='flutter pub get && flutter build apk --release'
alias fbas='flutter pub get && flutter build apk --split-per-abi'
alias fbac='flutter clean && flutter pub get && flutter build apk'
alias fbarc='flutter clean && flutter pub get && flutter build apk --release'
alias fbasc='flutter clean && flutter pub get && flutter build apk --split-per-abi'

# Build App Bundle
alias fbb='flutter pub get && flutter build appbundle'
alias fbbr='flutter pub get && flutter build appbundle --release'
alias fbbc='flutter clean && flutter pub get && flutter build appbundle'
alias fbbrc='flutter clean && flutter pub get && flutter build appbundle --release'

# Packages
alias fpg='flutter pub get'
alias fpu='flutter pub upgrade'
alias fpo='flutter pub outdated'

# Misc
alias fclean='flutter clean'
alias fcleanget='flutter clean && flutter pub get'
alias fdoc='flutter doctor'
alias fdocv='flutter doctor -v'
alias fdev='flutter devices'
alias fana='flutter analyze'
alias ftest='flutter test'
alias fbr='dart run build_runner build --delete-conflicting-outputs'
alias fbrw='dart run build_runner watch'


# =================================================================
# MAIN TUI MENU
# =================================================================

ftools() {
  _fc
  _check_flutter || return 1

  while true; do
    clear
    echo ""
    echo -e "${BOLD}${LC}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${LC}║          🐦  ftools — Flutter Interactive Toolkit            ║${RESET}"
    echo -e "${BOLD}${LC}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    _flutter_status_bar
    echo ""
    echo -e "${BOLD}${Y}  ━━ PROJECT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${LG}  1)${RESET}  🆕  Create new project      ${DIM}-- flutter create${RESET}"
    echo -e "  ${LG}  2)${RESET}  🔧  Configure platforms     ${DIM}-- flutter config${RESET}"
    echo ""
    echo -e "${BOLD}${Y}  ━━ RUN ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${LG}  3)${RESET}  ▶️   Run app                 ${DIM}-- flutter run [options]${RESET}"
    echo ""
    echo -e "${BOLD}${Y}  ━━ BUILD ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${LG}  4)${RESET}  🔨  Build                   ${DIM}-- APK / AAB / Web${RESET}"
    echo ""
    echo -e "${BOLD}${Y}  ━━ PACKAGES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${LG}  5)${RESET}  📦  Package manager         ${DIM}-- pub get / add / remove / upgrade${RESET}"
    echo ""
    echo -e "${BOLD}${Y}  ━━ DIAGNOSTICS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${LC}  6)${RESET}  🩺  Doctor & devices        ${DIM}-- flutter doctor / devices / emulators${RESET}"
    echo -e "  ${LC}  7)${RESET}  🔍  Analyze & test          ${DIM}-- flutter analyze / test${RESET}"
    echo ""
    echo -e "${BOLD}${Y}  ━━ MAINTENANCE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${M}   8)${RESET}  🧹  Clean & upgrade         ${DIM}-- flutter clean / upgrade / channel${RESET}"
    echo ""
    echo -e "${BOLD}${Y}  ━━ CODE GENERATION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${Y}   9)${RESET}  ⚙️   build_runner            ${DIM}-- dart run build_runner${RESET}"
    echo -e "  ${Y}  10)${RESET}  🌍  Localization (l10n)     ${DIM}-- flutter gen-l10n${RESET}"
    echo ""
    echo -e "${BOLD}${Y}  ━━ HELP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${C}  11)${RESET}  📖  Cheatsheet             ${DIM}-- fhelp${RESET}"
    echo ""
    echo -e "  ${LR}   0)${RESET}  🚪  Exit"
    echo ""
    read -rp "  Choose option [0-11]: " CHOICE
    echo ""

    case "$CHOICE" in
      1)  _flutter_create     ;;
      2)  _flutter_config_platforms ;;
      3)  _flutter_run_menu   ;;
      4)  _flutter_build_menu ;;
      5)  _flutter_packages   ;;
      6)  _flutter_doctor     ;;
      7)
          _check_flutter_project && {
            echo -e "  ${LC}  1)${RESET} analyze   ${LC}  2)${RESET} test"
            read -rp "  Choose: " AT
            case "$AT" in
              1) flutter analyze ;;
              2) flutter test    ;;
              *) echo -e "${LR}  ✗ Invalid.${RESET}" ;;
            esac
          }
          ;;
      8)  _flutter_clean_menu ;;
      9)  _flutter_codegen    ;;
      10) _flutter_l10n       ;;
      11) fhelp               ;;
      0)
        echo -e "${LC}  Goodbye! 🐦${RESET}"
        echo ""
        return 0
        ;;
      *)
        echo -e "${LR}  ✗ Invalid option. Choose 0-11.${RESET}"
        ;;
    esac

    echo ""
    read -rp "  Press Enter to return to menu..." _PAUSE
  done
}


# =================================================================
# CHEATSHEET
# =================================================================

fhelp() {
  _fc

  local DIV="${DIM}────────────────────────────────────────────────────────────────────────────────────${RESET}"

  echo ""
  echo -e "${BOLD}${LC}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${LC}║          🐦  ftools — Flutter Cheatsheet                     ║${RESET}"
  echo -e "${BOLD}${LC}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  printf "  ${BOLD}${W}%-26s %-35s %s${RESET}\n" "ALIAS / COMMAND" "WHAT IT DOES" "FLUTTER COMMAND"
  echo -e "$DIV"

  # Run
  echo -e "  ${BOLD}${Y}» Run${RESET}"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fr"    "pub get + run (debug)"          "flutter pub get && flutter run"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "frr"   "pub get + run (release)"        "flutter pub get && flutter run --release"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "frp"   "pub get + run (profile)"        "flutter pub get && flutter run --profile"
  printf "  ${Y}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "frc"   "clean + pub get + run"          "flutter clean && pub get && run"
  printf "  ${Y}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "frrc"  "clean + pub get + run release"  "flutter clean && pub get && run --release"
  echo -e "$DIV"

  # Build APK
  echo -e "  ${BOLD}${Y}» Build APK${RESET}"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fba"   "pub get + build apk"            "flutter build apk"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbar"  "pub get + build apk release"    "flutter build apk --release"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbas"  "pub get + build apk split ABI"  "flutter build apk --split-per-abi"
  printf "  ${Y}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbac"  "clean + build apk"              "flutter clean && build apk"
  printf "  ${Y}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbarc" "clean + build apk release"      "flutter clean && build apk --release"
  printf "  ${Y}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbasc" "clean + build apk split ABI"    "flutter clean && build apk --split-per-abi"
  echo -e "$DIV"

  # Build Bundle
  echo -e "  ${BOLD}${Y}» Build App Bundle (AAB)${RESET}"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbb"   "pub get + build appbundle"      "flutter build appbundle"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbbr"  "pub get + build bundle release" "flutter build appbundle --release"
  printf "  ${Y}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbbc"  "clean + build appbundle"        "flutter clean && build appbundle"
  printf "  ${Y}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbbrc" "clean + build bundle release"   "flutter clean && build appbundle --release"
  echo -e "$DIV"

  # Packages
  echo -e "  ${BOLD}${Y}» Packages${RESET}"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fpg"   "pub get"                        "flutter pub get"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fpu"   "pub upgrade"                    "flutter pub upgrade"
  printf "  ${LG}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fpo"   "pub outdated"                   "flutter pub outdated"
  echo -e "$DIV"

  # Maintenance
  echo -e "  ${BOLD}${Y}» Maintenance${RESET}"
  printf "  ${M}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fclean"    "flutter clean"              "flutter clean"
  printf "  ${M}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fcleanget" "clean + pub get"            "flutter clean && flutter pub get"
  printf "  ${M}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fdoc"      "flutter doctor"             "flutter doctor"
  printf "  ${M}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fdocv"     "flutter doctor -v"          "flutter doctor -v"
  printf "  ${M}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fdev"      "list devices"               "flutter devices"
  printf "  ${M}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fana"      "analyze code"               "flutter analyze"
  printf "  ${M}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "ftest"     "run tests"                  "flutter test"
  echo -e "$DIV"

  # Code gen
  echo -e "  ${BOLD}${Y}» Code Generation${RESET}"
  printf "  ${Y}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbr"   "build_runner build"             "dart run build_runner build --delete-conflicting-outputs"
  printf "  ${Y}%-26s${RESET}  ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fbrw"  "build_runner watch"             "dart run build_runner watch"
  echo -e "$DIV"

  # Project helpers
  echo -e "  ${BOLD}${Y}» Project Creation Helpers${RESET}"
  printf "  ${LC}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "flutter-only-android"       "Disable all except Android"   "flutter config --no-enable-*"
  printf "  ${LC}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "flutter-create-android"     "Create Android-only project"  "flutter create --platforms android"
  printf "  ${LC}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "flutter-create-android-ios" "Create Android+iOS project"   "flutter create --platforms android,ios"
  echo -e "$DIV"

  printf "  ${LC}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "ftools"  "Launch interactive menu"      "-"
  printf "  ${LC}%-26s${RESET} ${W}%-35s${RESET} ${DIM}%s${RESET}\n" "fhelp"   "Show this cheatsheet"         "-"
  echo ""
  echo -e "  ${BOLD}Legend:${RESET}  ${LG}■${RESET} Safe   ${Y}■${RESET} With clean   ${M}■${RESET} Maintenance   ${LC}■${RESET} Setup / Meta"
  echo ""
}
