# Staff Dashboard UI

This directory contains the staff-facing UI components for the Smart Restaurant Ordering System.

## Components

### 1. Staff Login Screen (`staff_login_screen.dart`)
- **Purpose**: Authentication for staff members
- **Features**:
  - Username/password form with validation
  - JWT token storage in SharedPreferences
  - Redirect to dashboard on success
  - Error handling with user feedback
- **Requirements**: 5.6

### 2. Order Management Screen (`order_management_screen.dart`)
- **Purpose**: Real-time order management dashboard
- **Features**:
  - Display active orders with order number, table ID, items, and status
  - Status update buttons following the sequence: Received → Cooking → Ready → Delivered
  - WebSocket connection for real-time updates
  - Connection status indicator
  - Error handling for invalid status transitions
- **Requirements**: 5.1, 5.2, 5.3, 5.4, 5.5

### 3. Menu Management Screen (`menu_management_screen.dart`)
- **Purpose**: CRUD operations for menu items
- **Features**:
  - List all menu items grouped by category
  - Create new menu items (admin only)
  - Update existing menu items
  - Toggle item availability
  - Form validation for price (> 0) and prep time (> 0)
  - Error handling with user feedback
- **Requirements**: 9.1, 9.2, 9.3, 9.4

### 4. Staff Dashboard (`staff_dashboard.dart`)
- **Purpose**: Main navigation hub for staff
- **Features**:
  - Bottom navigation bar with three tabs:
    - Orders: Order management
    - Menu: Menu management
    - QR Codes: QR code generator
  - Logout functionality
  - Persistent navigation state

### 5. QR Generator Screen (`qr_generator_screen.dart`)
- **Purpose**: Generate QR codes for table sessions
- **Features**:
  - Input table identifier
  - Generate QR code with embedded URL
  - Display printable QR code
  - Instructions for staff

## State Management

All screens use Riverpod for state management with the following providers:

- `authProvider`: Authentication state and login/logout
- `staffOrderProvider`: Order list and status updates
- `staffMenuProvider`: Menu items and CRUD operations

## Services & Repositories

### Services
- `AuthService`: JWT token management
- `ApiService`: HTTP client with automatic token injection
- `WebSocketService`: Real-time updates

### Repositories
- `AuthRepository`: Login and token refresh endpoints
- `StaffOrderRepository`: Staff order endpoints (`/staff/orders`)
- `StaffMenuRepository`: Staff menu endpoints (`/staff/menu`)

## API Integration

All staff endpoints require JWT authentication:
- `POST /auth/login`: Staff login
- `POST /auth/refresh`: Token refresh
- `GET /staff/orders`: Get active orders
- `PATCH /staff/orders/{id}/status`: Update order status
- `GET /staff/menu`: Get all menu items
- `POST /staff/menu`: Create menu item (admin only)
- `PUT /staff/menu/{id}`: Update menu item
- `PATCH /staff/menu/{id}/availability`: Toggle availability

WebSocket endpoint:
- `GET /ws/staff`: Real-time order updates

## Usage

### Navigation Flow
1. User opens app → Staff Login Screen
2. Enter credentials → Authenticate
3. On success → Staff Dashboard
4. Navigate between Orders, Menu, and QR tabs
5. Logout → Return to Login Screen

### Order Management Flow
1. View active orders in real-time
2. Click status button to advance order
3. Order progresses: Received → Cooking → Ready → Delivered
4. Invalid transitions show error toast
5. WebSocket updates all connected staff clients

### Menu Management Flow
1. View all menu items grouped by category
2. Toggle availability with switch
3. Click edit to update item details
4. Click FAB to create new item
5. Form validates price > 0 and prep time > 0

## Error Handling

All screens implement comprehensive error handling:
- Network errors: Show error toast with retry option
- Validation errors: Show inline form validation
- Authentication errors: Redirect to login
- WebSocket disconnection: Show connection status indicator

## Testing

Basic widget tests are in `test/staff_ui_test.dart`. For full integration testing:
1. Mock API responses
2. Test authentication flow
3. Test order status transitions
4. Test menu CRUD operations
5. Test WebSocket reconnection

## Future Enhancements

- Role-based access control (admin vs staff)
- Order filtering and search
- Menu item images
- Bulk operations
- Analytics dashboard
- Push notifications
