#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Services Generator - Navigation, storage, notifications
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/utils/file_ops.sh"

# ── Navigation Service ───────────────────────────────────
generate_navigation_service() {
  local out="${OUT_DIR}/lib/core/services/navigation_service.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter/material.dart';

/// Navigation service - app-wide navigation helper
class NavigationService {
  NavigationService._();
  static final NavigationService instance = NavigationService._();
  
  GlobalKey<NavigatorState>? _navigatorKey;
  
  /// Initialize - call once in main()
  void init() {
    _navigatorKey = GlobalKey<NavigatorState>();
  }
  
  GlobalKey<NavigatorState> get key => _navigatorKey!;
  
  /// Push page
  Future<T?> push<T>(Widget page) => _navigatorKey!.currentState!.push<T>(
    MaterialPageRoute(builder: (_) => page),
  );
  
  /// Push and replace
  Future<T?> pushReplacement<T>(Widget page) => _navigatorKey!.currentState!.pushReplacement<T>(
    MaterialPageRoute(builder: (_) => page),
  );
  
  /// Push and remove until
  Future<T?> pushAndRemoveUntil<T>(Widget page) => _navigatorKey!.currentState!.pushAndRemoveUntil<T>(
    MaterialPageRoute(builder: (_) => page),
    (route) => false,
  );
  
  /// Pop
  void pop<T>([T? result]) => _navigatorKey!.currentState!.pop(result);
  
  /// Pop to first
  void popToFirst() => _navigatorKey!.currentState!.popUntil((route) => route.isFirst);
  
  /// Check can pop
  bool canPop() => _navigatorKey!.currentState!.canPop();
}
EOF
  
  log_step "Generated: navigation_service.dart"
}

# ── Storage Service ───────────────────────────────────────
generate_storage_service() {
  local out="${OUT_DIR}/lib/core/services/storage_service.dart"
  
  cat > "$out" << 'EOF'
import 'package:shared_preferences/shared_preferences.dart';

/// Storage service - simple key-value storage
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();
  
  SharedPreferences? _prefs;
  
  /// Initialize - call once in main()
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  // ── String ─────────────────────────────────
  Future<void> setString(String key, String value) async => await _prefs!.setString(key, value);
  String? getString(String key) => _prefs!.getString(key);
  
  // ── Bool ─────────────────────────────────
  Future<void> setBool(String key, bool value) async => await _prefs!.setBool(key, value);
  bool? getBool(String key) => _prefs!.getBool(key);
  
  // ── Int ─────────────────────────────────
  Future<void> setInt(String key, int value) async => await _prefs!.setInt(key, value);
  int? getInt(String key) => _prefs!.getInt(key);
  
  // ── Double ─────────────────────────────
  Future<void> setDouble(String key, double value) async => await _prefs!.setDouble(key, value);
  double? getDouble(String key) => _prefs!.getDouble(key);
  
  // ── StringList ────────────────────────
  Future<void> setStringList(String key, List<String> value) async => await _prefs!.setStringList(key, value);
  List<String>? getStringList(String key) => _prefs!.getStringList(key);
  
  // ── Remove ───────────────────────────
  Future<void> remove(String key) async => await _prefs!.remove(key);
  Future<void> clear() async => await _prefs!.clear();
  
  // ── Check ───────────────────────────
  bool containsKey(String key) => _prefs!.containsKey(key);
}
EOF
  
  log_step "Generated: storage_service.dart"
}

# ── Notification Service ─────────────────────────────────
generate_notification_service() {
  local out="${OUT_DIR}/lib/core/services/notification_service.dart"
  
  cat > "$out" << 'EOF'
import 'package:firebase_messaging/firebase_messaging.dart';

/// Notification service - push notifications via FCM
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  
  /// Initialize - call once in main()
  Future<void> init() async {
    await _messaging.setAutoInitEnabled(true);
    FirebaseMessaging.onBackgroundMessage(_handleBackground);
    await _requestPermission();
  }
  
  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  
  /// Get FCM token
  Future<String?> getToken() => _messaging.getToken();
  
  /// Subscribe to topic
  Future<void> subscribe(String topic) => _messaging.subscribeToTopic(topic);
  
  /// Unsubscribe from topic
  Future<void> unsubscribe(String topic) => _messaging.unsubscribeFromTopic(topic);
  
  /// Handle background message
  static Future<void> _handleBackground(RemoteMessage message) async {
    print('📩 [BG] ${message.notification?.title}');
  }
}
EOF
  
  log_step "Generated: notification_service.dart"
}

# ── Run All ───────────────────────────────────────────
generate_services() {
  generate_navigation_service
  generate_storage_service
  generate_notification_service
  log_success "Generated services layer"
}