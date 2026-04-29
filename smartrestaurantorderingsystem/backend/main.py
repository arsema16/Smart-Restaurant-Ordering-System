from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from typing import Optional
import uuid
from datetime import datetime
from collections import defaultdict
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Habesha Bites API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

sessions = {}
carts = {}
orders = {}
user_profiles = {}

menu_items = [
    {"id": 1,  "name": "Doro Wat",         "price": 250.0, "category": "Main Course", "prep_time_minutes": 25, "is_available": True},
    {"id": 2,  "name": "Kitfo",            "price": 280.0, "category": "Main Course", "prep_time_minutes": 15, "is_available": True},
    {"id": 3,  "name": "Tibs",             "price": 220.0, "category": "Main Course", "prep_time_minutes": 20, "is_available": True},
    {"id": 4,  "name": "Shiro Wat",        "price": 150.0, "category": "Main Course", "prep_time_minutes": 18, "is_available": True},
    {"id": 5,  "name": "Gomen",            "price": 120.0, "category": "Main Course", "prep_time_minutes": 15, "is_available": True},
    {"id": 6,  "name": "Burger",           "price": 180.0, "category": "Fast Food",   "prep_time_minutes": 15, "is_available": True},
    {"id": 7,  "name": "Pizza Margherita", "price": 250.0, "category": "Fast Food",   "prep_time_minutes": 20, "is_available": True},
    {"id": 8,  "name": "Pasta Carbonara",  "price": 200.0, "category": "Fast Food",   "prep_time_minutes": 18, "is_available": True},
    {"id": 9,  "name": "Fried Chicken",    "price": 190.0, "category": "Fast Food",   "prep_time_minutes": 20, "is_available": True},
    {"id": 10, "name": "Ethiopian Coffee", "price":  50.0, "category": "Drinks",      "prep_time_minutes": 10, "is_available": True},
    {"id": 11, "name": "Tej (Honey Wine)", "price":  80.0, "category": "Drinks",      "prep_time_minutes":  5, "is_available": True},
    {"id": 12, "name": "Fresh Juice",      "price":  60.0, "category": "Drinks",      "prep_time_minutes":  5, "is_available": True},
    {"id": 13, "name": "Soft Drink",       "price":  40.0, "category": "Drinks",      "prep_time_minutes":  2, "is_available": True},
    {"id": 14, "name": "Mineral Water",    "price":  30.0, "category": "Drinks",      "prep_time_minutes":  1, "is_available": True},
    {"id": 15, "name": "Baklava",          "price":  90.0, "category": "Desserts",    "prep_time_minutes":  5, "is_available": True},
    {"id": 16, "name": "Ice Cream",        "price":  70.0, "category": "Desserts",    "prep_time_minutes":  3, "is_available": True},
    {"id": 17, "name": "Fruit Salad",      "price":  80.0, "category": "Desserts",    "prep_time_minutes":  5, "is_available": True},
    {"id": 18, "name": "Chocolate Cake",   "price": 100.0, "category": "Desserts",    "prep_time_minutes":  5, "is_available": True},
    {"id": 19, "name": "Sambusa",          "price":  60.0, "category": "Appetizers",  "prep_time_minutes": 10, "is_available": True},
    {"id": 20, "name": "Salad",            "price":  70.0, "category": "Appetizers",  "prep_time_minutes":  8, "is_available": True},
]

STAFF_CREDENTIALS = {"admin": "admin123", "staff": "staff123"}


def get_persistent_user_id(token: str) -> Optional[str]:
    for sid, data in sessions.items():
        if data.get("session_token") == token:
            return data.get("persistent_user_id")
    return None


def _cart_total(cart_items):
    return sum(ci["price"] * ci["quantity"] for ci in cart_items)


class SessionCreateRequest(BaseModel):
    table_identifier: str
    session_token: Optional[str] = None
    persistent_user_id: str


class LoginRequest(BaseModel):
    username: str
    password: str


@app.get("/api/v1/health")
@app.get("/health")
def health_check():
    return {"status": "healthy", "app": "Habesha Bites"}


@app.post("/api/v1/sessions")
def create_session(request: SessionCreateRequest):
    if request.session_token:
        for sid, data in sessions.items():
            if data.get("session_token") == request.session_token:
                return {"session_id": sid, "session_token": request.session_token,
                        "table_identifier": data["table_identifier"], "is_new": False}
    session_id = str(uuid.uuid4())
    session_token = str(uuid.uuid4())
    sessions[session_id] = {
        "table_identifier": request.table_identifier,
        "session_token": session_token,
        "persistent_user_id": request.persistent_user_id,
    }
    return {"session_id": session_id, "session_token": session_token,
            "table_identifier": request.table_identifier, "is_new": True}


