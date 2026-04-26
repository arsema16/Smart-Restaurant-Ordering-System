import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../repositories/staff_order_repository.dart';
import 'api_provider.dart';

/// Staff order state notifier
class StaffOrderNotifier extends StateNotifier<AsyncValue<List<OrderResponse>>> {
  final StaffOrderRepository _repository;

  StaffOrderNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  /// Load active orders from API
  Future<void> loadOrders() async {
    state = const AsyncValue.loading();
    try {
      final orders = await _repository.getActiveOrders();
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final updatedOrder = await _repository.updateOrderStatus(orderId, newStatus);
      
      // Update in current state
      state.whenData((orders) {
        final updatedOrders = orders.map((order) {
          if (order.id == orderId) {
            return updatedOrder;
          }
          return order;
        }).toList();
        state = AsyncValue.data(updatedOrders);
      });
    } catch (e, stack) {
      // Show error but keep current state
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Add new order (from WebSocket)
  void addOrder(OrderResponse order) {
    state.whenData((orders) {
      state = AsyncValue.data([order, ...orders]);
    });
  }

  /// Update order from WebSocket event
  void updateOrderFromWebSocket(String orderId, OrderStatus newStatus) {
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

  /// Get orders by status
  List<OrderResponse> getOrdersByStatus(OrderStatus status) {
    return state.when(
      data: (orders) => orders.where((order) => order.status == status).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }
}

/// Provider for Staff Order Repository
final staffOrderRepositoryProvider = Provider<StaffOrderRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return StaffOrderRepository(api);
});

/// Provider for Staff Order State
final staffOrderProvider = StateNotifierProvider<StaffOrderNotifier, AsyncValue<List<OrderResponse>>>((ref) {
  final repository = ref.watch(staffOrderRepositoryProvider);
  return StaffOrderNotifier(repository);
});
