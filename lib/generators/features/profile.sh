#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# Profile Feature Generator - User profile management
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/utils/file_ops.sh"

# ── Profile Repository ───────────────────────────────────
generate_profile_repository() {
  local out="${OUT_DIR}/lib/features/profile/data/profile_repository.dart"
  
  cat > "$out" << 'EOF'
import 'package:dio/dio.dart';
import 'package:${PROJECT_NAME}/core/network/api/api_client.dart';
import 'package:${PROJECT_NAME}/core/network/api/api_endpoints.dart';
import 'package:${PROJECT_NAME}/features/auth/data/auth_state.dart';

/// Profile repository - user profile CRUD
class ProfileRepository {
  const ProfileRepository(this._client);
  
  final ApiClient _client;
  
  /// Get user profile
  Future<User> getProfile() async {
    final response = await _client.get(ApiEndpoints.profile);
    return User.fromJson(response.data as Map<String, dynamic>);
  }
  
  /// Update profile
  Future<User> updateProfile({
    String? name,
    String? photoUrl,
    String? phone,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (phone != null) data['phone'] = phone;
    
    final response = await _client.patch(ApiEndpoints.profile, data: data);
    return User.fromJson(response.data as Map<String, dynamic>);
  }
  
  /// Update password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.patch(
      '${ApiEndpoints.profile}/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
  
  /// Delete account
  Future<void> deleteAccount() async {
    await _client.delete(ApiEndpoints.profile);
  }
}
EOF
  
  log_step "Generated: profile_repository.dart"
}

# ── Profile BLoC ───────────────────────────────────────
generate_profile_bloc() {
  local out="${OUT_DIR}/lib/features/profile/presentation/profile_bloc.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:${PROJECT_NAME}/features/auth/data/auth_state.dart';
import 'package:${PROJECT_NAME}/features/profile/data/profile_repository.dart';

/// Profile events
abstract class ProfileEvent {
  const ProfileEvent();
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested({this.name, this.photoUrl, this.phone});
  final String? name;
  final String? photoUrl;
  final String? phone;
}

/// Profile state
class ProfileState {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.error,
  });
  
  final ProfileStatus status;
  final User? user;
  final String? error;
  
  bool get isLoading => status == ProfileStatus.loading;
  bool get isSuccess => status == ProfileStatus.success;
  
  ProfileState copyWith({
    ProfileStatus? status,
    User? user,
    String? error,
  }) =>
      ProfileState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error ?? this.error,
      );
}

enum ProfileStatus {
  initial,
  loading,
  success,
  failure,
}

/// Profile BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required this.repository}) : super(const ProfileState()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
  }
  
  final ProfileRepository repository;
  
  Future<void> _onLoad(ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    
    try {
      final user = await repository.getProfile();
      emit(state.copyWith(status: ProfileStatus.success, user: user));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: e.toString()));
    }
  }
  
  Future<void> _onUpdate(ProfileUpdateRequested event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    
    try {
      final user = await repository.updateProfile(
        name: event.name,
        photoUrl: event.photoUrl,
        phone: event.phone,
      );
      emit(state.copyWith(status: ProfileStatus.success, user: user));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: e.toString()));
    }
  }
}
EOF
  
  log_step "Generated: profile_bloc.dart"
}

# ── Profile Screen ───────────────────────────────────────
generate_profile_screen() {
  local out="${OUT_DIR}/lib/features/profile/presentation/profile_screen.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:${PROJECT_NAME}/features/profile/presentation/profile_bloc.dart';

/// Profile screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editProfile(context),
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final user = state.user;
          if (user == null) {
            return const Center(child: Text('No profile data'));
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  user.name ?? 'No name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _editProfile(BuildContext context) {
    // Navigate to edit screen
  }
}
EOF
  
  log_step "Generated: profile_screen.dart"
}

# ── Run All ───────────────────────────────────────────
generate_profile() {
  generate_profile_repository
  generate_profile_bloc
  generate_profile_screen
  log_success "Generated profile feature"
}