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
from typing import List

class MenuItem(BaseModel):
    id: str
    name: str
    price: float
    category: str
    available: bool

# sample menu data
menu_items = [
    {
        "id": "1",
        "name": "Burger",
        "price": 150,
        "category": "Main",
        "available": True
    },
    {
        "id": "2",
        "name": "Pizza",
        "price": 200,
        "category": "Main",
        "available": True
    },
    {
        "id": "3",
        "name": "Coke",
        "price": 50,
        "category": "Drinks",
        "available": True
    },
]

@app.get("/menu", response_model=List[MenuItem])
def get_menu():
    return menu_items
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