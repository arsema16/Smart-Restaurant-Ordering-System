/// Session models matching backend Pydantic schemas

import 'cart_item_model.dart';
import 'order_model.dart';

/// Response when creating a new session
class SessionCreateResponse {
  final String sessionId;
  final String sessionToken;
  final String tableIdentifier;
  final bool isNew;

  SessionCreateResponse({
    required this.sessionId,
    required this.sessionToken,
    required this.tableIdentifier,
    required this.isNew,
  });

  factory SessionCreateResponse.fromJson(Map<String, dynamic> json) {
    return SessionCreateResponse(
      sessionId: json['session_id'] as String,
      sessionToken: json['session_token'] as String,
      tableIdentifier: json['table_identifier'] as String,
      isNew: json['is_new'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'session_token': sessionToken,
      'table_identifier': tableIdentifier,
      'is_new': isNew,
    };
  }
}

/// Request to create a session
class SessionCreateRequest {
  final String tableIdentifier;
  final String? sessionToken;
  final String? persistentUserId;

  SessionCreateRequest({
    required this.tableIdentifier,
    this.sessionToken,
    this.persistentUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'table_identifier': tableIdentifier,
      if (sessionToken != null) 'session_token': sessionToken,
      if (persistentUserId != null) 'persistent_user_id': persistentUserId,
    };
  }
}

/// Full session state response
class SessionStateResponse {
  final String sessionId;
  final String tableIdentifier;
  final List<CartItemDetail> cartItems;
  final List<OrderResponse> orders;

  SessionStateResponse({
    required this.sessionId,
    required this.tableIdentifier,
    required this.cartItems,
    required this.orders,
  });

  factory SessionStateResponse.fromJson(Map<String, dynamic> json) {
    return SessionStateResponse(
      sessionId: json['session_id'] as String,
      tableIdentifier: json['table_identifier'] as String,
      cartItems: (json['cart_items'] as List)
          .map((item) => CartItemDetail.fromJson(item))
          .toList(),
      orders: (json['orders'] as List)
          .map((order) => OrderResponse.fromJson(order))
          .toList(),
    );
  }
}