import '../services/api_service.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  /// Staff login
  Future<TokenResponse> login(String username, String password) async {
    final response = await _api.post(
      '/auth/login',
      data: LoginRequest(username: username, password: password).toJson(),
    );
    return TokenResponse.fromJson(response.data);
  }

  /// Refresh JWT token
  Future<TokenResponse> refreshToken(String refreshToken) async {
    final response = await _api.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return TokenResponse.fromJson(response.data);
  }
}
