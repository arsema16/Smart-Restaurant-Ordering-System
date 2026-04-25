# Implementation Plan: Smart Restaurant Ordering System

## Overview

This implementation plan breaks down the Smart Restaurant Ordering System into discrete, incremental coding tasks. The system is built with FastAPI (Python 3.11+), PostgreSQL, Redis, and React/TypeScript. Each task builds on previous work, with property-based tests validating universal correctness guarantees and unit tests covering specific scenarios.

The implementation follows a layered approach: database models → core services → API endpoints → WebSocket real-time layer → recommendation engine → frontend components. Testing tasks are marked optional with `*` and can be skipped for faster MVP delivery.

---

## Tasks

- [x] 1. Set up project structure and core infrastructure
  - Create backend directory structure (`app/`, `tests/`, `alembic/`)
  - Set up `pyproject.toml` with dependencies (FastAPI, SQLAlchemy 2.0, asyncpg, aioredis, python-jose, bcrypt, hypothesis, pytest-asyncio)
  - Create `app/config.py` with Pydantic settings for database URL, Redis URL, JWT secret
  - Create `app/database.py` with async SQLAlchemy engine and session factory
  - Create `app/redis_client.py` with aioredis connection pool
  - Set up Docker Compose with PostgreSQL 15, Redis 7, and FastAPI service
  - _Requirements: 10.1, 10.4_

- [x] 1.1 Set up testing infrastructure
  - Configure pytest with asyncio mode and Hypothesis settings (200 examples)
  - Create test fixtures for database session, Redis client, and test client
  - Create test directory structure (`tests/unit/`, `tests/integration/`, `tests/e2e/`)
  - _Requirements: 10.1_

- [ ] 2. Implement database models and migrations
  - [x] 2.1 Create SQLAlchemy models
    - Create `app/models/table_session.py` with TableSession model (id, table_identifier, session_token, persistent_user_id, created_at, last_active_at, is_active)
    - Create `app/models/menu_item.py` with MenuItem model (id, name, category, price, prep_time_minutes, is_available, updated_at)
    - Create `app/models/cart.py` with CartItem model (id, session_id FK, menu_item_id FK, quantity, added_at)
    - Create `app/models/order.py` with Order and OrderItem models
    - Create `app/models/user_profile.py` with UserProfile model (id, persistent_user_id, most_ordered_items JSONB, recently_ordered_items JSONB, updated_at)
    - Create `app/models/staff_user.py` with StaffUser model (id, username, hashed_password, role, is_active)
    - _Requirements: 1.1, 1.2, 1.5, 2.1, 3.1, 4.1, 7.1, 9.1_

  - [x] 2.2 Create Alembic migrations
    - Initialize Alembic with `alembic init alembic`
    - Create migration for all tables with indexes and constraints
    - Add unique constraints, foreign keys, and check constraints as per design DDL
    - _Requirements: 9.4, 10.1_

  - [x] 2.3 Write property test for session token uniqueness
    - **Property 1: Session Token Uniqueness**
    - **Validates: Requirements 1.1, 1.2, 1.5**
    - Generate multiple session tokens and verify all are unique
    - Generate sessions for different table_identifiers and verify session_ids are unique

  - [ ]* 2.4 Write unit tests for model validation
    - Test MenuItem price and prep_time_minutes validation (must be positive)
    - Test Order status enum validation
    - Test CartItem quantity validation (must be positive)
    - _Requirements: 9.2, 9.3_

- [x] 3. Implement Pydantic schemas
  - Create `app/schemas/session.py` with SessionCreateRequest, SessionCreateResponse, SessionStateResponse
  - Create `app/schemas/menu.py` with MenuItemResponse, MenuItemCreate, MenuItemUpdate, MenuGroupedResponse
  - Create `app/schemas/cart.py` with CartItemAdd, CartItemUpdate, CartResponse, CartItemDetail
  - Create `app/schemas/order.py` with OrderResponse, OrderItemDetail, OrderStatusUpdate
  - Create `app/schemas/recommendation.py` with RecommendedItem, RecommendationResponse
  - Create `app/schemas/auth.py` with LoginRequest, TokenResponse
  - _Requirements: 2.2, 3.4, 4.1, 5.2, 8.1_

