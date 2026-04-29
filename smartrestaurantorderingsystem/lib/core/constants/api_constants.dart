import 'package:flutter/foundation.dart' show kIsWeb;

/// API configuration constants
class ApiConstants {
  // ─── PRODUCTION URL ────────────────────────────────────────────────────────
  // Set this to your Railway backend URL after deploying.
  // Leave empty to use the auto-detected URL (same host, port 8000).
  static const String _productionBackendUrl = 'https://smart-restaurant-ordering-system-kos8.onrender.com';
  // ───────────────────────────────────────────────────────────────────────────

  /// Returns the backend base URL.
  /// • If [_productionBackendUrl] is set → use it (production deployment).
  /// • On web → use the same host the Flutter app was served from, port 8000.
  /// • On native → fall back to the PC's LAN IP.
  static String get baseUrl {
    if (_productionBackendUrl.isNotEmpty) {
      return _productionBackendUrl;
    }
    if (kIsWeb) {
      final host = Uri.base.host;
      final scheme = Uri.base.scheme;
      return '$scheme://$host:8000';
    }
    // Native fallback
    return 'http://10.163.23.62:8000';
  }

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
