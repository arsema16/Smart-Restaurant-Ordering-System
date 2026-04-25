import '../services/api_service.dart';
import '../models/menu_item_model.dart';

class MenuRepository {
  final ApiService _api;

  MenuRepository(this._api);

  /// Get all menu items grouped by category
  Future<MenuGroupedResponse> getMenu() async {
    final response = await _api.get('/menu');
    return MenuGroupedResponse.fromJson(response.data);
  }

  /// Get a single menu item by ID
  Future<MenuItemResponse> getMenuItem(int itemId) async {
    final response = await _api.get('/menu/$itemId');
    return MenuItemResponse.fromJson(response.data);
  }
}
