import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';
import '../repositories/staff_menu_repository.dart';
import 'api_provider.dart';

/// Staff menu state notifier
class StaffMenuNotifier extends StateNotifier<AsyncValue<List<MenuItemResponse>>> {
  final StaffMenuRepository _repository;

  StaffMenuNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMenuItems();
  }

  /// Load all menu items
  Future<void> loadMenuItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getAllMenuItems();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create menu item
  Future<void> createMenuItem(MenuItemCreate item) async {
    try {
      final newItem = await _repository.createMenuItem(item);
      
      state.whenData((items) {
        state = AsyncValue.data([...items, newItem]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Update menu item
  Future<void> updateMenuItem(int itemId, MenuItemUpdate update) async {
    try {
      final updatedItem = await _repository.updateMenuItem(itemId, update);
      
      state.whenData((items) {
        final updatedItems = items.map((item) {
          if (item.id == itemId) {
            return updatedItem;
          }
          return item;
        }).toList();
        state = AsyncValue.data(updatedItems);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Toggle availability
  Future<void> toggleAvailability(int itemId, bool isAvailable) async {
    try {
      final updatedItem = await _repository.toggleAvailability(itemId, isAvailable);
      
      state.whenData((items) {
        final updatedItems = items.map((item) {
          if (item.id == itemId) {
            return updatedItem;
          }
          return item;
        }).toList();
        state = AsyncValue.data(updatedItems);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider for Staff Menu Repository
final staffMenuRepositoryProvider = Provider<StaffMenuRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return StaffMenuRepository(api);
});

/// Provider for Staff Menu State
final staffMenuProvider = StateNotifierProvider<StaffMenuNotifier, AsyncValue<List<MenuItemResponse>>>((ref) {
  final repository = ref.watch(staffMenuRepositoryProvider);
  return StaffMenuNotifier(repository);
});