- [ ]* 3.1 Write property test for preference profile serialization round-trip
  - **Property 15: Preference Profile Serialization Round-Trip**
  - **Validates: Requirements 8.7**
  - Generate random PreferenceProfile objects, serialize to JSON, deserialize, verify equality

- [-] 4. Implement session management service
  - [x] 4.1 Create session service with token generation
    - Create `app/services/session_service.py`
    - Implement `generate_session_token()` using `secrets.token_urlsafe(32)`
    - Implement `create_session(table_identifier, persistent_user_id)` → creates TableSession, caches token in Redis
    - Implement `resume_session(session_token)` → looks up session from Redis cache or DB
    - Implement `validate_session_token(token)` → returns session_id or raises 401
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.6_

  - [ ]* 4.2 Write property test for session token round-trip
    - **Property 2: Session Token Round-Trip**
    - **Validates: Requirements 1.3, 1.4**
    - For any table_identifier, create session, then resume with token, verify same session_id returned

  - [ ]* 4.3 Write unit tests for session service
    - Test invalid/expired token returns 401
    - Test session restoration after page reload
    - Test session access from different device with same token
    - _Requirements: 1.3, 1.4, 1.6_

- [x] 5. Implement menu service
  - [x] 5.1 Create menu service with CRUD operations
    - Create `app/services/menu_service.py`
    - Implement `get_menu_grouped_by_category()` → returns MenuGroupedResponse
    - Implement `get_menu_item(item_id)` → returns MenuItem or 404
    - Implement `create_menu_item(data)` → validates and creates MenuItem (admin only)
    - Implement `update_menu_item(item_id, data)` → validates and updates MenuItem
    - Implement `toggle_availability(item_id, is_available)` → updates availability, publishes Redis event
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 9.1, 9.2, 9.3, 9.4_

  - [ ]* 5.2 Write property test for menu grouping completeness
    - **Property 3: Menu Grouping Completeness**
    - **Validates: Requirements 2.1, 2.2**
    - Generate random menu items with categories, call grouping function, verify all items present in correct groups

  - [ ]* 5.3 Write property test for unavailable item rejection
    - **Property 4: Unavailable Item Rejection**
    - **Validates: Requirements 2.3**
    - For any menu item with is_available=False, verify adding to cart is rejected

  - [ ]* 5.4 Write property test for menu item validation
    - **Property 19: Menu Item Validation**
    - **Validates: Requirements 9.2, 9.3**
    - Generate invalid menu items (price ≤ 0, prep_time ≤ 0, missing fields), verify all rejected

  - [ ]* 5.5 Write property test for menu item CRUD round-trip
    - **Property 20: Menu Item CRUD Round-Trip**
    - **Validates: Requirements 9.1, 9.4**
    - Create menu item, read it back, verify all fields preserved

- [x] 6. Checkpoint - Ensure database and core services work
  - Run migrations against test database
  - Run all property tests and unit tests for models, schemas, session service, menu service
  - Ensure all tests pass, ask the user if questions arise

- [x] 7. Implement cart service
  - [x] 7.1 Create cart service with add/remove/update operations
    - Create `app/services/cart_service.py`
    - Implement `get_cart(session_id)` → returns CartResponse with items and total_price
    - Implement `add_item(session_id, menu_item_id, quantity)` → adds or increments quantity, validates availability
    - Implement `update_item_quantity(session_id, menu_item_id, quantity)` → updates quantity or removes if zero
    - Implement `remove_item(session_id, menu_item_id)` → removes item from cart
    - Implement `clear_cart(session_id)` → removes all items
    - Implement `remove_unavailable_items(session_id)` → removes items with is_available=False
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ]* 7.2 Write property test for cart quantity invariant
    - **Property 5: Cart Quantity Invariant**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
    - Generate sequence of add/remove operations, verify final quantity and total_price correct

  - [ ]* 7.3 Write property test for unavailable cart item removal
    - **Property 6: Unavailable Cart Item Removal**
    - **Validates: Requirements 3.6**
    - Add item to cart, mark item unavailable, read cart, verify item absent

  - [ ]* 7.4 Write unit tests for cart service
    - Test empty cart blocks order placement
    - Test adding same item multiple times increments quantity
    - Test removing item when quantity reaches zero
    - _Requirements: 3.2, 3.3, 3.5_

