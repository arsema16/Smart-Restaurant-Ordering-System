import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';
import 'api_provider.dart';

/// Order state notifier
class OrderNotifier extends StateNotifier<AsyncValue<List<OrderResponse>>> {
  final OrderRepository _repository;

  OrderNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  /// Load orders from API
  Future<void> loadOrders() async {
    state = const AsyncValue.loading();
    try {
      final orders = await _repository.getOrders();
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Place a new order
  Future<OrderResponse> placeOrder() async {
    try {
      final order = await _repository.placeOrder();
      
      // Add to current state
      state.whenData((orders) {
        state = AsyncValue.data([...orders, order]);
      });
      
      return order;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Update order status (from WebSocket)
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    state.whenData((orders) {
      final updatedOrders = orders.map((order) {
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
      state = AsyncValue.data(updatedOrders);
    });
  }

  /// Get active orders (not delivered)
  List<OrderResponse> get activeOrders {
    return state.when(
      data: (orders) => orders.where((order) => order.status != OrderStatus.delivered).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Get delivered orders
  List<OrderResponse> get deliveredOrders {
    return state.when(
      data: (orders) => orders.where((order) => order.status == OrderStatus.delivered).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<List<OrderResponse>>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrderNotifier(repository);
});

