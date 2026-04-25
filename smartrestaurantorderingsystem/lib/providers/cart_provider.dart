import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../repositories/cart_repository.dart';
import 'api_provider.dart';

/// Cart state notifier
class CartNotifier extends StateNotifier<AsyncValue<CartResponse>> {
  final CartRepository _repository;

  CartNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCart();
  }

  /// Load cart from API
  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      final cart = await _repository.getCart();
      state = AsyncValue.data(cart);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Add item to cart
  Future<void> addItem(int menuItemId, int quantity) async {
    try {
      final cart = await _repository.addItem(
        CartItemAdd(menuItemId: menuItemId, quantity: quantity),
      );
      state = AsyncValue.data(cart);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(int menuItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeItem(menuItemId);
        return;
      }
      final cart = await _repository.updateItemQuantity(menuItemId, quantity);
      state = AsyncValue.data(cart);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Remove item from cart
  Future<void> removeItem(int menuItemId) async {
    try {
      final cart = await _repository.removeItem(menuItemId);
      state = AsyncValue.data(cart);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Get total price
  double get totalPrice {
    return state.when(
      data: (cart) => cart.totalPrice,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
  }

  /// Get item count
  int get itemCount {
    return state.when(
      data: (cart) => cart.items.length,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<CartResponse>>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return CartNotifier(repository);
});