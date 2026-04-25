# Smart Restaurant Ordering System - Flutter Frontend

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart      # API configuration and endpoints
│   ├── services/                   # Core services
│   └── utils/                      # Utility functions
│
├── models/                         # Data models matching backend schemas
│   ├── auth_model.dart            # Staff authentication models
│   ├── cart_item_model.dart       # Cart models
│   ├── menu_item_model.dart       # Menu models
│   ├── order_model.dart           # Order models
│   ├── recommendation_model.dart  # Recommendation models
│   └── session_model.dart         # Session models
│
├── services/                       # Business logic services
│   ├── api_service.dart           # HTTP client with Dio
│   └── websocket_service.dart     # WebSocket connection manager
│
├── providers/                      # Riverpod state management
│   ├── api_provider.dart          # API service provider
│   ├── cart_provider.dart         # Cart state
│   ├── menu_provider.dart         # Menu state
│   ├── order_provider.dart        # Order state
│   ├── recommendation_provider.dart # Recommendation state
│   ├── session_provider.dart      # Session state
│   └── websocket_provider.dart    # WebSocket service provider
│
├── repositories/                   # Data access layer
│   ├── menu_repository.dart
│   ├── order_repository.dart
│   ├── recommendation_repository.dart
│   └── session_repository.dart
│
├── screens/                        # UI screens
│   ├── cart/                      # Cart screen
│   ├── menu/                      # Menu browsing screen
│   ├── order/                     # Order tracking screen
│   ├── qr/                        # QR scanner screen
│   ├── recommendation/            # Recommendations screen
│   ├── splash/                    # Splash screen
│   └── staff/                     # Staff dashboard
│
├── routes/                         # Navigation
│   ├── app_router.dart            # Route configuration
│   └── route_names.dart           # Route name constants
│
├── widgets/                        # Reusable widgets
│   ├── app_bar.dart
│   ├── custom_button.dart
│   ├── error_widget.dart
│   └── loading_indicator.dart
│
├── app.dart                        # App widget
└── main.dart                       # Entry point
```

## Key Dependencies

- **flutter_riverpod**: State management
- **dio**: HTTP client for REST API calls
- **web_socket_channel**: WebSocket connections for real-time updates
- **go_router**: Declarative routing
- **shared_preferences**: Local storage for tokens and user ID
- **mobile_scanner**: QR code scanning
- **qr_flutter**: QR code generation
- **freezed**: Code generation for immutable models
- **json_serializable**: JSON serialization

## API Configuration

The backend API base URL is configured in `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://localhost:8000';
```

Update this to point to your backend server.

## Services

### API Service (`lib/services/api_service.dart`)

- Configured with base URL `/api/v1`
- Automatically adds session token to `X-Session-Token` header
- Automatically adds JWT token to `Authorization` header for staff endpoints
- Handles 401 errors by clearing tokens

### WebSocket Service (`lib/services/websocket_service.dart`)

- Manages WebSocket connections for real-time updates
- Supports guest and staff connections
- Implements automatic reconnection with exponential backoff
- Handles ping/pong keepalive (30s interval)
- Provides event stream for listening to server events

## Models

All models match the backend Pydantic schemas:

- **Session**: `SessionCreateRequest`, `SessionCreateResponse`, `SessionStateResponse`
- **Menu**: `MenuItemResponse`, `MenuGroupedResponse`, `MenuItemCreate`, `MenuItemUpdate`
- **Cart**: `CartItemAdd`, `CartItemUpdate`, `CartItemDetail`, `CartResponse`
- **Order**: `OrderResponse`, `OrderItemDetail`, `OrderStatusUpdate`, `OrderStatus` enum
- **Recommendation**: `RecommendedItem`, `RecommendationResponse`
- **Auth**: `LoginRequest`, `TokenResponse`

## WebSocket Events

The WebSocket service handles these event types:

- `order_created`: New order notification (staff)
- `order_status_updated`: Order status change (guest + staff)
- `menu_item_availability_changed`: Menu availability update (all guests)
- `cart_item_removed_unavailable`: Cart item removed due to unavailability (guest)
- `ping`/`pong`: Keepalive messages

## Next Steps

1. Implement repository layer for data access
2. Implement provider logic for state management
3. Build UI screens for guest and staff flows
4. Implement QR scanning and session initialization
5. Wire up WebSocket connections for real-time updates
