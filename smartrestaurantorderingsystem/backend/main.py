from fastapi import FastAPI
from pydantic import BaseModel
import uuid

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# ✅ allow Flutter web to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# request body
class SessionRequest(BaseModel):
    table_id: str

# response model (optional but clean)
class SessionResponse(BaseModel):
    session_id: str
    table_id: str

# in-memory storage (for now)
sessions = {}

@app.post("/session/start", response_model=SessionResponse)
def start_session(request: SessionRequest):
    session_id = str(uuid.uuid4())

    sessions[session_id] = {
        "table_id": request.table_id
    }

    return {
        "session_id": session_id,
        "table_id": request.table_id
    }

# New endpoint for Flutter app compatibility
class SessionCreateRequest(BaseModel):
    table_identifier: str
    session_token: str | None = None
    persistent_user_id: str

class SessionCreateResponse(BaseModel):
    session_id: str
    session_token: str
    table_identifier: str
    is_new: bool

@app.post("/api/v1/sessions", response_model=SessionCreateResponse)
def create_session(request: SessionCreateRequest):
    # Generate session ID and token
    session_id = str(uuid.uuid4())
    session_token = request.session_token or str(uuid.uuid4())
    
    # Check if this is a new session or resuming
    is_new = request.session_token is None
    
    sessions[session_id] = {
        "table_identifier": request.table_identifier,
        "session_token": session_token,
        "persistent_user_id": request.persistent_user_id
    }
    
    return {
        "session_id": session_id,
        "session_token": session_token,
        "table_identifier": request.table_identifier,
        "is_new": is_new
    }
from typing import List

class MenuItem(BaseModel):
    id: int
    name: str
    price: float
    category: str
    prep_time_minutes: int
    is_available: bool

# sample menu data with Ethiopian and international dishes
menu_items = [
    # Main Courses
    {
        "id": 1,
        "name": "Doro Wat",
        "price": 250.0,
        "category": "Main Course",
        "prep_time_minutes": 25,
        "is_available": True
    },
    {
        "id": 2,
        "name": "Kitfo",
        "price": 280.0,
        "category": "Main Course",
        "prep_time_minutes": 15,
        "is_available": True
    },
    {
        "id": 3,
        "name": "Tibs",
        "price": 220.0,
        "category": "Main Course",
        "prep_time_minutes": 20,
        "is_available": True
    },
    {
        "id": 4,
        "name": "Shiro Wat",
        "price": 150.0,
        "category": "Main Course",
        "prep_time_minutes": 18,
        "is_available": True
    },
    {
        "id": 5,
        "name": "Gomen",
        "price": 120.0,
        "category": "Main Course",
        "prep_time_minutes": 15,
        "is_available": True
    },
    {
        "id": 6,
        "name": "Burger",
        "price": 180.0,
        "category": "Fast Food",
        "prep_time_minutes": 15,
        "is_available": True
    },
    {
        "id": 7,
        "name": "Pizza Margherita",
        "price": 250.0,
        "category": "Fast Food",
        "prep_time_minutes": 20,
        "is_available": True
    },
    {
        "id": 8,
        "name": "Pasta Carbonara",
        "price": 200.0,
        "category": "Fast Food",
        "prep_time_minutes": 18,
        "is_available": True
    },
    {
        "id": 9,
        "name": "Fried Chicken",
        "price": 190.0,
        "category": "Fast Food",
        "prep_time_minutes": 20,
        "is_available": True
    },
    # Drinks
    {
        "id": 10,
        "name": "Ethiopian Coffee",
        "price": 50.0,
        "category": "Drinks",
        "prep_time_minutes": 10,
        "is_available": True
    },
    {
        "id": 11,
        "name": "Tej (Honey Wine)",
        "price": 80.0,
        "category": "Drinks",
        "prep_time_minutes": 5,
        "is_available": True
    },
    {
        "id": 12,
        "name": "Fresh Juice",
        "price": 60.0,
        "category": "Drinks",
        "prep_time_minutes": 5,
        "is_available": True
    },
    {
        "id": 13,
        "name": "Soft Drink",
        "price": 40.0,
        "category": "Drinks",
        "prep_time_minutes": 2,
        "is_available": True
    },
    {
        "id": 14,
        "name": "Mineral Water",
        "price": 30.0,
        "category": "Drinks",
        "prep_time_minutes": 1,
        "is_available": True
    },
    # Desserts
    {
        "id": 15,
        "name": "Baklava",
        "price": 90.0,
        "category": "Desserts",
        "prep_time_minutes": 5,
        "is_available": True
    },
    {
        "id": 16,
        "name": "Ice Cream",
        "price": 70.0,
        "category": "Desserts",
        "prep_time_minutes": 3,
        "is_available": True
    },
    {
        "id": 17,
        "name": "Fruit Salad",
        "price": 80.0,
        "category": "Desserts",
        "prep_time_minutes": 5,
        "is_available": True
    },
    {
        "id": 18,
        "name": "Chocolate Cake",
        "price": 100.0,
        "category": "Desserts",
        "prep_time_minutes": 5,
        "is_available": True
    },
    # Appetizers
    {
        "id": 19,
        "name": "Sambusa",
        "price": 60.0,
        "category": "Appetizers",
        "prep_time_minutes": 10,
        "is_available": True
    },
    {
        "id": 20,
        "name": "Salad",
        "price": 70.0,
        "category": "Appetizers",
        "prep_time_minutes": 8,
        "is_available": True
    },
]

