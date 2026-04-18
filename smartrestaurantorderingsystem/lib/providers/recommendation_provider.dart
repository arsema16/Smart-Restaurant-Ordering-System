import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../models/menu_item_model.dart';
import 'session_provider.dart';

final recommendationProvider =
    FutureProvider<List<MenuItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final session = ref.watch(sessionProvider).value;

  if (session == null) return [];

  final data =
      await api.getRecommendations(session.sessionId);
print("Recommendation API called");
  return data.map<MenuItem>((e) => MenuItem.fromJson(e)).toList();
});