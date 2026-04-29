import '../services/api_service.dart';
import '../models/order_model.dart';

class OrderRepository {
  final ApiService _api;

  OrderRepository(this._api);

  /// Place an order from the current cart
  Future<OrderResponse> placeOrder() async {
    final response = await _api.post('/orders');
    return OrderResponse.fromJson(response.data);
  }

  /// Get all orders for the current session
  Future<List<OrderResponse>> getOrders() async {
    final response = await _api.get('/orders');
    return (response.data as List)
        .map((order) => OrderResponse.fromJson(order))
        .toList();
  }

  /// Get a single order by ID
  Future<OrderResponse> getOrder(String orderId) async {
    final response = await _api.get('/orders/$orderId');
    return OrderResponse.fromJson(response.data);
  }}
