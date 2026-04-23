"""Order-related Pydantic schemas."""

from datetime import datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class OrderItemDetail(BaseModel):
    """Detailed order item with snapshot of price at order time."""

    id: int
    menu_item_id: int
    menu_item_name: str
    quantity: int
    unit_price: Decimal = Field(..., decimal_places=2, description="Price at time of order")
    subtotal: Decimal = Field(..., decimal_places=2, description="unit_price * quantity")

    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    """Response schema for an order."""

    id: UUID
    order_number: str
    status: Literal["Received", "Cooking", "Ready", "Delivered"]
    items: list[OrderItemDetail]
    total_price: Decimal = Field(..., decimal_places=2)
    estimated_wait_minutes: int = Field(..., ge=0)
    created_at: datetime
    updated_at: datetime
    table_identifier: str = Field(..., description="Table where order was placed")

    class Config:
        from_attributes = True


class OrderStatusUpdate(BaseModel):
    """Request schema for updating order status."""

    status: Literal["Received", "Cooking", "Ready", "Delivered"] = Field(
        ..., description="New status (must follow valid transition sequence)"
    )
