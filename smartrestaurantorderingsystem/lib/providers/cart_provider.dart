import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(MenuItem item) {
    final index = state.indexWhere((e) => e.id == item.id);

    if (index >= 0) {
      state[index].quantity++;
      state = [...state];
    } else {
      state = [
        ...state,
        CartItem(
          id: item.id,
          name: item.name,
          price: item.price,
        )
      ];
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  double get totalPrice {
    return state.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});