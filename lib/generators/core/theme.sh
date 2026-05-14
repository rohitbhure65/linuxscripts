#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Theme Generator - Light/dark themes
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/utils/file_ops.sh"

# ── App Theme ───────────────────────────────────────────
generate_app_theme() {
  local out="${OUT_DIR}/lib/core/theme/app_theme.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/core/theme/light_theme.dart';
import 'package:${PROJECT_NAME}/core/theme/dark_theme.dart';

/// App theme - light/dark theme provider
class AppTheme {
  static ThemeData get light => lightThemeData;
  static ThemeData get dark => darkThemeData;
}
EOF
  
  log_step "Generated: app_theme.dart"
}

# ── Light Theme ───────────────────────────────────────────
generate_light_theme() {
  local out="${OUT_DIR}/lib/core/theme/light_theme.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/core/constants/app_colors.dart';

/// Light theme data
ThemeData lightThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Poppins',
  
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    error: AppColors.error,
  ),
  
  scaffoldBackgroundColor: AppColors.background,
  
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textLight,
    elevation: 0,
    centerTitle: true,
  ),
  
  cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.grey100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
  
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
  ),
);
EOF
  
  log_step "Generated: light_theme.dart"
}

# ── Dark Theme ───────────────────────────────────────────
generate_dark_theme() {
  local out="${OUT_DIR}/lib/core/theme/dark_theme.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter/material.dart';
import 'package:${PROJECT_NAME}/core/constants/app_colors.dart';

/// Dark theme data
ThemeData darkThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Poppins',
  
  colorScheme: ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surfaceDark,
    error: AppColors.error,
  ),
  
  scaffoldBackgroundColor: AppColors.backgroundDark,
  
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: AppColors.textLight,
    elevation: 0,
    centerTitle: true,
  ),
  
  cardTheme: CardThemeData(
    color: AppColors.cardDark,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textLight,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
  
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
  ),
);
EOF
  
  log_step "Generated: dark_theme.dart"
}

# ── Run All ───────────────────────────────────────────
generate_theme() {
  generate_app_theme
  generate_light_theme
  generate_dark_theme
  log_success "Generated theme layer"
}