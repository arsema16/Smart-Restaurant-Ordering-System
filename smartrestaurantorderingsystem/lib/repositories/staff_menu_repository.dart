import '../services/api_service.dart';
import '../models/menu_item_model.dart';

class StaffMenuRepository {
  final ApiService _api;

  StaffMenuRepository(this._api);

  /// Get all menu items (including unavailable)
  Future<List<MenuItemResponse>> getAllMenuItems() async {
    final response = await _api.get('/staff/menu');
    return (response.data as List)
        .map((item) => MenuItemResponse.fromJson(item))
        .toList();
  }

  /// Create menu item (admin only)
  Future<MenuItemResponse> createMenuItem(MenuItemCreate item) async {
    final response = await _api.post('/staff/menu', data: item.toJson());
    return MenuItemResponse.fromJson(response.data);
  }

  /// Update menu item
  Future<MenuItemResponse> updateMenuItem(int itemId, MenuItemUpdate update) async {
    final response = await _api.put('/staff/menu/$itemId', data: update.toJson());
    return MenuItemResponse.fromJson(response.data);
  }

  /// Toggle menu item availability
  Future<MenuItemResponse> toggleAvailability(int itemId, bool isAvailable) async {
    final response = await _api.patch(
      '/staff/menu/$itemId/availability',
      data: {'is_available': isAvailable},
    );
    return MenuItemResponse.fromJson(response.data);
  }
}
