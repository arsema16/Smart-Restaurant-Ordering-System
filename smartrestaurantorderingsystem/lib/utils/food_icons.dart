import 'package:flutter/material.dart';

/// Get appropriate icon for food item based on name
IconData getFoodIcon(String foodName) {
  final name = foodName.toLowerCase();
  
  // Ethiopian dishes
  if (name.contains('doro') || name.contains('wat')) {
    return Icons.ramen_dining;
  }
  if (name.contains('kitfo') || name.contains('tibs')) {
    return Icons.lunch_dining;
  }
  if (name.contains('shiro')) {
    return Icons.soup_kitchen;
  }
  if (name.contains('gomen')) {
    return Icons.eco;
  }
  if (name.contains('sambusa')) {
    return Icons.bakery_dining;
  }
  
  // Fast food
  if (name.contains('burger')) {
    return Icons.lunch_dining;
  }
  if (name.contains('pizza')) {
    return Icons.local_pizza;
  }
  if (name.contains('pasta')) {
    return Icons.ramen_dining;
  }
  if (name.contains('chicken')) {
    return Icons.set_meal;
  }
  
  // Drinks
  if (name.contains('coffee')) {
    return Icons.coffee;
  }
  if (name.contains('tej') || name.contains('wine')) {
    return Icons.wine_bar;
  }
  if (name.contains('juice')) {
    return Icons.local_drink;
  }
  if (name.contains('soft') || name.contains('drink')) {
    return Icons.local_cafe;
  }
  if (name.contains('water')) {
    return Icons.water_drop;
  }
  
  // Desserts
  if (name.contains('ice cream')) {
    return Icons.icecream;
  }
  if (name.contains('cake')) {
    return Icons.cake;
  }
  if (name.contains('fruit')) {
    return Icons.apple;
  }
  if (name.contains('baklava')) {
    return Icons.cookie;
  }
  
  // Appetizers
  if (name.contains('salad')) {
    return Icons.grass;
  }
  
  // Default
  return Icons.restaurant;
}

/// Get color for food category
Color getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'main course':
    case 'main':
      return Colors.orange;
    case 'fast food':
      return Colors.red;
    case 'drinks':
      return Colors.blue;
    case 'desserts':
      return Colors.pink;
    case 'appetizers':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
