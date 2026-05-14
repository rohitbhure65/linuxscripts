#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Errors Generator - Exception and Failure types
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/utils/file_ops.sh"

# ── Exceptions ───────────────────────────────────────────
generate_exceptions() {
  local out="${OUT_DIR}/lib/core/errors/exceptions.dart"
  
  cat > "$out" << 'EOF'
/// App exceptions - custom exception types
abstract class AppException implements Exception {
  const AppException(this.message);
  final String message;
  
  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message);
  
  factory NetworkException.noConnection() =>
      const NetworkException('No internet connection');
  
  factory NetworkException.timeout() =>
      const NetworkException('Request timed out');
  
  factory NetworkException.server(String message) =>
      NetworkException('Server error: $message');
}

/// API exceptions
class ApiException extends AppException {
  const ApiException(super.message, {this.statusCode});
  final int? statusCode;
  
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}

/// Cache exceptions
class CacheException extends AppException {
  const CacheException(super.message);
  
  factory CacheException.notFound() =>
      const CacheException('Cached data not found');
  
  factory CacheException.expired() =>
      const CacheException('Cached data has expired');
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message);
  
  factory ValidationException.required(String field) =>
      ValidationException('$field is required');
  
  factory ValidationException.invalid(String field) =>
      ValidationException('$field is invalid');
}
EOF
  
  log_step "Generated: exceptions.dart"
}

# ── Failures ───────────────────────────────────────────
generate_failures() {
  local out="${OUT_DIR}/lib/core/errors/failures.dart"
  
  cat > "$out" << 'EOF'
import 'package:dartz/dartz.dart';

/// Base failure class - sealed hierarchy for error handling
sealed class Failure {
  const Failure(this.message);
  final String message;
  
  @override
  String toString() => message;
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unknown error occurred']);
}
EOF
  
  log_step "Generated: failures.dart"
}

# ── Error Messages ───────────────────────────────────────
generate_error_messages() {
  local out="${OUT_DIR}/lib/core/errors/error_messages.dart"
  
  cat > "$out" << 'EOF'
/// Error messages - user-facing error strings
abstract class ErrorMessages {
  // ── Network ─────────────────────────────────────
  static const String noConnection = 'No internet connection';
  static const String timeout = 'Request timed out';
  static const String serverError = 'Server error. Please try again.';
  
  // ── Auth ─────────────────────────────────────
  static const String invalidCredentials = 'Invalid email or password';
  static const String sessionExpired = 'Session expired. Please login again.';
  static const String accountLocked = 'Account locked. Please try again later.';
  
  // ── Validation ────────────────────────────────
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String invalidPhone = 'Please enter a valid phone number';
  static const String weakPassword = 'Password must be at least 8 characters';
  static const String passwordMismatch = 'Passwords do not match';
  
  // ── Generic ────────────────────────────────
  static const String somethingWrong = 'Something went wrong';
  static const String tryAgain = 'Please try again';
}
EOF
  
  log_step "Generated: error_messages.dart"
}

# ── Run All ───────────────────────────────────────────
generate_errors() {
  generate_exceptions
  generate_failures
  generate_error_messages
  log_success "Generated errors layer"
}