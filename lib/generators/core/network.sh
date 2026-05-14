#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# Network Generator - API client, interceptors
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/utils/file_ops.sh"

# ── API Client (Dio) ───────────────────────────────────────
generate_api_client() {
  local out="${OUT_DIR}/lib/core/network/api/api_client.dart"
  
  cat > "$out" << 'EOF'
import 'package:dio/dio.dart';
import 'package:${PROJECT_NAME}/core/constants/app_api.dart';

/// API client using Dio with retry, interceptors
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  
  late final Dio _dio;
  
  /// Initialize - call once in main()
  void init({String? baseUrl, String? token}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? AppApi.baseUrl,
      connectTimeout: AppApi.connectTimeout,
      receiveTimeout: AppApi.receiveTimeout,
      headers: {
        AppApi.headerContentType: AppApi.valueJson,
        AppApi.headerAccept: AppApi.valueJson,
      },
    ));
    
    _dio.interceptors.addAll([
      LoggingInterceptor(),
      RetryInterceptor(),
    ]);
  }
  
  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    Options? options,
  }) =>
      _dio.get(path, queryParameters: queryParams, options: options);
  
  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) =>
      _dio.post(path, data: data, queryParameters: queryParams, options: options);
  
  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) =>
      _dio.put(path, data: data, queryParameters: queryParams, options: options);
  
  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) =>
      _dio.patch(path, data: data, queryParameters: queryParams, options: options);
  
  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) =>
      _dio.delete(path, data: data, queryParameters: queryParams, options: options);
}

/// Logging interceptor
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('➡️  ${options.method} ${options.path}');
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('⬅️  ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌  ${err.response?.statusCode} ${err.requestOptions.path}');
    handler.next(err);
  }
}

/// Retry interceptor
class RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
    
    if (_shouldRetry(err) && retryCount < AppApi.maxRetries) {
      await Future.delayed(Duration(milliseconds: AppApi.retryDelayMs));
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      handler.resolve(await _dio.fetch(err.requestOptions));
    } else {
      handler.next(err);
    }
  }
  
  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response?.statusCode ?? 0) >= 500;
  }
}
EOF
  
  log_step "Generated: api_client.dart"
}

# ── API Endpoints ─────────────────────────────────────────
generate_api_endpoints() {
  local out="${OUT_DIR}/lib/core/network/api/api_endpoints.dart"
  
  cat > "$out" << 'EOF'
/// API endpoints - all endpoint paths
abstract class ApiEndpoints {
  // ── Auth ─────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  
  // ── User ───────────────────────────────────
  static const String profile = '/user/profile';
  static const String users = '/users';
  
  // ── Settings ────────────────────────────────
  static const String settings = '/settings';
  
  // ── Upload ────────────────────────────────
  static const String upload = '/upload';
}
EOF
  
  log_step "Generated: api_endpoints.dart"
}

# ── Connectivity ───────────────────────────────────────
generate_connectivity() {
  local out="${OUT_DIR}/lib/core/network/connectivity/connectivity_service.dart"
  
  cat > "$out" << 'EOF'
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity service - network status monitoring
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();
  
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  
  Stream<bool> get stream => _controller.stream;
  
  /// Initialize - call once in main()
  void init() {
    _connectivity.onConnectivityChanged.listen((results) {
      _controller.add(_isConnected(results));
    });
  }
  
  /// Check current connectivity
  Future<bool> check() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }
  
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
  
  void dispose() => _controller.close();
}
EOF
  
  log_step "Generated: connectivity_service.dart"
}

# ── Run All ───────────────────────────────────────────
generate_network() {
  generate_api_client
  generate_api_endpoints
  generate_connectivity
  log_success "Generated network layer"
}