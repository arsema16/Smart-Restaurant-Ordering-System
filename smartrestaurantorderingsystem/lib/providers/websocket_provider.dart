import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';
import '../core/constants/api_constants.dart';
import '../models/order_model.dart';
import 'session_provider.dart';
import 'order_provider.dart';
import 'menu_provider.dart';
import 'cart_provider.dart';

/// WebSocket connection state
class WebSocketState {
  final bool isConnected;
  final String? error;

  WebSocketState({
    required this.isConnected,
    this.error,
  });
}

/// WebSocket state notifier
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final WebSocketService _service;
  final Ref _ref;

  WebSocketNotifier(this._service, this._ref)
      : super(WebSocketState(isConnected: false)) {
    _listenToEvents();
  }

  /// Connect as guest
  Future<void> connectGuest() async {
    try {
      final session = _ref.read(sessionProvider);
      if (session == null) {
        throw Exception('No active session');
      }

      await _service.connectGuest(session.sessionId);
      state = WebSocketState(isConnected: true);
    } catch (e) {
      state = WebSocketState(isConnected: false, error: e.toString());
    }
  }

  /// Connect as staff
  Future<void> connectStaff() async {
    try {
      await _service.connectStaff();
      state = WebSocketState(isConnected: true);
    } catch (e) {
      state = WebSocketState(isConnected: false, error: e.toString());
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    await _service.disconnect();
    state = WebSocketState(isConnected: false);
  }

  /// Listen to WebSocket events and update providers
  void _listenToEvents() {
    _service.eventStream.listen((event) {
      switch (event.event) {
        case WebSocketEventType.orderStatusUpdated:
          _handleOrderStatusUpdate(event.payload);
          break;
        case WebSocketEventType.menuItemAvailabilityChanged:
          _handleMenuAvailabilityChange(event.payload);
          break;
        case WebSocketEventType.cartItemRemovedUnavailable:
          _handleCartItemRemoved(event.payload);
          break;
        case WebSocketEventType.orderCreated:
          // Staff only - reload orders
          _ref.read(orderProvider.notifier).loadOrders();
          break;
        default:
          break;
      }
    });
  }

  /// Handle order status update event
  void _handleOrderStatusUpdate(Map<String, dynamic> payload) {
    final orderId = payload['order_id'] as String;
    final newStatus = OrderStatus.fromJson(payload['new_status'] as String);
    
    _ref.read(orderProvider.notifier).updateOrderStatus(orderId, newStatus);
  }

  /// Handle menu availability change event
  void _handleMenuAvailabilityChange(Map<String, dynamic> payload) {
    // Reload menu to get updated availability
    _ref.read(menuProvider.notifier).loadMenu();
  }

  /// Handle cart item removed event
  void _handleCartItemRemoved(Map<String, dynamic> payload) {
    final itemName = payload['item_name'] as String;
    
    // Reload cart to reflect removal
    _ref.read(cartProvider.notifier).loadCart();
    
    // Could also show a notification here
    print('Item removed from cart: $itemName');
  }
}

/// Provider for WebSocket service
final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(baseUrl: ApiConstants.baseUrl);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider for WebSocket state
final websocketProvider = StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
  final service = ref.watch(websocketServiceProvider);
  return WebSocketNotifier(service, ref);
});

