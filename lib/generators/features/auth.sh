#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Auth Feature Generator - Login, register, auth state
# ═══════════════════════════════════════════════════════════════════════

source "${LIB_DIR}/utils/file_ops.sh"

# ── Auth State ───────────────────────────────────────────
generate_auth_state() {
  local out="${OUT_DIR}/lib/features/auth/data/auth_state.dart"
  
  cat > "$out" << 'EOF'
/// Auth state - current user and auth status
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

/// Auth state holder
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });
  
  final AuthStatus status;
  final User? user;
  final String? error;
  
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error ?? this.error,
      );
}

/// User model
class User {
  const User({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.createdAt,
  });
  
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final DateTime? createdAt;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'photoUrl': photoUrl,
    'createdAt': createdAt?.toIso8601String(),
  };
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String?,
    photoUrl: json['photoUrl'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
  );
}
EOF
  
  log_step "Generated: auth_state.dart"
}

# ── Auth Repository ───────────────────────────────────────
generate_auth_repository() {
  local out="${OUT_DIR}/lib/features/auth/data/auth_repository.dart"
  
  cat > "$out" << 'EOF'
import 'package:dio/dio.dart';
import 'package:${PROJECT_NAME}/core/network/api/api_client.dart';
import 'package:${PROJECT_NAME}/core/network/api/api_endpoints.dart';
import 'package:${PROJECT_NAME}/core/cache/cache_keys.dart';
import 'package:${PROJECT_NAME}/core/cache/cache_manager.dart';
import 'package:${PROJECT_NAME}/features/auth/data/auth_state.dart';

/// Auth repository - login, register, logout
class AuthRepository {
  const AuthRepository(this._client, this._cache);
  
  final ApiClient _client;
  final CacheManager _cache;
  
  /// Login with email/password
  Future<User> login(String email, String password) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    
    final token = response.data['token'] as String;
    await _cache.setString(CacheKeys.authToken, token);
    
    return User.fromJson(response.data['user'] as Map<String, dynamic>);
  }
  
  /// Register new user
  Future<User> register(String email, String password, String? name) async {
    final response = await _client.post(
      ApiEndpoints.register,
      data: {'email': email, 'password': password, 'name': name},
    );
    
    final token = response.data['token'] as String;
    await _cache.setString(CacheKeys.authToken, token);
    
    return User.fromJson(response.data['user'] as Map<String, dynamic>);
  }
  
  /// Logout
  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout);
    } finally {
      await _cache.remove(CacheKeys.authToken);
      await _cache.remove(CacheKeys.refreshToken);
    }
  }
  
  /// Get current user
  Future<User?> getCurrentUser() async {
    final token = _cache.getString(CacheKeys.authToken);
    if (token == null) return null;
    
    final response = await _client.get(ApiEndpoints.profile);
    return User.fromJson(response.data as Map<String, dynamic>);
  }
  
  /// Check if logged in
  Future<bool> isLoggedIn() async {
    final token = _cache.getString(CacheKeys.authToken);
    return token != null;
  }
}
EOF
  
  log_step "Generated: auth_repository.dart"
}

# ── Auth BLoC ───────────────────────────────────────────
generate_auth_bloc() {
  local out="${OUT_DIR}/lib/features/auth/presentation/auth_bloc.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:${PROJECT_NAME}/features/auth/data/auth_state.dart';
import 'package:${PROJECT_NAME}/features/auth/data/auth_repository.dart';

/// Auth events
abstract class AuthEvent {
  const AuthEvent();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});
  final String email;
  final String password;
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Auth BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this.repository}) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
  }
  
  final AuthRepository repository;
  
  Future<void> _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    try {
      final user = await repository.getCurrentUser();
      emit(state.copyWith(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }
  
  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    
    try {
      final user = await repository.login(event.email, event.password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, error: e.toString()));
    }
  }
  
  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
EOF
  
  log_step "Generated: auth_bloc.dart"
}

# ── Login Screen ───────────────────────────────────────────
generate_login_screen() {
  local out="${OUT_DIR}/lib/features/auth/presentation/login_screen.dart"
  
  cat > "$out" << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:${PROJECT_NAME}/features/auth/presentation/auth_bloc.dart';
import 'package:${PROJECT_NAME}/core/constants/app_colors.dart';

/// Login screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error ?? 'Login failed')),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome Back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Please enter email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Please enter password' : null,
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.isLoading
                              ? null
                              : () => _login(context),
                          child: state.isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Login'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _login(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthLoginRequested(
        email: _emailController.text,
        password: _passwordController.text,
      ));
    }
  }
}
EOF
  
  log_step "Generated: login_screen.dart"
}

# ── Run All ────────���─���────────────────────────────────
generate_auth() {
  generate_auth_state
  generate_auth_repository
  generate_auth_bloc
  generate_login_screen
  log_success "Generated auth feature"
}