- [x] 8. Implement order service
  - [x] 8.1 Create order service with placement and status management
    - Create `app/services/order_service.py`
    - Implement `generate_order_number()` → generates unique human-readable order number (e.g., "ORD-0042")
    - Implement `place_order(session_id)` → creates Order from cart, clears cart, sets status="Received", publishes Redis event
    - Implement `get_order(order_id)` → returns OrderResponse with items and status
    - Implement `get_orders_for_session(session_id)` → returns list of OrderResponse
    - Implement `get_all_active_orders()` → returns orders with status != "Delivered" (staff view)
    - Implement `update_order_status(order_id, new_status)` → validates transition, updates status, publishes Redis event
    - Implement `calculate_estimated_wait(order_id, queue_depth)` → sums prep_time_minutes + queue factor
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.2, 5.3, 5.4, 5.5, 6.2, 6.3, 6.4, 6.5_

  - [ ]* 8.2 Write property test for order number uniqueness and initial status
    - **Property 7: Order Number Uniqueness and Initial Status**
    - **Validates: Requirements 4.1, 4.2, 4.3**
    - Create N orders, verify all order_numbers unique and all initial status="Received"

  - [ ]* 8.3 Write property test for multiple orders per session
    - **Property 8: Multiple Orders Per Session**
    - **Validates: Requirements 4.5, 6.4**
    - Place N orders in same session, verify N distinct orders with distinct order_numbers

  - [ ]* 8.4 Write property test for order status transition guard
    - **Property 9: Order Status Transition Guard**
    - **Validates: Requirements 5.4, 5.5**
    - Generate random status transitions, verify only valid sequence allowed (Received→Cooking→Ready→Delivered)

  - [ ]* 8.5 Write property test for staff order response completeness
    - **Property 10: Staff Order Response Completeness**
    - **Validates: Requirements 5.2**
    - For any order, verify staff response contains order_number, table_identifier, items, status

  - [ ]* 8.6 Write property test for order status persistence round-trip
    - **Property 11: Order Status Persistence Round-Trip**
    - **Validates: Requirements 5.3**
    - Update order status, read back from DB, verify new status persisted

  - [ ]* 8.7 Write property test for estimated wait time calculation
    - **Property 12: Estimated Wait Time Calculation**
    - **Validates: Requirements 6.2, 6.3**
    - Generate orders with known prep times and queue depth, verify calculation is non-negative and correct

  - [ ]* 8.8 Write unit tests for order service
    - Test empty cart rejects order placement with descriptive error
    - Test order history shows delivered orders as complete
    - Test concurrent order status updates result in consistent state
    - _Requirements: 4.6, 6.5, 10.3_

- [x] 9. Checkpoint - Ensure cart and order services work end-to-end
  - Run all property tests and unit tests for cart and order services
  - Ensure all tests pass, ask the user if questions arise

- [x] 10. Implement preference profile service
  - [x] 10.1 Create preference profile service
    - Create `app/services/preference_profile_service.py`
    - Implement `get_or_create_profile(persistent_user_id)` → returns UserProfile or creates empty one
    - Implement `update_profile_on_order(persistent_user_id, ordered_item_ids)` → increments counts in most_ordered_items (top 5), prepends to recently_ordered_items (max 10)
    - Implement `get_most_ordered_items(persistent_user_id)` → returns top 5 items by count
    - Implement `get_recently_ordered_items(persistent_user_id)` → returns last 10 items
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [ ]* 10.2 Write property test for preference profile update invariants
    - **Property 13: Preference Profile Update Invariants**
    - **Validates: Requirements 7.1, 7.2, 7.3**
    - Place sequence of orders, verify most_ordered_items ≤ 5, recently_ordered_items ≤ 10, all ordered items appear in at least one list

  - [ ]* 10.3 Write property test for preference profile persistence
    - **Property 14: Preference Profile Persistence**
    - **Validates: Requirements 7.4**
    - Create multiple sessions with same persistent_user_id, verify profile identical across sessions

  - [ ]* 10.4 Write unit tests for preference profile service
    - Test new user gets empty profile
    - Test profile survives session changes
    - _Requirements: 7.4, 7.5_

