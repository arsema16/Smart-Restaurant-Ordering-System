from pydantic import BaseModel
from datetime import datetime
from enum import Enum


class OrderStatus(str, Enum):
    pending = "pending"
    confirmed = "confirmed"
    preparing = "preparing"
    ready = "ready"
    delivered = "delivered"
    cancelled = "cancelled"


class OrderItemDetail(BaseModel):
    menu_item_id: int
    menu_item_name: str
    quantity: int
    price_at_order: float
    subtotal: float

    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    id: int
    session_id: int
    table_identifier: str
    status: OrderStatus
    total_amount: float
    estimated_prep_time_minutes: int
    items: list[OrderItemDetail]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class OrderStatusUpdate(BaseModel):
    status: OrderStatus
