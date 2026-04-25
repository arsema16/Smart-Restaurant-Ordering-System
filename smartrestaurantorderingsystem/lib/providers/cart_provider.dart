import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';

/// Cart state notifier
class CartNotifier extends StateNotifier<CartResponse?> {
  CartNotifier() : super(null);

  /// Update cart with response from API
  void updateCart(CartResponse cart) {
    state = cart;
  }

  /// Clear cart
  void clearCart() {
    state = null;
  }

  /// Get total price
  double get totalPrice => state?.totalPrice ?? 0.0;

  /// Get item count
  int get itemCount => state?.items.length ?? 0;
}

final cartProvider = StateNotifierProvider<CartNotifier, CartResponse?>((ref) {
  return CartNotifier();
});