- [ ] 11. Implement recommendation engine
  - [ ] 11.1 Create recommendation engine interface and implementations
    - Create `app/recommendation/engine.py` with RecommendationEngine Protocol
    - Create `app/recommendation/collaborative.py` with CollaborativeEngine (item-item similarity using scikit-learn)
    - Create `app/recommendation/fallback.py` with PopularityEngine (ranks by global order count)
    - Implement `get_recommendations(profile, cart_item_ids, available_item_ids, limit=5)` in both engines
    - Implement upsell rule: if cart has main_course and recommendations lack beverage/dessert, append one
    - Implement Redis caching with key `rec:{persistent_user_id}:{cart_hash}` and 60s TTL
    - Implement background task to rebuild similarity matrix every 15 minutes (asyncio + APScheduler)
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [ ]* 11.2 Write property test for recommendation exclusion and size
    - **Property 16: Recommendation Exclusion and Size**
    - **Validates: Requirements 8.1, 8.2, 8.3**
    - Generate profile, cart, available items, verify recommendations ≤ 5, no cart items, no unavailable items

  - [ ]* 11.3 Write property test for upsell inclusion when main course present
    - **Property 17: Upsell Inclusion When Main Course Present**
    - **Validates: Requirements 8.4**
    - Add main_course item to cart, verify recommendations include beverage or dessert

  - [ ]* 11.4 Write property test for popularity fallback ordering
    - **Property 18: Popularity Fallback Ordering**
    - **Validates: Requirements 8.5**
    - Empty profile, verify recommendations ordered by descending global order count

  - [ ]* 11.5 Write unit tests for recommendation engine
    - Test recommendation cache invalidation on cart change
    - Test similarity matrix refresh background task
    - _Requirements: 8.6_

- [ ] 12. Implement authentication and middleware
  - [ ] 12.1 Create JWT authentication for staff
    - Create `app/services/auth_service.py`
    - Implement `hash_password(password)` using bcrypt
    - Implement `verify_password(plain, hashed)` using bcrypt
    - Implement `create_access_token(username, role)` → JWT with 30min TTL
    - Implement `create_refresh_token(username)` → JWT with 8hr TTL
    - Implement `decode_token(token)` → returns payload or raises 401
    - _Requirements: 5.6_

  - [ ] 12.2 Create middleware for session and JWT validation
    - Create `app/middleware/session.py` with `validate_session_token` dependency
    - Create `app/middleware/auth.py` with `get_current_staff` dependency (validates JWT, checks is_active)
    - Create `app/middleware/auth.py` with `require_admin` dependency (checks role="admin")
    - _Requirements: 1.6, 2.5, 5.6_

  - [ ]* 12.3 Write unit tests for authentication
    - Test staff login returns JWT
    - Test invalid JWT returns 401
    - Test inactive staff user returns 401
    - Test non-admin user cannot create menu items (403)
    - _Requirements: 5.6_

