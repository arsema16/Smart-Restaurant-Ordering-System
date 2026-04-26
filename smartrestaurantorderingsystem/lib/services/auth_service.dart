import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';

/// Authentication service for staff login
class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  /// Staff login - returns JWT tokens
  Future<TokenResponse> login(String username, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: LoginRequest(username: username, password: password).toJson(),
    );
    
    final tokenResponse = TokenResponse.fromJson(response.data);
    
    // Store JWT token in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', tokenResponse.accessToken);
    await prefs.setString('refresh_token', tokenResponse.refreshToken);
    
    return tokenResponse;
  }

  /// Refresh JWT token
  Future<TokenResponse> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    
    if (refreshToken == null) {
      throw Exception('No refresh token found');
    }
    
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    
    final tokenResponse = TokenResponse.fromJson(response.data);
    
    // Update stored tokens
    await prefs.setString('jwt_token', tokenResponse.accessToken);
    await prefs.setString('refresh_token', tokenResponse.refreshToken);
    
    return tokenResponse;
  }

  /// Logout - clear stored tokens
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') != null;
  }

  /// Get stored JWT token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
}
