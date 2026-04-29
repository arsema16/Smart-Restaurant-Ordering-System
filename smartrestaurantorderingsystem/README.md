# Habesha Bites — Smart Restaurant Ordering System

A full-stack digital restaurant ordering system built with **FastAPI** (backend) and **Flutter Web** (frontend), deployed on **Railway** and **Firebase Hosting**.

## Live Demo

- **Frontend**: https://smart-restaurant-app-2024.web.app
- **Backend API**: https://smart-restaurant-ordering-system-production.up.railway.app
- **GitHub**: https://github.com/arsema16/Smart-Restaurant-Ordering-System

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Web (Firebase)                │
│  Welcome/QR → Menu → Cart → Order → Tracking            │
│  Staff Login → Staff Dashboard → Order Management       │
└────────────────────┬────────────────────────────────────┘
                     │ HTTPS REST API
┌────────────────────▼────────────────────────────────────┐
│              FastAPI Backend (Railway)                   │
│  /api/v1/sessions  /api/v1/menu  /api/v1/cart           │
│  /api/v1/orders    /api/v1/recommendations              │
│  /api/v1/staff/*   /api/v1/auth/*                       │
└────────────────────┬────────────────────────────────────┘
                     │ In-memory storage (demo)
                     │ (upgradeable to PostgreSQL)
```

---

## QR Session Logic

1. Each table has a unique QR code encoding:
   `https://smart-restaurant-app-2024.web.app/?table=<table-id>`

2. When a customer scans the QR code:
   - Flutter reads `?table=` from `Uri.base` (browser URL)
   - Calls `POST /api/v1/sessions` with `table_identifier` and `persistent_user_id`
   - Backend creates a unique `session_id` + `session_token`
   - Token stored in `localStorage` via `SharedPreferences`

3. Session persistence:
   - On page refresh: app reads token from `localStorage`, calls `POST /api/v1/sessions` with existing token → backend returns same session
   - Each session is uniquely identified by `session_id` (UUID)
   - Each user is identified by `persistent_user_id` (UUID stored in localStorage)

4. Cart isolation:
   - Every API call includes `X-Session-Token` header
   - Backend uses this token as the cart key → each user has their own cart

---

## AI Feature: Personalized Recommendations

**Implementation**: Collaborative filtering based on order history

**How it works**:
1. When a user places an order, the system records which items they ordered and how many times (keyed by `persistent_user_id`)
2. On the next visit, `GET /api/v1/recommendations` returns:
   - **Returning users**: Their most frequently ordered items (sorted by order count), excluding items already in cart
   - **New users**: Popular items (Ethiopian Coffee, Doro Wat, Sambusa, etc.) as fallback
3. Smart upselling: Items already in cart are excluded from recommendations

**Visible value**:
- Shown on both menu screen and cart screen
- Each recommendation card shows the reason: "You've ordered this 3 times" or "Popular choice"
- One-tap add to cart from recommendation card

---

## Staff Dashboard

Access: `https://smart-restaurant-app-2024.web.app` → Staff Dashboard button

**Credentials**:
- Username: `admin` / Password: `admin123`
- Username: `staff` / Password: `staff123`

**Features**:
- View all incoming orders in real time (poll every 30s)
- Update order status: Received → Cooking → Ready → Delivered
- Menu management (add/edit/toggle availability)
- Generate QR codes for tables

---

## Design Decisions

### Backend
- **FastAPI** with in-memory storage for demo simplicity (no Docker/PostgreSQL required)
- Session tokens passed via `X-Session-Token` header for cart/order isolation
- Per-user preference profiles stored in memory, keyed by `persistent_user_id`
- Staff auth uses simple credential check (upgradeable to JWT)

### Frontend
- **Flutter Web** for cross-platform support (works on any phone browser)
- **Riverpod** for state management
- Dynamic backend URL: reads host from `Uri.base` so the same build works on localhost and production
- `persistent_user_id` generated on first visit, stored in localStorage — survives sessions

### AI
- Frequency-based collaborative filtering (no external ML library needed)
- Runs entirely in the backend, O(n) complexity
- Graceful fallback to popularity-based recommendations for new users

---

## Running Locally

### Backend
```bash
cd backend
pip install fastapi uvicorn pydantic python-multipart
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend
```bash
flutter pub get
flutter run -d chrome --web-port 8080
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/sessions` | Create or resume table session |
| GET | `/api/v1/menu` | Get menu grouped by category |
| GET | `/api/v1/menu/search?q=` | Search menu items |
| GET | `/api/v1/cart` | Get user's cart |
| POST | `/api/v1/cart/items` | Add item to cart |
| PATCH | `/api/v1/cart/items/{id}` | Update cart item quantity |
| DELETE | `/api/v1/cart/items/{id}` | Remove cart item |
| POST | `/api/v1/orders` | Place order from cart |
| GET | `/api/v1/orders` | Get user's orders |
| GET | `/api/v1/recommendations` | Get AI recommendations |
| POST | `/api/v1/auth/login` | Staff login |
| GET | `/api/v1/staff/orders` | All orders (staff view) |
| PATCH | `/api/v1/staff/orders/{id}/status` | Update order status |
