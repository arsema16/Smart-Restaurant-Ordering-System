import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';
import '../repositories/menu_repository.dart';
import 'api_provider.dart';

/// Menu state notifier
class MenuNotifier extends StateNotifier<AsyncValue<MenuGroupedResponse>> {
  final MenuRepository _repository;

  MenuNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMenu();
  }

  /// Load menu from API
  Future<void> loadMenu() async {
    state = const AsyncValue.loading();
    try {
      final menu = await _repository.getMenu();
      state = AsyncValue.data(menu);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Get all items as flat list
  List<MenuItemResponse> get allItems {
    return state.when(
      data: (menu) => menu.categories.values.expand((items) => items).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Get items by category
  List<MenuItemResponse> getItemsByCategory(String category) {
    return state.when(
      data: (menu) => menu.categories[category] ?? [],
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Get available categories
  List<String> get categories {
    return state.when(
      data: (menu) => menu.categories.keys.toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, AsyncValue<MenuGroupedResponse>>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  return MenuNotifier(repository);
});