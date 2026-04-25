/// API configuration constants
class ApiConstants {
  // Base URL for the backend API
  // Change this to your backend server URL
  static const String baseUrl = 'http://localhost:8000';

  // API version prefix
  static const String apiVersion = '/api/v1';

  // Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  // WebSocket base URL
  static String get wsBaseUrl => baseUrl.replaceFirst('http', 'ws');

  // Endpoints
  static const String sessions = '/sessions';
  static const String menu = '/menu';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String recommendations = '/recommendations';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String staffOrders = '/staff/orders';
  static const String staffMenu = '/staff/menu';

  // WebSocket endpoints
  static String guestWebSocket(String sessionId) => '/ws/guest/$sessionId';
  static const String staffWebSocket = '/ws/staff';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // WebSocket
  static const Duration pingInterval = Duration(seconds: 30);
  static const int maxReconnectDelay = 30; // seconds
}
