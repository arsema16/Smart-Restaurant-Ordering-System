import '../services/api_service.dart';
import '../models/recommendation_model.dart';

class RecommendationRepository {
  final ApiService _api;

  RecommendationRepository(this._api);

  /// Get personalized recommendations
  Future<RecommendationResponse> getRecommendations() async {
    final response = await _api.get('/recommendations');
    return RecommendationResponse.fromJson(response.data);
  }
}
