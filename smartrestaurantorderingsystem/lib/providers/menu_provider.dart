import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../models/menu_item_model.dart';
final apiServiceProvider = Provider((ref) => ApiService());
final menuProvider = FutureProvider<List<MenuItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);

  final data = await api.fetchMenu();

  return data.map<MenuItem>((e) => MenuItem.fromJson(e)).toList();
});