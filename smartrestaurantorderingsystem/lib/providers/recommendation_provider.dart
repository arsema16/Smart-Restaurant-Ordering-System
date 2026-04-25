import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation_model.dart';

/// Recommendation state notifier
class RecommendationNotifier extends StateNotifier<RecommendationResponse?> {
  RecommendationNotifier() : super(null);

  /// Update recommendations with response from API
  void updateRecommendations(RecommendationResponse recommendations) {
    state = recommendations;
  }

  /// Clear recommendations
  void clearRecommendations() {
    state = null;
  }

  /// Get recommended items
  List<RecommendedItem> get items => state?.recommendations ?? [];
}

final recommendationProvider = StateNotifierProvider<RecommendationNotifier, RecommendationResponse?>((ref) {
  return RecommendationNotifier();
});