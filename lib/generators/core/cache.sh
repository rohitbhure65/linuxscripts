#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Cache Generator - Cache manager, keys, policy
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/utils/file_ops.sh"

# ── Cache Keys ───────────────────────────────────────────
generate_cache_keys() {
  local out="${OUT_DIR}/lib/core/cache/cache_keys.dart"
  
  cat > "$out" << 'EOF'
/// Cache keys - single source of truth for cache keys
abstract final class CacheKeys {
  // ── Auth ─────────────────────────────────────
  static const String authToken = 'cache:auth:token';
  static const String refreshToken = 'cache:auth:refresh_token';
  static const String userId = 'cache:auth:user_id';
  
  // ── User ─────────────────────────────────────
  static const String userProfile = 'cache:user:profile';
  static const String userSettings = 'cache:user:settings';
  static const String userPrefs = 'cache:user:prefs';
  
  // ── App ─────────────────────────────────────
  static const String onboarded = 'cache:app:onboarded';
  static const String themeMode = 'cache:app:theme_mode';
  static const String locale = 'cache:app:locale';
  static const String firstLaunch = 'cache:app:first_launch';
  static const String lastVersion = 'cache:app:last_version';
  
  // ── Dynamic Keys ────────────────────────────────
  static String user(String id) => 'cache:user:$id';
  static String file(String id) => 'cache:file:$id';
  static String query(String hash) => 'cache:query:$hash';
}
EOF
  
  log_step "Generated: cache_keys.dart"
}

# ── Cache Policy ───────────────────────────────────────
generate_cache_policy() {
  local out="${OUT_DIR}/lib/core/cache/cache_policy.dart"
  
  cat > "$out" << 'EOF'
/// Cache policy - TTL and fetch strategy
enum CacheStrategy {
  cacheOnly,
  networkOnly,
  cacheFirst,
  networkFirst,
  staleWhileRevalidate,
}

/// Cache policy definition
class CachePolicy {
  const CachePolicy({
    required this.ttl,
    this.strategy = CacheStrategy.cacheFirst,
    this.maxStaleAge,
    this.encrypt = false,
  });
  
  final Duration ttl;
  final CacheStrategy strategy;
  final Duration? maxStaleAge;
  final bool encrypt;
  
  bool get isExpirable => ttl != Duration.zero;
  
  // ── Predefined Policies ───────────────────
  static const auth = CachePolicy(
    ttl: Duration(hours: 1),
    strategy: CacheStrategy.cacheFirst,
    encrypt: true,
  );
  
  static const userProfile = CachePolicy(
    ttl: Duration(hours: 6),
    strategy: CacheStrategy.networkFirst,
  );
  
  static const settings = CachePolicy(
    ttl: Duration(days: 30),
    strategy: CacheStrategy.cacheFirst,
  );
  
  static const feed = CachePolicy(
    ttl: Duration(minutes: 10),
    strategy: CacheStrategy.staleWhileRevalidate,
    maxStaleAge: Duration(hours: 1),
  );
  
  static const noCache = CachePolicy(
    ttl: Duration.zero,
    strategy: CacheStrategy.networkOnly,
  );
}
EOF
  
  log_step "Generated: cache_policy.dart"
}

# ── Cache Manager ───────────────────────────────────────
generate_cache_manager() {
  local out="${OUT_DIR}/lib/core/cache/cache_manager.dart"
  
  cat > "$out" << 'EOF'
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_policy.dart';

/// Cache entry wrapper
class _CacheEntry {
  const _CacheEntry({required this.data, required this.expiresAt});
  final String data;
  final DateTime expiresAt;
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Map<String, dynamic> toJson() => {
    'data': data,
    'expiresAt': expiresAt.toIso8601String(),
  };
  
  factory _CacheEntry.fromJson(Map<String, dynamic> json) => _CacheEntry(
    data: json['data'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}

/// Cache manager - policy-aware wrapper around SharedPreferences
class CacheManager {
  CacheManager._();
  static final CacheManager instance = CacheManager._();
  
  SharedPreferences? _prefs;
  
  /// Initialize - call once in main()
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  // ── Write ─────────────────────────────────
  Future<void> setString(String key, String value, {CachePolicy policy = const CachePolicy(ttl: Duration(hours: 12)) async {
    final entry = _CacheEntry(
      data: value,
      expiresAt: DateTime.now().add(policy.ttl),
    );
    await _prefs!.setString(key, jsonEncode(entry.toJson()));
  }
  
  Future<void> setJson(String key, Map<String, dynamic> value, {CachePolicy policy = const CachePolicy(ttl: Duration(hours: 12)) async {
    await setString(key, jsonEncode(value), policy: policy);
  }
  
  // ── Read ─────────────────────────────────
  String? getString(String key) {
    final raw = _prefs!.getString(key);
    if (raw == null) return null;
    
    try {
      final entry = _CacheEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (entry.isExpired) {
        remove(key);
        return null;
      }
      return entry.data;
    } catch (_) {
      return raw;
    }
  }
  
  Map<String, dynamic>? getJson(String key) {
    final raw = getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
  
  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs!.getBool(key) ?? defaultValue;
  
  // ── Remove ─────────────────────────────
  Future<void> remove(String key) async => await _prefs!.remove(key);
  
  Future<void> removeWhere(String prefix) async {
    final keys = _prefs!.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) await _prefs!.remove(k);
  }
  
  Future<void> clearAll() async => await _prefs!.clear();
}
EOF
  
  log_step "Generated: cache_manager.dart"
}

# ── Run All ───────────────────────────────────────────
generate_cache() {
  generate_cache_keys
  generate_cache_policy
  generate_cache_manager
  log_success "Generated cache layer"
}