@app.get("/api/v1/menu")
def get_menu():
    grouped = {}
    for item in menu_items:
        grouped.setdefault(item["category"], []).append(item)
    return grouped


@app.get("/api/v1/menu/search")
def search_menu(q: str = ""):
    if not q:
        return menu_items
    q_lower = q.lower()
    return [m for m in menu_items if q_lower in m["name"].lower() or q_lower in m["category"].lower()]


@app.get("/api/v1/cart")
def get_cart(x_session_token: Optional[str] = Header(default=None)):
    token = x_session_token or "guest"
    items = carts.get(token, [])
    return {"items": items, "total_price": _cart_total(items)}


@app.post("/api/v1/cart/items")
def add_cart_item(item: dict, x_session_token: Optional[str] = Header(default=None)):
    token = x_session_token or "guest"
    carts.setdefault(token, [])
    menu_item_id = item.get("menu_item_id")
    quantity = item.get("quantity", 1)
    menu_item = next((m for m in menu_items if m["id"] == menu_item_id), None)
    if not menu_item:
        raise HTTPException(status_code=404, detail="Menu item not found")
    existing = next((ci for ci in carts[token] if ci["menu_item_id"] == menu_item_id), None)
    if existing:
        existing["quantity"] += quantity
    else:
        carts[token].append({"id": len(carts[token]) + 1, "menu_item_id": menu_item_id,
                              "name": menu_item["name"], "price": menu_item["price"],
                              "quantity": quantity, "added_at": datetime.now().isoformat()})
    return {"items": carts[token], "total_price": _cart_total(carts[token])}


@app.patch("/api/v1/cart/items/{item_id}")
def update_cart_item(item_id: int, item: dict, x_session_token: Optional[str] = Header(default=None)):
    token = x_session_token or "guest"
    cart = carts.get(token, [])
    ci = next((c for c in cart if c["menu_item_id"] == item_id), None)
    if ci:
        ci["quantity"] = item.get("quantity", ci["quantity"])
        if ci["quantity"] <= 0:
            carts[token] = [c for c in cart if c["menu_item_id"] != item_id]
    return {"items": carts.get(token, []), "total_price": _cart_total(carts.get(token, []))}


@app.delete("/api/v1/cart/items/{item_id}")
def remove_cart_item(item_id: int, x_session_token: Optional[str] = Header(default=None)):
    token = x_session_token or "guest"
    carts[token] = [c for c in carts.get(token, []) if c["menu_item_id"] != item_id]
    return {"items": carts[token], "total_price": _cart_total(carts[token])}


@app.post("/api/v1/orders")
def create_order(x_session_token: Optional[str] = Header(default=None)):
    token = x_session_token or "guest"
    cart = carts.get(token, [])
    if not cart:
        raise HTTPException(status_code=400, detail="Cart is empty")
    order_id = str(uuid.uuid4())
    order = {
        "id": order_id,
        "order_number": f"ORD-{len(orders) + 1:04d}",
        "status": "Received",
        "items": [{"menu_item_id": ci["menu_item_id"], "name": ci["name"],
                   "quantity": ci["quantity"], "unit_price": ci["price"]} for ci in cart],
        "estimated_wait_minutes": 20,
        "created_at": datetime.now().isoformat(),
        "session_token": token,
    }
    orders[order_id] = order
    uid = get_persistent_user_id(token)
    if uid:
        profile = user_profiles.setdefault(uid, defaultdict(int))
        for ci in cart:
            profile[ci["menu_item_id"]] += ci["quantity"]
    carts[token] = []
    return order


@app.get("/api/v1/orders")
def get_orders(x_session_token: Optional[str] = Header(default=None)):
    token = x_session_token or "guest"
    return [o for o in orders.values() if o.get("session_token") == token]


