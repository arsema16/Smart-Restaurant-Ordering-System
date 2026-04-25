/// Menu item models matching backend Pydantic schemas

/// Menu item response
class MenuItemResponse {
  final int id;
  final String name;
  final String category;
  final double price;
  final int prepTimeMinutes;
  final bool isAvailable;

  MenuItemResponse({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.prepTimeMinutes,
    required this.isAvailable,
  });

  factory MenuItemResponse.fromJson(Map<String, dynamic> json) {
    return MenuItemResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      prepTimeMinutes: json['prep_time_minutes'] as int,
      isAvailable: json['is_available'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'prep_time_minutes': prepTimeMinutes,
      'is_available': isAvailable,
    };
  }
}

/// Menu grouped by category
class MenuGroupedResponse {
  final Map<String, List<MenuItemResponse>> categories;

  MenuGroupedResponse({required this.categories});

  factory MenuGroupedResponse.fromJson(Map<String, dynamic> json) {
    final categories = <String, List<MenuItemResponse>>{};
    json.forEach((category, items) {
      categories[category] = (items as List)
          .map((item) => MenuItemResponse.fromJson(item))
          .toList();
    });
    return MenuGroupedResponse(categories: categories);
  }
}

/// Menu item create request (staff only)
class MenuItemCreate {
  final String name;
  final String category;
  final double price;
  final int prepTimeMinutes;
  final bool isAvailable;

  MenuItemCreate({
    required this.name,
    required this.category,
    required this.price,
    required this.prepTimeMinutes,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'prep_time_minutes': prepTimeMinutes,
      'is_available': isAvailable,
    };
  }
}

/// Menu item update request (staff only)
class MenuItemUpdate {
  final String? name;
  final String? category;
  final double? price;
  final int? prepTimeMinutes;
  final bool? isAvailable;

  MenuItemUpdate({
    this.name,
    this.category,
    this.price,
    this.prepTimeMinutes,
    this.isAvailable,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (price != null) 'price': price,
      if (prepTimeMinutes != null) 'prep_time_minutes': prepTimeMinutes,
      if (isAvailable != null) 'is_available': isAvailable,
    };
  }
}