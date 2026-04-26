import '../services/api_service.dart';
import '../models/order_model.dart';

class StaffOrderRepository {
  final ApiService _api;

  StaffOrderRepository(this._api);

  /// Get all active orders (staff view)
  Future<List<OrderResponse>> getActiveOrders() async {
    final response = await _api.get('/staff/orders');
    return (response.data as List)
        .map((order) => OrderResponse.fromJson(order))
        .toList();
  }

  /// Update order status
  Future<OrderResponse> updateOrderStatus(String orderId, OrderStatus status) async {
    final response = await _api.patch(
      '/staff/orders/$orderId/status',
      data: OrderStatusUpdate(status: status).toJson(),
    );
    return OrderResponse.fromJson(response.data);
  }
}
