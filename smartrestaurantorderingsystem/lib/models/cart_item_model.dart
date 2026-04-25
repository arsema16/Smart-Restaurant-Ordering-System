/// Cart models matching backend Pydantic schemas

/// Request to add item to cart
class CartItemAdd {
  final int menuItemId;
  final int quantity;

  CartItemAdd({
    required this.menuItemId,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'menu_item_id': menuItemId,
      'quantity': quantity,
    };
  }
}

/// Request to update cart item quantity
class CartItemUpdate {
  final int quantity;

  CartItemUpdate({required this.quantity});

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
    };
  }
}

/// Cart item detail in response
class CartItemDetail {
  final int id;
  final int menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String addedAt;

  CartItemDetail({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.addedAt,
  });

  factory CartItemDetail.fromJson(Map<String, dynamic> json) {
    return CartItemDetail(
      id: json['id'] as int,
      menuItemId: json['menu_item_id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      addedAt: json['added_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_item_id': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'added_at': addedAt,
    };
  }
}

/// Full cart response
class CartResponse {
  final List<CartItemDetail> items;
  final double totalPrice;

  CartResponse({
    required this.items,
    required this.totalPrice,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      items: (json['items'] as List)
          .map((item) => CartItemDetail.fromJson(item))
          .toList(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total_price': totalPrice,
    };
  }
}