@app.get("/menu")
def get_menu():
    return menu_items

@app.get("/api/v1/menu")
def get_menu_v1():
    # Group menu items by category
    grouped = {}
    for item in menu_items:
        category = item["category"]
        if category not in grouped:
            grouped[category] = []
        grouped[category].append(item)
    return grouped
from datetime import datetime

class OrderItem(BaseModel):
    id: str
    name: str
    price: float
    quantity: int

class OrderRequest(BaseModel):
    session_id: str
    items: list[OrderItem]

class OrderResponse(BaseModel):
    order_id: str
    status: str
    created_at: str

orders = {}

@app.post("/order", response_model=OrderResponse)
def create_order(request: OrderRequest):
    order_id = str(uuid.uuid4())

    orders[order_id] = {
        "session_id": request.session_id,
        "items": request.items,
        "status": "Received",
        "created_at": datetime.now().isoformat()
    }

    return {
        "order_id": order_id,
        "status": "Received",
        "created_at": orders[order_id]["created_at"]
    }
@app.get("/order/{order_id}")
def get_order(order_id: str):
    order = orders.get(order_id)

    if not order:
        return {"error": "Order not found"}

    return {
        "order_id": order_id,
        "status": order["status"],
        "created_at": order["created_at"]
    }
@app.get("/recommend/{session_id}")
def recommend(session_id: str):
    # simple logic (you can improve later)
    return [
        {
            "id": "3",
            "name": "Coke",
            "price": 50,
            "category": "Drinks",
            "available": True
        }
    ]

@app.get("/api/v1/health")
@app.get("/health")
def health_check():
    return {"status": "healthy", "app": "Smart Restaurant Ordering System"}

# Cart storage (in-memory)
carts = {}  # session_id -> list of cart items

# Cart endpoints
@app.get("/api/v1/cart")
def get_cart():
    # Get cart for default session
    session_id = "default"
    
    if session_id in carts and carts[session_id]:
        total = sum(ci["price"] * ci["quantity"] for ci in carts[session_id])
        return {"items": carts[session_id], "total_price": total}
    
    return {"items": [], "total_price": 0.0}

