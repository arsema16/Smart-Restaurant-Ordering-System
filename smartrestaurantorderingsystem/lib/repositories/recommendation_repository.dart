import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartrestaurantorderingsystem/providers/menu_provider.dart' hide apiServiceProvider;
import 'package:smartrestaurantorderingsystem/providers/session_provider.dart';
import '../core/services/api_service.dart';
import '../models/menu_item_model.dart';

final recommendationProvider =
    FutureProvider<List<MenuItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final session = ref.watch(sessionProvider).value;

  if (session == null) return [];

  final data =
      await api.getRecommendations(session.sessionId);

  return data.map<MenuItem>((e) => MenuItem.fromJson(e)).toList();
});