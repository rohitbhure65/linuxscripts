#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Constants Generator - App constants, colors, strings
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/utils/file_ops.sh"

# ── App Colors ───────────────────────────────────────────
generate_app_colors() {
  local out="${OUT_DIR}/lib/core/constants/app_colors.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter/material.dart';

/// App color palette - semantic color definitions
abstract class AppColors {
  // ── Primary ───────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // ── Secondary ───────────────────────────────────────
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);

  // ── Semantic ───────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Light Theme ────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A000000);
  static const Color glassLight = Color(0x0A000000);

  // ── Dark Theme ──────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textDisabledDark = Color(0xFF475569);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF334155);
  static const Color shadowDark = Color(0x40000000);
  static const Color glassDark = Color(0x20000000);

  // ── Text ───────────────────────────────────────────
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1E293B);

  // ── Grey ───────────────────────────────────────────
  static const Color grey50 = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);
}
EOF
  
  log_step "Generated: app_colors.dart"
}

# ── App Strings ─────────────────────────────────────────
generate_app_strings() {
  local out="${OUT_DIR}/lib/core/constants/app_strings.dart"
  
  cat > "$out" << 'EOF'
/// App strings - static text content
abstract class AppStrings {
  // ── App ───────────────────────────────────────────
  static const String appName = '${PROJECT_NAME}';
  static const String appVersion = '1.0.0';

  // ── Common ─────────────────────────────────────
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String done = 'Done';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String skip = 'Skip';
  static const String submit = 'Submit';
  static const String retry = 'Retry';
  static const String close = 'Close';

  // ── Auth ─────────────────────────────────────────
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String noAccount = "Don't have an account?";
  static const String haveAccount = 'Already have an account?';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';

  // ── Errors ────────────────────────────────────────
  static const String errorGeneric = 'Something went wrong';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorUnauthorized = 'Session expired. Please login again.';
  static const String errorNotFound = 'Resource not found.';
}
EOF
  
  log_step "Generated: app_strings.dart"
}

# ── App Dimensions ─────────────────────────────────────
generate_app_dimensions() {
  local out="${OUT_DIR}/lib/core/constants/app_dimensions.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter/material.dart';

/// App dimensions - spacing, sizing, radii
abstract class AppDimensions {
  // ── Spacing ─────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ── Padding ─────────────────────────────────────
  static const EdgeInsets paddingXs = EdgeInsets.all(spacingXs);
  static const EdgeInsets paddingSm = EdgeInsets.all(spacingSm);
  static const EdgeInsets paddingMd = EdgeInsets.all(spacingMd);
  static const EdgeInsets paddingLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets paddingXl = EdgeInsets.all(spacingXl);

  // ── Radius ─────────────────────────────────────
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 999.0;

  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));

  // ── Icon ─────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ── Button ───────────────────────────────────
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;

  // ── Input ─────────────────────────────────────
  static const double inputHeight = 48.0;

  // ── AppBar ───────────────────────────────────
  static const double appBarHeight = 56.0;

  // ── Bottom Nav ────────────────────────────────
  static const double bottomNavHeight = 64.0;
}
EOF
  
  log_step "Generated: app_dimensions.dart"
}

# ── App API Constants ───────────────────────────────────
generate_app_api() {
  local out="${OUT_DIR}/lib/core/constants/app_api.dart"
  
  cat > "$out" << 'EOF'
/// App API constants - endpoints, headers, timeouts
abstract class AppApi {
  // ── Base URL ─────────────────────────────────────
  static const String baseUrl = 'https://api.example.com/v1';

  // ── Headers ────────────────────────────────────
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String headerAuth = 'Authorization';
  static const String headerLang = 'Accept-Language';

  // ── Values ────────────────────────────────────
  static const String valueJson = 'application/json';
  static const String valueBearer = 'Bearer ';

  // ── Timeouts ────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ── Retry ────────────────────────────────────
  static const int maxRetries = 3;
  static const int retryDelayMs = 1000;
}
EOF
  
  log_step "Generated: app_api.dart"
}

# ── Run All ───────────────────────────────────────────
generate_constants() {
  generate_app_colors
  generate_app_strings
  generate_app_dimensions
  generate_app_api
  log_success "Generated constants layer"
}