- [ ] 13. Implement WebSocket connection manager
  - [ ] 13.1 Create WebSocket connection manager with Redis pub/sub
    - Create `app/services/websocket_manager.py`
    - Implement `ConnectionManager` class with guest_connections dict and staff_connections list
    - Implement `connect_guest(session_id, ws)` → adds to guest_connections, subscribes to Redis channels
    - Implement `connect_staff(ws)` → adds to staff_connections, subscribes to Redis channels
    - Implement `disconnect(ws)` → removes from connections, unsubscribes
    - Implement `broadcast_to_session(session_id, event)` → sends event to all guest connections for session
    - Implement `broadcast_to_staff(event)` → sends event to all staff connections
    - Implement `broadcast_order_status(order_id, new_status)` → publishes to Redis `orders:{order_id}:status`
    - Implement Redis pub/sub listeners for `orders:new`, `orders:{order_id}:status`, `menu:availability`
    - _Requirements: 2.4, 4.4, 5.1, 6.1, 10.4_

  - [ ]* 13.2 Write integration tests for WebSocket
    - Test order created event reaches staff dashboard within 2s
    - Test order status update event reaches guest within 2s
    - Test menu availability change event reaches all guests
    - Test WebSocket reconnection and state resync
    - _Requirements: 2.4, 4.4, 5.1, 6.1, 10.4_

- [ ] 14. Implement REST API endpoints
  - [ ] 14.1 Create guest endpoints
    - Create `app/routers/sessions.py` with POST /sessions, GET /sessions/{session_id}
    - Create `app/routers/menu.py` with GET /menu
    - Create `app/routers/cart.py` with GET /cart, POST /cart/items, PATCH /cart/items/{item_id}, DELETE /cart/items/{item_id}
    - Create `app/routers/orders.py` with POST /orders, GET /orders
    - Create `app/routers/recommendations.py` with GET /recommendations
    - Apply session token validation middleware to all guest endpoints
    - _Requirements: 1.1, 1.3, 2.1, 2.5, 3.1, 3.2, 3.3, 4.1, 4.5, 6.4, 8.1_

  - [ ] 14.2 Create staff endpoints
    - Create `app/routers/auth.py` with POST /auth/login, POST /auth/refresh
    - Create `app/routers/staff_orders.py` with GET /staff/orders, PATCH /staff/orders/{id}/status
    - Create `app/routers/staff_menu.py` with GET /staff/menu, POST /staff/menu, PUT /staff/menu/{id}, PATCH /staff/menu/{id}/availability
    - Apply JWT validation middleware to all staff endpoints
    - Apply admin role check to menu create/delete endpoints
    - _Requirements: 5.1, 5.2, 5.3, 5.6, 9.1_

  - [ ] 14.3 Create WebSocket endpoints
    - Create `app/routers/ws.py` with GET /ws/guest/{session_id}, GET /ws/staff
    - Validate session token (query param) for guest WS, JWT (query param) for staff WS
    - Implement ping/pong keepalive every 30s
    - _Requirements: 4.4, 5.1, 6.1, 10.4_

  - [ ] 14.4 Wire all routers into FastAPI app
    - Create `app/main.py` with FastAPI app factory
    - Register all routers with `/api/v1` prefix
    - Add CORS middleware for frontend
    - Add error handlers for 401, 403, 404, 422, 500
    - _Requirements: All API requirements_

  - [ ]* 14.5 Write integration tests for API endpoints
    - Test full guest flow: scan QR → browse menu → add to cart → place order → track status
    - Test staff flow: login → view orders → update status
    - Test session state round-trip (Property 21)
    - _Requirements: 10.1, 10.2, 10.5_

- [ ] 15. Checkpoint - Ensure backend is fully functional
  - Run all property tests, unit tests, and integration tests
  - Test API endpoints with curl or Postman
  - Test WebSocket connections with wscat
  - Ensure all tests pass, ask the user if questions arise

- [ ] 16. Set up frontend project structure
  - Create React 18 + TypeScript project with Vite
  - Set up directory structure (`src/components/`, `src/services/`, `src/hooks/`, `src/types/`)
  - Install dependencies (react-router-dom, axios, zustand for state, socket.io-client for WebSocket)
  - Create `src/services/api.ts` with axios instance configured for `/api/v1` base URL
  - Create `src/services/websocket.ts` with WebSocket connection manager
  - Create `src/types/` with TypeScript interfaces matching backend Pydantic schemas
  - _Requirements: 2.1, 6.1, 10.4_

