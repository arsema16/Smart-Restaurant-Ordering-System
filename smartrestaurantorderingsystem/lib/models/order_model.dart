/// Order models matching backend Pydantic schemas

/// Order status enum
enum OrderStatus {
  received,
  cooking,
  ready,
  delivered;

  String toJson() {
    switch (this) {
      case OrderStatus.received:
        return 'Received';
      case OrderStatus.cooking:
        return 'Cooking';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  static OrderStatus fromJson(String status) {
    switch (status) {
      case 'Received':
        return OrderStatus.received;
      case 'Cooking':
        return OrderStatus.cooking;
      case 'Ready':
        return OrderStatus.ready;
      case 'Delivered':
        return OrderStatus.delivered;
      default:
        throw ArgumentError('Unknown order status: $status');
    }
  }
}

/// Order item detail
class OrderItemDetail {
  final int menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;

  OrderItemDetail({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      menuItemId: json['menu_item_id'] as int,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_item_id': menuItemId,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}

/// Order response
class OrderResponse {
  final String id;
  final String orderNumber;
  final OrderStatus status;
  final List<OrderItemDetail> items;
  final int estimatedWaitMinutes;
  final String createdAt;

  OrderResponse({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.estimatedWaitMinutes,
    required this.createdAt,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      status: OrderStatus.fromJson(json['status'] as String),
      items: (json['items'] as List)
          .map((item) => OrderItemDetail.fromJson(item))
          .toList(),
      estimatedWaitMinutes: json['estimated_wait_minutes'] as int,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'status': status.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'estimated_wait_minutes': estimatedWaitMinutes,
      'created_at': createdAt,
    };
  }
}

/// Order status update request (staff only)
class OrderStatusUpdate {
  final OrderStatus status;

  OrderStatusUpdate({required this.status});

  Map<String, dynamic> toJson() {
    return {
      'status': status.toJson(),
    };
  }
}
