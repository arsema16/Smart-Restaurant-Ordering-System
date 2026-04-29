import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API service for making HTTP requests to the backend
/// Configured with base URL `/api/v1` and handles authentication
class ApiService {
  late final Dio _dio;
  final String baseUrl;

  ApiService({
    required this.baseUrl,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api/v1',
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and token management
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add session token to headers if available
          final prefs = await SharedPreferences.getInstance();
          final sessionToken = prefs.getString('session_token');
          if (sessionToken != null) {
            options.headers['X-Session-Token'] = sessionToken;
          }

          // Add JWT token for staff endpoints
          final jwtToken = prefs.getString('jwt_token');
          if (jwtToken != null && options.path.startsWith('/staff')) {
            options.headers['Authorization'] = 'Bearer $jwtToken';
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 errors (invalid/expired tokens)
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('session_token');
            await prefs.remove('jwt_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
