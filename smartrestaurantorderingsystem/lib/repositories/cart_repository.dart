import '../services/api_service.dart';
import '../models/cart_item_model.dart';

class CartRepository {
  final ApiService _api;

  CartRepository(this._api);

  /// Get current cart
  Future<CartResponse> getCart() async {
    final response = await _api.get('/cart');
    return CartResponse.fromJson(response.data);
  }

  /// Add item to cart
  Future<CartResponse> addItem(CartItemAdd item) async {
    final response = await _api.post('/cart/items', data: item.toJson());
    return CartResponse.fromJson(response.data);
  }

  /// Update item quantity
  Future<CartResponse> updateItemQuantity(int menuItemId, int quantity) async {
    final response = await _api.patch(
      '/cart/items/$menuItemId',
      data: CartItemUpdate(quantity: quantity).toJson(),
    );
    return CartResponse.fromJson(response.data);
  }

  /// Remove item from cart
  Future<CartResponse> removeItem(int menuItemId) async {
    final response = await _api.delete('/cart/items/$menuItemId');
    return CartResponse.fromJson(response.data);
  }
}
