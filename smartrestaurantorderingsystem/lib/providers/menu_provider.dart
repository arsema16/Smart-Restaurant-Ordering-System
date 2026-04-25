import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';

/// Menu state notifier
class MenuNotifier extends StateNotifier<MenuGroupedResponse?> {
  MenuNotifier() : super(null);

  /// Update menu with response from API
  void updateMenu(MenuGroupedResponse menu) {
    state = menu;
  }

  /// Get all items as flat list
  List<MenuItemResponse> get allItems {
    if (state == null) return [];
    return state!.categories.values.expand((items) => items).toList();
  }

  /// Get items by category
  List<MenuItemResponse> getItemsByCategory(String category) {
    return state?.categories[category] ?? [];
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuGroupedResponse?>((ref) {
  return MenuNotifier();
});