- [ ] 17. Implement guest UI components
  - [ ] 17.1 Create QR scan and session initialization
    - Create `src/pages/QRScanPage.tsx` with QR code scanner (use `react-qr-reader`)
    - On scan, call POST /sessions, store session_token in localStorage
    - Create `src/hooks/useSession.ts` to manage session state and token
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [ ] 17.2 Create menu browsing UI
    - Create `src/pages/MenuPage.tsx` with category tabs and item cards
    - Display item name, price, prep time, availability status
    - Disable "Add to Cart" button for unavailable items
    - Call GET /menu on mount
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ] 17.3 Create cart UI
    - Create `src/components/Cart.tsx` with item list, quantity controls, total price
    - Implement add, update, remove item actions calling cart API endpoints
    - Disable "Place Order" button when cart is empty
    - Show notification when unavailable item is removed from cart
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ] 17.4 Create order placement and tracking UI
    - Create `src/pages/OrdersPage.tsx` with order history and status tracking
    - Display order number, items, status, estimated wait time
    - Call POST /orders to place order
    - Connect to WebSocket `/ws/guest/{session_id}` to receive real-time status updates
    - Implement reconnection logic with exponential backoff
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 6.1, 6.2, 6.3, 6.4, 6.5, 10.4_

  - [ ] 17.5 Create recommendations UI
    - Create `src/components/Recommendations.tsx` with recommended item cards
    - Call GET /recommendations on menu page and cart page
    - Update recommendations when cart changes
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [ ] 18. Implement staff dashboard UI
  - [ ] 18.1 Create staff login page
    - Create `src/pages/StaffLoginPage.tsx` with username/password form
    - Call POST /auth/login, store JWT in localStorage
    - Redirect to dashboard on success
    - _Requirements: 5.6_

  - [ ] 18.2 Create staff order management dashboard
    - Create `src/pages/StaffDashboardPage.tsx` with active orders list
    - Display order number, table identifier, items, status
    - Add status update buttons (Received → Cooking → Ready → Delivered)
    - Connect to WebSocket `/ws/staff` to receive real-time order events
    - Call PATCH /staff/orders/{id}/status to update status
    - Show error toast for invalid status transitions
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [ ] 18.3 Create staff menu management UI
    - Create `src/pages/StaffMenuPage.tsx` with menu item list and CRUD forms
    - Implement create, update, toggle availability actions
    - Show validation errors for invalid price or prep time
    - Restrict create/delete to admin role
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [ ] 19. Wire frontend and backend together
  - [ ] 19.1 Set up frontend routing
    - Create `src/App.tsx` with React Router routes for guest and staff pages
    - Implement protected routes for staff pages (check JWT)
    - Implement session restoration on page reload (check localStorage for session_token)
    - _Requirements: 1.3, 5.6_

  - [ ] 19.2 Implement persistent user identity
    - Generate `persistent_user_id` on first visit, store in localStorage
    - Send `persistent_user_id` in POST /sessions request body
    - _Requirements: 7.4_

  - [ ] 19.3 Test full end-to-end flows
    - Test guest flow: QR scan → browse menu → add to cart → place order → track status → receive delivered notification
    - Test staff flow: login → view new order → update status → verify guest receives update
    - Test menu availability change propagates to all guests
    - Test session restoration after page reload
    - Test session access from different device
    - _Requirements: All requirements_

- [ ] 20. Final checkpoint - Full system integration test
  - Run all backend tests (property, unit, integration)
  - Run frontend in dev mode, test all user flows manually
  - Test WebSocket reconnection and state resync
  - Test concurrent order updates from multiple staff members
  - Ensure all tests pass, ask the user if questions arise

---

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Property tests validate universal correctness guarantees (21 properties total)
- Unit tests validate specific examples and edge cases
- Integration tests validate real-time WebSocket behavior and infrastructure wiring
- The implementation follows a layered approach: models → services → API → WebSocket → recommendation → frontend
- Checkpoints ensure incremental validation at key milestones
- All code should be clean, readable, and follow natural Python/TypeScript conventions
