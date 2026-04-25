import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WebSocket event types
enum WebSocketEventType {
  orderCreated,
  orderStatusUpdated,
  menuItemAvailabilityChanged,
  cartItemRemovedUnavailable,
  ping,
  pong,
  error,
}

/// WebSocket event model
class WebSocketEvent {
  final WebSocketEventType event;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  WebSocketEvent({
    required this.event,
    required this.payload,
    required this.timestamp,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      event: _parseEventType(json['event'] as String),
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  static WebSocketEventType _parseEventType(String eventString) {
    switch (eventString) {
      case 'order_created':
        return WebSocketEventType.orderCreated;
      case 'order_status_updated':
        return WebSocketEventType.orderStatusUpdated;
      case 'menu_item_availability_changed':
        return WebSocketEventType.menuItemAvailabilityChanged;
      case 'cart_item_removed_unavailable':
        return WebSocketEventType.cartItemRemovedUnavailable;
      case 'ping':
        return WebSocketEventType.ping;
      case 'pong':
        return WebSocketEventType.pong;
      case 'error':
        return WebSocketEventType.error;
      default:
        throw ArgumentError('Unknown event type: $eventString');
    }
  }
}

/// WebSocket connection manager for real-time updates
class WebSocketService {
  final String baseUrl;
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectDelay = 30; // seconds

  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();

  Stream<WebSocketEvent> get eventStream => _eventController.stream;

  bool get isConnected => _channel != null;

  WebSocketService({required this.baseUrl});

  /// Connect to guest WebSocket endpoint
  Future<void> connectGuest(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionToken = prefs.getString('session_token');

    if (sessionToken == null) {
      throw Exception('Session token not found');
    }

    final wsUrl = baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsUrl/api/v1/ws/guest/$sessionId?token=$sessionToken');

    await _connect(uri);
  }

  /// Connect to staff WebSocket endpoint
  Future<void> connectStaff() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');

    if (jwtToken == null) {
      throw Exception('JWT token not found');
    }

    final wsUrl = baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsUrl/api/v1/ws/staff?token=$jwtToken');

    await _connect(uri);
  }

  /// Internal connection method
  Future<void> _connect(Uri uri) async {
    try {
      _channel = WebSocketChannel.connect(uri);

      // Listen to incoming messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
          _reconnectAttempts = 0; // Reset on successful message
        },
        onError: (error) {
          _handleError(error);
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      // Start ping/pong keepalive (every 30 seconds)
      _startPingTimer();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final event = WebSocketEvent.fromJson(json);

      // Respond to ping with pong
      if (event.event == WebSocketEventType.ping) {
        _sendPong();
      }

      _eventController.add(event);
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _eventController.addError(error);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    print('WebSocket disconnected');
    _pingTimer?.cancel();
    _channel = null;
    _scheduleReconnect();
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    // Exponential backoff: 1s, 2s, 4s, 8s, max 30s
    final delay = (1 << _reconnectAttempts).clamp(1, _maxReconnectDelay);
    _reconnectAttempts++;

    print('Reconnecting in $delay seconds (attempt $_reconnectAttempts)...');

    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      // Attempt to reconnect (caller needs to provide session/staff context)
      // This is a simplified version - in practice, you'd store connection type
      print('Attempting to reconnect...');
    });
  }

  /// Start ping timer for keepalive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendPing();
    });
  }

  /// Send ping message
  void _sendPing() {
    if (_channel != null) {
      final message = jsonEncode({
        'event': 'ping',
        'payload': {},
        'timestamp': DateTime.now().toIso8601String(),
      });
      _channel!.sink.add(message);
    }
  }

  /// Send pong message
  void _sendPong() {
    if (_channel != null) {
      final message = jsonEncode({
        'event': 'pong',
        'payload': {},
        'timestamp': DateTime.now().toIso8601String(),
      });
      _channel!.sink.add(message);
    }
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _eventController.close();
  }
}
