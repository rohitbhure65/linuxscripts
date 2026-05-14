#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Settings Feature Generator - App settings management
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/utils/file_ops.sh"

# ── Settings Repository ───────────────────────────────────
generate_settings_repository() {
  local out="${OUT_DIR}/lib/features/settings/data/settings_repository.dart"
  
  cat > "$out" << 'EOF'
import 'package:dio/dio.dart';
import 'package:${PROJECT_NAME}/core/network/api/api_client.dart';
import 'package:${PROJECT_NAME}/core/network/api/api_endpoints.dart';
import 'package:${PROJECT_NAME}/core/cache/cache_keys.dart';
import 'package:${PROJECT_NAME}/core/cache/cache_manager.dart';

/// Settings model
class Settings {
  const Settings({
    this.themeMode = 'system',
    this.locale = 'en',
    this.notifications = true,
    this.location = false,
  });
  
  final String themeMode;
  final String locale;
  final bool notifications;
  final bool location;
  
  Map<String, dynamic> toJson() => {
    'themeMode': themeMode,
    'locale': locale,
    'notifications': notifications,
    'location': location,
  };
  
  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
    themeMode: json['themeMode'] as String? ?? 'system',
    locale: json['locale'] as String? ?? 'en',
    notifications: json['notifications'] as bool? ?? true,
    location: json['location'] as bool? ?? false,
  );
  
  Settings copyWith({
    String? themeMode,
    String? locale,
    bool? notifications,
    bool? location,
  }) =>
      Settings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        notifications: notifications ?? this.notifications,
        location: location ?? this.location,
      );
}

/// Settings repository
class SettingsRepository {
  const SettingsRepository(this._client, this._cache);
  
  final ApiClient _client;
  final CacheManager _cache;
  
  /// Get settings (local first, then remote)
  Future<Settings> getSettings() async {
    final cached = _cache.getJson(CacheKeys.userSettings);
    if (cached != null) return Settings.fromJson(cached);
    
    final response = await _client.get(ApiEndpoints.settings);
    final settings = Settings.fromJson(response.data as Map<String, dynamic>);
    await _cache.setJson(CacheKeys.userSettings, settings.toJson());
    return settings;
  }
  
  /// Update settings
  Future<Settings> updateSettings(Settings settings) async {
    final response = await _client.patch(
      ApiEndpoints.settings,
      data: settings.toJson(),
    );
    final updated = Settings.fromJson(response.data as Map<String, dynamic>);
    await _cache.setJson(CacheKeys.userSettings, updated.toJson());
    return updated;
  }
  
  /// Clear settings
  Future<void> clearSettings() async {
    await _cache.remove(CacheKeys.userSettings);
  }
}
EOF
  
  log_step "Generated: settings_repository.dart"
}

# ── Settings BLoC ───────────────────────────────────────────
generate_settings_bloc() {
  local out="${OUT_DIR}/lib/features/settings/presentation/settings_bloc.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:${PROJECT_NAME}/features/settings/data/settings_repository.dart';

/// Settings events
abstract class SettingsEvent {
  const SettingsEvent();
}

class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

class SettingsUpdateRequested extends SettingsEvent {
  const SettingsUpdateRequested({required this.settings});
  final Settings settings;
}

class SettingsThemeChanged extends SettingsEvent {
  const SettingsThemeChanged({required this.themeMode});
  final String themeMode;
}

class SettingsLocaleChanged extends SettingsEvent {
  const SettingsLocaleChanged({required this.locale});
  final String locale;
}

class SettingsNotificationsToggled extends SettingsEvent {
  const SettingsNotificationsToggled({required this.enabled});
  final bool enabled;
}

/// Settings BLoC
class SettingsBloc extends Bloc<SettingsEvent, Settings> {
  SettingsBloc({required this.repository}) : super(const Settings()) {
    on<SettingsLoadRequested>(_onLoad);
    on<SettingsUpdateRequested>(_onUpdate);
    on<SettingsThemeChanged>(_onThemeChanged);
    on<SettingsLocaleChanged>(_onLocaleChanged);
    on<SettingsNotificationsToggled>(_onNotificationsToggled);
  }
  
  final SettingsRepository repository;
  
  Future<void> _onLoad(SettingsLoadRequested event, Emitter<Settings> emit) async {
    try {
      final settings = await repository.getSettings();
      emit(settings);
    } catch (_) {
      // Use defaults on error
    }
  }
  
  Future<void> _onUpdate(SettingsUpdateRequested event, Emitter<Settings> emit) async {
    try {
      final settings = await repository.updateSettings(event.settings);
      emit(settings);
    } catch (_) {
      // Handle error
    }
  }
  
  Future<void> _onThemeChanged(SettingsThemeChanged event, Emitter<Settings> emit) async {
    final updated = copyWith(themeMode: event.themeMode);
    add(SettingsUpdateRequested(settings: updated));
  }
  
  Future<void> _onLocaleChanged(SettingsLocaleChanged event, Emitter<Settings> emit) async {
    final updated = copyWith(locale: event.locale);
    add(SettingsUpdateRequested(settings: updated));
  }
  
  Future<void> _onNotificationsToggled(SettingsNotificationsToggled event, Emitter<Settings> emit) async {
    final updated = copyWith(notifications: event.enabled);
    add(SettingsUpdateRequested(settings: updated));
  }
}
EOF
  
  log_step "Generated: settings_bloc.dart"
}

# ── Settings Screen ───────────────────────────────────────
generate_settings_screen() {
  local out="${OUT_DIR}/lib/features/settings/presentation/settings_screen.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:${PROJECT_NAME}/features/settings/presentation/settings_bloc.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsBloc, Settings>(
        builder: (context, settings) {
          return ListView(
            children: [
              // Theme
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme'),
                subtitle: Text(settings.themeMode),
                onTap: () => _showThemeDialog(context),
              ),
              
              // Language
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(settings.locale),
                onTap: () => _showLanguageDialog(context),
              ),
              
              // Notifications
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                value: settings.notifications,
                onChanged: (enabled) {
                  context.read<SettingsBloc>().add(
                    SettingsNotificationsToggled(enabled: enabled),
                  );
                },
              ),
              
              // Location
              SwitchListTile(
                secondary: const Icon(Icons.location_on),
                title: const Text('Location Services'),
                value: settings.location,
                onChanged: (enabled) {
                  context.read<SettingsBloc>().add(
                    SettingsNotificationsToggled(enabled: enabled),
                  );
                },
              ),
              
              const Divider(),
              
              // About
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () => _showAbout(context),
              ),
              
              // Privacy
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                onTap: () {},
              ),
              
              // Terms
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System'),
              value: 'system',
              groupValue: 'system',
              onChanged: (_) {},
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: 'system',
              onChanged: (_) {},
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: 'system',
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }
  
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: 'en',
              onChanged: (_) {},
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'es',
              groupValue: 'en',
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'My App',
      applicationVersion: '1.0.0',
    );
  }
}
EOF
  
  log_step "Generated: settings_screen.dart"
}

# ── Run All ───────────────────────────────────────────
generate_settings() {
  generate_settings_repository
  generate_settings_bloc
  generate_settings_screen
  log_success "Generated settings feature"
}