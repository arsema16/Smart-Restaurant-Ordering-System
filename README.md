# Habesha Bites — Smart Restaurant Ordering System

A full-stack digital restaurant ordering system where customers scan a QR code at their table and interact with a complete ordering, tracking, and recommendation system.

**Live Demo**
- Frontend: https://smart-restaurant-app-2024.web.app
- Backend API: https://smart-restaurant-ordering-system-production.up.railway.app
- GitHub: https://github.com/arsema16/Smart-Restaurant-Ordering-System

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                  Flutter Web (Firebase Hosting)              │
│                                                              │
│  ┌─────────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐    │
│  │ Welcome/QR  │→ │   Menu   │→ │   Cart   │→ │ Tracking│    │
│  └─────────────┘  └──────────┘  └──────────┘  └─────────┘    │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │         Staff Dashboard (Login → Orders → Status)    │    │
│  └──────────────────────────────────────────────────────┘    │
└────────────────────────┬─────────────────────────────────────┘
                         │ HTTPS REST API
                         │ (X-Session-Token header)
┌────────────────────────▼─────────────────────────────────────┐
│                  FastAPI Backend (Railway)                   │
│                                                              │
│  Sessions  │  Menu  │  Cart  │  Orders  │  Recommendations   │
│                                                              │
│  Auth      │  Staff Orders   │  User Profiles                │
└──────────────────────────────────────────────────────────────┘
```

**Technology Stack**
- Backend: Python 3.11 + FastAPI, deployed on Railway
- Frontend: Flutter Web (Dart), deployed on Firebase Hosting
- Storage: In-memory (no database required for demo)
- State Management: Riverpod
- HTTP Client: Dio

---

## QR Session Logic

### How it works

Each restaurant table has a unique QR code that encodes a URL:
```
https://smart-restaurant-app-2024.web.app/?table=table-1
```

**Step 1 — QR Scan**
When a customer scans the QR code, their phone browser opens the Flutter web app. Flutter reads the `?table=` parameter directly from `Uri.base` (the browser URL) before any routing occurs.

**Step 2 — Session Creation**
The app calls `POST /api/v1/sessions` with:
- `table_identifier` — the table ID from the QR code
- `persistent_user_id` — a UUID generated on first visit and stored in localStorage
- `session_token` — null for new sessions, or the existing token when resuming

The backend returns a unique `session_id` and `session_token`.

**Step 3 — Session Persistence**
The `session_token` is stored in the device's localStorage via SharedPreferences. On every subsequent visit (refresh, return visit), the app sends the existing token to the backend, which returns the same session — preserving the user's cart and order history.

**Step 4 — Request Isolation**
Every API request includes the `X-Session-Token` header. The backend uses this token as the key for cart storage, so each user's cart is completely isolated from other users at the same or different tables.

```
User A (table-1) → session_token: "abc-123" → cart["abc-123"] = [Doro Wat]
User B (table-1) → session_token: "xyz-789" → cart["xyz-789"] = [Burger]
```

### Staff QR Code
The staff portal generates a separate QR code encoding:
```
https://smart-restaurant-app-2024.web.app/staff-login
```
When staff scan this, they are taken directly to the staff login page, not the customer menu.

---

## AI Feature: Personalized Recommendations with Smart Upselling

### Overview
The system integrates a personalized recommendation engine that combines order history analysis with real-time cart-aware upselling. It is visible on both the menu screen and the cart screen.

### How it works

The recommendation engine runs in three layers:

**Layer 1 — Personal History (Collaborative Filtering)**
When a user places an order, the system records which items they ordered and how many times, keyed by their `persistent_user_id`. On the next visit, the engine retrieves their top items sorted by order frequency and recommends items they have ordered before but are not currently in their cart.

Example output: *"You've ordered this 3 times"*

**Layer 2 — Smart Upselling (Rule-Based)**
The engine inspects the current cart contents in real time:
- If the cart contains a Main Course or Fast Food item but no Drink → recommends a drink with the message *"Pairs well with your meal 🥤"*
- If the cart contains a Main Course or Fast Food item but no Dessert → recommends a dessert with the message *"Complete your meal with dessert 🍰"*

This increases average order value and improves the dining experience.

**Layer 3 — Popularity Fallback**
For new users with no order history, the engine falls back to globally popular items (Ethiopian Coffee, Doro Wat, Sambusa, Ice Cream, Burger) ranked by their position in the menu.

### Why it is not decorative
- Recommendations change based on what is in the cart right now
- Recommendations change based on the user's personal order history
- Each recommendation card shows a reason explaining why it was suggested
- Users can add recommended items to cart with a single tap
- The engine excludes items already in the cart to avoid redundancy

---

## Design Decisions

### 1. In-Memory Storage Instead of a Database
The backend uses Python dictionaries for all storage. This eliminates the need for PostgreSQL, Redis, or Docker during development and demo, making the system immediately runnable with a single command. The data structures are designed to be drop-in replaceable with a real database.

### 2. Session Token in HTTP Header
Rather than using cookies or URL parameters, the session token is passed as a custom `X-Session-Token` header on every request. This approach works reliably across all browsers including mobile Safari, avoids CORS cookie issues, and makes the API stateless and easy to test.

### 3. Persistent User Identity Without Login
Each device generates a `persistent_user_id` UUID on first visit and stores it in localStorage. This ID survives session changes and allows the system to build a preference profile per user without requiring account creation. The user gets personalized recommendations from their first order onward.

### 4. Polling Instead of WebSockets
The order tracking screen and staff dashboard poll the backend every 5 seconds instead of maintaining a WebSocket connection. This decision was made because WebSocket connections are unreliable in Flutter Web across different mobile browsers, while polling is universally supported and sufficient for a restaurant context where order status changes every few minutes.

### 5. Flutter Web for Cross-Platform Support
Using Flutter Web means the same codebase runs on any device with a browser — no app installation required. Customers scan a QR code and the ordering interface loads immediately in their phone browser. The app is compiled to JavaScript and served as a static site from Firebase Hosting, giving it fast global load times.

### 6. Dynamic Backend URL
The Flutter app determines the backend URL at runtime using `Uri.base.host`. When accessed from `localhost:8080`, it calls `localhost:8000`. When accessed from the Firebase domain, it calls the Railway backend. This means the same build works in both development and production without any configuration changes.

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/sessions` | Create or resume a table session |
| GET | `/api/v1/menu` | Get menu grouped by category |
| GET | `/api/v1/menu/search?q=` | Search menu items |
| GET | `/api/v1/cart` | Get current user's cart |
| POST | `/api/v1/cart/items` | Add item to cart |
| PATCH | `/api/v1/cart/items/{id}` | Update item quantity |
| DELETE | `/api/v1/cart/items/{id}` | Remove item from cart |
| POST | `/api/v1/orders` | Place order from cart |
| GET | `/api/v1/orders` | Get all orders for current session |
| GET | `/api/v1/orders/{id}` | Get single order by ID |
| GET | `/api/v1/recommendations` | Get AI-powered recommendations |
| GET | `/api/v1/profile` | Get user preference profile |
| POST | `/api/v1/auth/login` | Staff login |
| GET | `/api/v1/staff/orders` | Get all orders (staff view) |
| PATCH | `/api/v1/staff/orders/{id}/status` | Update order status |

---

## Running Locally

**Backend**
```bash
cd backend
pip install fastapi uvicorn pydantic python-multipart
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Frontend**
```bash
flutter pub get
flutter run -d chrome --web-port 8080
```

**Staff Login Credentials**
- Username: `admin` / Password: `admin123`
- Username: `staff` / Password: `staff123`
