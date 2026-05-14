#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Configuration Prompts - Interactive CLI for project setup
# ═══════════════════════════════════════════════════════════════

# ── State Management Prompt ─────────────────────────────────
prompt_state_management() {
  log_info "Select State Management:"
  echo "  1) BLoC (flutter_bloc)"
  echo "  2) Riverpod (flutter_riverpod)"
  echo "  3) GetX (get)"
  echo "  4) Provider"
  read -p "  Choice [1]: " SM_CHOICE
  SM_CHOICE="${SM_CHOICE:-1}"
  
  case "$SM_CHOICE" in
    1) SM_LABEL="BLoC"; SM_DIR="bloc";;
    2) SM_LABEL="Riverpod"; SM_DIR="providers";;
    3) SM_LABEL="GetX"; SM_DIR="controllers";;
    4) SM_LABEL="Provider"; SM_DIR="providers";;
    *) SM_CHOICE=1; SM_LABEL="BLoC"; SM_DIR="bloc";;
  esac
}

# ── API Client Prompt ────────────────────────────────────────────
prompt_api_client() {
  log_info "Select API Client:"
  echo "  1) Dio + Retrofit"
  echo "  2) http (lightweight)"
  echo "  3) Firebase (Firestore)"
  echo "  4) GraphQL"
  echo "  5) Dio only (no code-gen)"
  read -p "  Choice [1]: " API_CHOICE
  API_CHOICE="${API_CHOICE:-1}"
  
  case "$API_CHOICE" in
    1) API_LABEL="Dio + Retrofit";;
    2) API_LABEL="http";;
    3) API_LABEL="Firebase Firestore";;
    4) API_LABEL="GraphQL";;
    5) API_LABEL="Dio";;
    *) API_CHOICE=1; API_LABEL="Dio + Retrofit";;
  esac
}

# ── Storage Prompt ───────────────────────────────────────────
prompt_storage() {
  log_info "Select Local Storage:"
  echo "  1) Hive (NoSQL)"
  echo "  2) SharedPreferences"
  echo "  3) SQLite (sqflite)"
  echo "  4) Isar"
  read -p "  Choice [1]: " STORAGE_CHOICE
  STORAGE_CHOICE="${STORAGE_CHOICE:-1}"
  
  case "$STORAGE_CHOICE" in
    1) STORAGE_LABEL="Hive";;
    2) STORAGE_LABEL="SharedPreferences";;
    3) STORAGE_LABEL="SQLite";;
    4) STORAGE_LABEL="Isar";;
    *) STORAGE_CHOICE=1; STORAGE_LABEL="Hive";;
  esac
}

# ── Features Prompt ──────────────────────────────────────────────
prompt_features() {
  log_info "Select Features (comma-separated, or 'all'):"
  echo "  a) Authentication (JWT, OAuth)"
  echo "  b) Push Notifications"
  echo "  c) Firebase (Auth, Firestore, Analytics)"
  echo "  d) Payment Gateway"
  echo "  e) Maps & Location"
  echo "  f) Charts"
  echo "  g) Onboarding"
  echo "  h) Splash Screen"
  read -p "  Features [all]: " FEATURES_INPUT
  
  if [[ "$FEATURES_INPUT" == "all" ]] || [[ -z "$FEATURES_INPUT" ]]; then
    F_AUTH=1; F_PUSH=1; F_FIREBASE_AUTH=1
    F_PAYMENT=1; F_MAPS=1; F_CHARTS=1
    F_ONBOARDING=1; F_SPLASH=1
  else
    echo "$FEATURES_INPUT" | grep -q "a" && F_AUTH=1
    echo "$FEATURES_INPUT" | grep -q "b" && F_PUSH=1
    echo "$FEATURES_INPUT" | grep -q "c" && F_FIREBASE_AUTH=1
    echo "$FEATURES_INPUT" | grep -q "d" && F_PAYMENT=1
    echo "$FEATURES_INPUT" | grep -q "e" && F_MAPS=1
    echo "$FEATURES_INPUT" | grep -q "f" && F_CHARTS=1
    echo "$FEATURES_INPUT" | grep -q "g" && F_ONBOARDING=1
    echo "$FEATURES_INPUT" | grep -q "h" && F_SPLASH=1
  fi
}

# ── Routing Prompt ───────────────────────────────────────────
prompt_routing() {
  log_info "Select Routing:"
  echo "  1) GoRouter (declarative)"
  echo "  2) AutoRoute (code-gen)"
  echo "  3) Named routes (default)"
  read -p "  Choice [1]: " ROUTING_CHOICE
  ROUTING_CHOICE="${ROUTING_CHOICE:-1}"
  
  case "$ROUTING_CHOICE" in
    1) F_GOROUTER=1; F_AUTOROUTE=0; ROUTING_LABEL="GoRouter";;
    2) F_GOROUTER=0; F_AUTOROUTE=1; ROUTING_LABEL="AutoRoute";;
    *) F_GOROUTER=0; F_AUTOROUTE=0; ROUTING_LABEL="Named Routes";;
  esac
}

# ── Project Name Prompt ─────────────────────────────────────
prompt_project_name() {
  read -p "Project name [my_app]: " PROJECT_NAME
  PROJECT_NAME="${PROJECT_NAME:-my_app}"
  
  # Validate: lowercase, underscores only
  if ! [[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
    log_warn "Invalid name. Using 'my_app'"
    PROJECT_NAME="my_app"
  fi
}

# ── App ID Prompt ───────────────────────────────────────────
prompt_app_id() {
  read -p "App ID [com.example.myapp]: " APP_ID
  APP_ID="${APP_ID:-com.example.myapp}"
}

# ── Run All Prompts ─────────────────────────────────────────
run_prompts() {
  clear
  log_bold "╔══════════════════════════════════════════════════════════════╗"
  log_bold "║     Flutter Project Scaffolder - Configuration            ║"
  log_bold "╚══════════════════════════════════════════════════════════════╝"
  echo ""
  
  prompt_project_name
  prompt_app_id
  prompt_state_management
  prompt_api_client
  prompt_storage
  prompt_routing
  prompt_features
  
  echo ""
  log_success "Configuration complete!"
}