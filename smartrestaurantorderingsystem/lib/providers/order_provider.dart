import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';

/// Order state notifier
class OrderNotifier extends StateNotifier<List<OrderResponse>> {
  OrderNotifier() : super([]);

  /// Update orders with response from API
  void updateOrders(List<OrderResponse> orders) {
    state = orders;
  }

  /// Add a new order
  void addOrder(OrderResponse order) {
    state = [...state, order];
  }

  /// Update order status
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    state = state.map((order) {
      if (order.id == orderId) {
        return OrderResponse(
          id: order.id,
          orderNumber: order.orderNumber,
          status: newStatus,
          items: order.items,
          estimatedWaitMinutes: order.estimatedWaitMinutes,
          createdAt: order.createdAt,
        );
      }
      return order;
    }).toList();
  }

  /// Clear orders
  void clearOrders() {
    state = [];
  }

  /// Get active orders (not delivered)
  List<OrderResponse> get activeOrders {
    return state.where((order) => order.status != OrderStatus.delivered).toList();
  }

  /// Get delivered orders
  List<OrderResponse> get deliveredOrders {
    return state.where((order) => order.status == OrderStatus.delivered).toList();
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderResponse>>((ref) {
  return OrderNotifier();
});