@app.get("/api/v1/orders/{order_id}")
def get_order(order_id: str):
    order = orders.get(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


@app.get("/api/v1/recommendations")
def get_recommendations(x_session_token: Optional[str] = Header(default=None)):
    token = x_session_token or "guest"
    uid = get_persistent_user_id(token)
    cart_items = carts.get(token, [])
    cart_ids = {ci["menu_item_id"] for ci in cart_items}
    cart_menu_categories = set()
    for ci in cart_items:
        m = next((x for x in menu_items if x["id"] == ci["menu_item_id"]), None)
        if m:
            cart_menu_categories.add(m["category"])
    recs = []
    if uid and uid in user_profiles:
        profile = user_profiles[uid]
        ordered_ids = sorted(profile.keys(), key=lambda i: profile[i], reverse=True)
        personal = [m for m in menu_items if m["id"] in ordered_ids and m["id"] not in cart_ids and m["is_available"]]
        for m in personal[:2]:
            recs.append({**m, "reason": f"You've ordered this {profile[m['id']]} time(s)"})
    if "Main Course" in cart_menu_categories or "Fast Food" in cart_menu_categories:
        if "Drinks" not in cart_menu_categories:
            drink = next((m for m in menu_items if m["category"] == "Drinks" and m["id"] not in cart_ids and m["is_available"]), None)
            if drink and not any(r["id"] == drink["id"] for r in recs):
                recs.append({**drink, "reason": "Pairs well with your meal 🥤"})
        if "Desserts" not in cart_menu_categories:
            dessert = next((m for m in menu_items if m["category"] == "Desserts" and m["id"] not in cart_ids and m["is_available"]), None)
            if dessert and not any(r["id"] == dessert["id"] for r in recs):
                recs.append({**dessert, "reason": "Complete your meal with dessert 🍰"})
    if len(recs) < 3:
        for pid in [10, 1, 19, 16, 6]:
            if len(recs) >= 3:
                break
            m = next((x for x in menu_items if x["id"] == pid and x["id"] not in cart_ids and x["is_available"]), None)
            if m and not any(r["id"] == m["id"] for r in recs):
                recs.append({**m, "reason": "Popular choice ⭐"})
    return recs[:3]


@app.get("/api/v1/profile")
def get_user_profile(x_session_token: Optional[str] = Header(default=None)):
    token = x_session_token or "guest"
    uid = get_persistent_user_id(token)
    if not uid or uid not in user_profiles:
        return {"most_ordered": [], "recently_ordered": [], "total_orders": 0}
    profile = user_profiles[uid]
    sorted_ids = sorted(profile.keys(), key=lambda i: profile[i], reverse=True)[:5]
    most_ordered = []
    for mid in sorted_ids:
        item = next((m for m in menu_items if m["id"] == mid), None)
        if item:
            most_ordered.append({**item, "order_count": profile[mid]})
    return {"most_ordered": most_ordered, "recently_ordered": most_ordered, "total_orders": sum(profile.values())}


@app.post("/api/v1/auth/login")
def staff_login(request: LoginRequest):
    if request.username in STAFF_CREDENTIALS and STAFF_CREDENTIALS[request.username] == request.password:
        token = f"staff-token-{request.username}-{str(uuid.uuid4())[:8]}"
        return {"access_token": token, "refresh_token": token + "-refresh", "token_type": "bearer"}
    raise HTTPException(status_code=401, detail="Invalid credentials")


@app.post("/api/v1/auth/refresh")
def refresh_token(request: dict):
    token = f"staff-token-refreshed-{str(uuid.uuid4())[:8]}"
    return {"access_token": token, "refresh_token": token + "-refresh", "token_type": "bearer"}


@app.get("/api/v1/staff/orders")
def get_all_orders():
    return list(orders.values())


@app.patch("/api/v1/staff/orders/{order_id}/status")
def update_order_status(order_id: str, body: dict):
    order = orders.get(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    new_status = body.get("status")
    if new_status not in ["Received", "Cooking", "Ready", "Delivered"]:
        raise HTTPException(status_code=400, detail="Invalid status")
    orders[order_id]["status"] = new_status
    return orders[order_id]


@app.get("/api/v1/staff/menu")
def get_staff_menu():
    return menu_items

@app.post("/api/v1/staff/menu")
def create_menu_item(item: dict):
    new_id = max(m["id"] for m in menu_items) + 1
    new_item = {
        "id": new_id,
        "name": item.get("name", ""),
        "price": float(item.get("price", 0)),
        "category": item.get("category", "Main Course"),
        "prep_time_minutes": int(item.get("prep_time_minutes", 15)),
        "is_available": True,
    }
    menu_items.append(new_item)
    return new_item

@app.put("/api/v1/staff/menu/{item_id}")
def update_menu_item(item_id: int, item: dict):
    menu_item = next((m for m in menu_items if m["id"] == item_id), None)
    if not menu_item:
        raise HTTPException(status_code=404, detail="Item not found")
    menu_item.update({k: v for k, v in item.items() if k != "id"})
    return menu_item

@app.patch("/api/v1/staff/menu/{item_id}/availability")
def toggle_availability(item_id: int, body: dict):
    menu_item = next((m for m in menu_items if m["id"] == item_id), None)
    if not menu_item:
        raise HTTPException(status_code=404, detail="Item not found")
    menu_item["is_available"] = body.get("is_available", not menu_item["is_available"])
    return menu_item
