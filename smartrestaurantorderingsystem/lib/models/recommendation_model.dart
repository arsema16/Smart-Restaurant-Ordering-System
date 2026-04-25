/// Recommendation models matching backend Pydantic schemas

/// Recommended item
class RecommendedItem {
  final int menuItemId;
  final String name;
  final String category;
  final double price;
  final double score;
  final String reason;

  RecommendedItem({
    required this.menuItemId,
    required this.name,
    required this.category,
    required this.price,
    required this.score,
    required this.reason,
  });

  factory RecommendedItem.fromJson(Map<String, dynamic> json) {
    return RecommendedItem(
      menuItemId: json['menu_item_id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      score: (json['score'] as num).toDouble(),
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_item_id': menuItemId,
      'name': name,
      'category': category,
      'price': price,
      'score': score,
      'reason': reason,
    };
  }
}

/// Recommendation response
class RecommendationResponse {
  final List<RecommendedItem> recommendations;

  RecommendationResponse({required this.recommendations});

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      recommendations: (json['recommendations'] as List)
          .map((item) => RecommendedItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendations': recommendations.map((item) => item.toJson()).toList(),
    };
  }
}
