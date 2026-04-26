import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import 'api_provider.dart';

/// Auth state
class AuthState {
  final bool isAuthenticated;
  final String? error;
  final bool isLoading;

  AuthState({
    required this.isAuthenticated,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState(isAuthenticated: false)) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    state = AuthState(isAuthenticated: token != null);
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final tokenResponse = await _repository.login(username, password);
      
      // Store tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', tokenResponse.accessToken);
      await prefs.setString('refresh_token', tokenResponse.refreshToken);
      
      state = AuthState(isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
    state = AuthState(isAuthenticated: false);
  }

  /// Refresh token
  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) {
        state = AuthState(isAuthenticated: false);
        return false;
      }
      
      final tokenResponse = await _repository.refreshToken(refreshToken);
      
      // Update stored tokens
      await prefs.setString('jwt_token', tokenResponse.accessToken);
      await prefs.setString('refresh_token', tokenResponse.refreshToken);
      
      state = AuthState(isAuthenticated: true);
      return true;
    } catch (e) {
      state = AuthState(isAuthenticated: false, error: e.toString());
      return false;
    }
  }
}

/// Provider for Auth Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AuthRepository(api);
});

/// Provider for Auth State
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
