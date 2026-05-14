#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Default Values - Configuration defaults
# ═══════════════════════════════════════════════════════════════

# ── Flutter Version ───────────────────────────────────────────
_FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.0}"
_SDK_CONSTRAINT="${SDK_CONSTRAINT:->=3.5.0 <4.0.0}"

# ── Default Project Settings ────────────────────────────────
PROJECT_NAME="${PROJECT_NAME:-my_app}"
APP_ID="${APP_ID:-com.example.myapp}"
_SM_CHOICE="${SM_CHOICE:-1}"
_API_CHOICE="${API_CHOICE:-1}"
_STORAGE_CHOICE="${STORAGE_CHOICE:-1}"
_ROUTING_CHOICE="${ROUTING_CHOICE:-1}"

# ── State Management Defaults ────────────────────────────────
case "$_SM_CHOICE" in
  1) SM_LABEL="BLoC"; SM_DIR="bloc";;
  2) SM_LABEL="Riverpod"; SM_DIR="providers";;
  3) SM_LABEL="GetX"; SM_DIR="controllers";;
  4) SM_LABEL="Provider"; SM_DIR="providers";;
  *) SM_LABEL="BLoC"; SM_DIR="bloc"; SM_CHOICE=1;;
esac

# ── API Client Defaults ─────────────────────────────────
case "$_API_CHOICE" in
  1) API_LABEL="Dio + Retrofit";;
  2) API_LABEL="http";;
  3) API_LABEL="Firebase Firestore";;
  4) API_LABEL="GraphQL";;
  5) API_LABEL="Dio";;
  *) API_LABEL="Dio + Retrofit"; API_CHOICE=1;;
esac

# ── Storage Defaults ───────────────────────────────────────
case "$_STORAGE_CHOICE" in
  1) STORAGE_LABEL="Hive";;
  2) STORAGE_LABEL="SharedPreferences";;
  3) STORAGE_LABEL="SQLite";;
  4) STORAGE_LABEL="Isar";;
  *) STORAGE_LABEL="Hive"; STORAGE_CHOICE=1;;
esac

# ── Routing Defaults ────────────────────────────────────────
case "$_ROUTING_CHOICE" in
  1) F_GOROUTER=1; F_AUTOROUTE=0; ROUTING_LABEL="GoRouter";;
  2) F_GOROUTER=0; F_AUTOROUTE=1; ROUTING_LABEL="AutoRoute";;
  *) F_GOROUTER=0; F_AUTOROUTE=0; ROUTING_LABEL="Named Routes";;
esac

# ── Feature Flags (all enabled by default) ─────────────────
F_AUTH="${F_AUTH:-1}"
F_PUSH="${F_PUSH:-1}"
F_FIREBASE_AUTH="${F_FIREBASE_AUTH:-1}"
F_PAYMENT="${F_PAYMENT:-1}"
F_MAPS="${F_MAPS:-1}"
F_CHARTS="${F_CHARTS:-1}"
F_ONBOARDING="${F_ONBOARDING:-1}"
F_SPLASH="${F_SPLASH:-1}"
F_THEME="${F_THEME:-1}"
F_DI="${F_DI:-1}"
F_LOGGING="${F_LOGGING:-1}"
F_L10N="${F_L10N:-0}"
F_CONNECTIVITY="${F_CONNECTIVITY:-1}"
F_IMAGE_PICKER="${F_IMAGE_PICKER:-1}"
F_LOCATION="${F_LOCATION:-1}"
F_SENTRY="${F_SENTRY:-0}"
F_CICD="${F_CICD:-1}"
F_FLAVORS="${F_FLAVORS:-0}"
F_UNIT_TEST="${F_UNIT_TEST:-1}"
F_WIDGET_TEST="${F_WIDGET_TEST:-1}"

# ── Firebase ────────────────────────────────────────────────
_FIREBASE_BOM_VERSION="${_FIREBASE_BOM_VERSION:-33.0.0}"

# ── Helper: Check if feature is enabled ─────────────────────
_yes() {
  [[ "${!1:-0}" == "1" ]]
}

# ── Export All Variables ───────────────────────────────────
export_defaults() {
  export _FLUTTER_VERSION SDK_CONSTRAINT
  export PROJECT_NAME APP_ID
  export SM_CHOICE API_CHOICE STORAGE_CHOICE ROUTING_CHOICE
  export SM_LABEL SM_DIR API_LABEL STORAGE_LABEL ROUTING_LABEL
  export F_GOROUTER F_AUTOROUTE
  export F_AUTH F_PUSH F_FIREBASE_AUTH F_PAYMENT F_MAPS F_CHARTS
  export F_ONBOARDING F_SPLASH F_THEME F_DI F_LOGGING F_L10N
  export F_CONNECTIVITY F_IMAGE_PICKER F_LOCATION F_SENTRY
  export F_CICD F_FLAVORS F_UNIT_TEST F_WIDGET_TEST
  export _FIREBASE_BOM_VERSION
}