@app.post("/api/v1/cart/items")
def add_cart_item(item: dict):
    # Get session from headers (simplified - just use a default session)
    session_id = "default"
    
    if session_id not in carts:
        carts[session_id] = []
    
    # Check if item already exists
    menu_item_id = item.get("menu_item_id")
    quantity = item.get("quantity", 1)
    
    # Find the menu item details
    menu_item = next((m for m in menu_items if m["id"] == menu_item_id), None)
    if not menu_item:
        return {"items": [], "total_price": 0.0}
    
    # Check if item already in cart
    existing_item = next((ci for ci in carts[session_id] if ci["menu_item_id"] == menu_item_id), None)
    
    if existing_item:
        existing_item["quantity"] += quantity
    else:
        carts[session_id].append({
            "id": len(carts[session_id]) + 1,
            "menu_item_id": menu_item_id,
            "name": menu_item["name"],
            "price": menu_item["price"],
            "quantity": quantity,
            "added_at": datetime.now().isoformat()
        })
    
    # Calculate total
    total = sum(ci["price"] * ci["quantity"] for ci in carts[session_id])
    
    return {"items": carts[session_id], "total_price": total}

@app.delete("/api/v1/cart/items/{item_id}")
def remove_cart_item(item_id: int):
    session_id = "default"
    
    if session_id in carts:
        carts[session_id] = [ci for ci in carts[session_id] if ci["menu_item_id"] != item_id]
        total = sum(ci["price"] * ci["quantity"] for ci in carts[session_id])
        return {"items": carts[session_id], "total_price": total}
    
    return {"items": [], "total_price": 0.0}

@app.patch("/api/v1/cart/items/{item_id}")
def update_cart_item(item_id: int, item: dict):
    session_id = "default"
    
    if session_id in carts:
        cart_item = next((ci for ci in carts[session_id] if ci["menu_item_id"] == item_id), None)
        if cart_item:
            cart_item["quantity"] = item.get("quantity", cart_item["quantity"])
            
            # Remove if quantity is 0
            if cart_item["quantity"] <= 0:
                carts[session_id] = [ci for ci in carts[session_id] if ci["menu_item_id"] != item_id]
        
        total = sum(ci["price"] * ci["quantity"] for ci in carts[session_id])
        return {"items": carts[session_id], "total_price": total}
    
    return {"items": [], "total_price": 0.0}

# Recommendations endpoint
@app.get("/api/v1/recommendations")
def get_recommendations():
    # Return some sample recommendations (Ethiopian dishes and popular items)
    return [
        {
            "id": 10,
            "name": "Ethiopian Coffee",
            "price": 50.0,
            "category": "Drinks",
            "prep_time_minutes": 10,
            "is_available": True
        },
        {
            "id": 2,
            "name": "Kitfo",
            "price": 280.0,
            "category": "Main Course",
            "prep_time_minutes": 15,
            "is_available": True
        },
        {
            "id": 19,
            "name": "Sambusa",
            "price": 60.0,
            "category": "Appetizers",
            "prep_time_minutes": 10,
            "is_available": True
        },
    ]

# Orders endpoints
@app.post("/api/v1/orders")
def create_order_v1():
    # Get cart for default session
    session_id = "default"
    
    if session_id not in carts or not carts[session_id]:
        return {"error": "Cart is empty"}
    
    # Create order from cart
    order_id = str(uuid.uuid4())
    order_number = f"ORD-{len(orders) + 1:04d}"
    
    # Convert cart items to order items
    order_items = []
    for cart_item in carts[session_id]:
        order_items.append({
            "menu_item_id": cart_item["menu_item_id"],
            "name": cart_item["name"],
            "quantity": cart_item["quantity"],
            "unit_price": cart_item["price"]
        })
    
    order = {
        "id": order_id,
        "order_number": order_number,
        "status": "Received",
        "items": order_items,
        "estimated_wait_minutes": 20,
        "created_at": datetime.now().isoformat()
    }
    
    orders[order_id] = order
    
    # Clear cart after order
    carts[session_id] = []
    
    return order

@app.get("/api/v1/orders")
def get_orders_v1():
    # Return all orders
    return list(orders.values())

@app.get("/api/v1/orders/{order_id}")
def get_order_by_id_v1(order_id: str):
    order = orders.get(order_id)
    if not order:
        return {"error": "Order not found"}
    return order