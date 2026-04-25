import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation_model.dart';
import '../repositories/recommendation_repository.dart';
import 'api_provider.dart';
import 'cart_provider.dart';

/// Recommendation state notifier
class RecommendationNotifier extends StateNotifier<AsyncValue<RecommendationResponse>> {
  final RecommendationRepository _repository;
  final Ref _ref;

  RecommendationNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadRecommendations();
    
    // Listen to cart changes and reload recommendations
    _ref.listen(cartProvider, (previous, next) {
      loadRecommendations();
    });
  }

  /// Load recommendations from API
  Future<void> loadRecommendations() async {
    try {
      final recommendations = await _repository.getRecommendations();
      state = AsyncValue.data(recommendations);
    } catch (e, stack) {
      // Don't show error for recommendations, just return empty
      state = AsyncValue.data(RecommendationResponse(recommendations: []));
    }
  }

  /// Get recommended items
  List<RecommendedItem> get items {
    return state.when(
      data: (rec) => rec.recommendations,
      loading: () => [],
      error: (_, __) => [],
    );
  }
}

final recommendationProvider = StateNotifierProvider<RecommendationNotifier, AsyncValue<RecommendationResponse>>((ref) {
  final repository = ref.watch(recommendationRepositoryProvider);
  return RecommendationNotifier(repository, ref);
});