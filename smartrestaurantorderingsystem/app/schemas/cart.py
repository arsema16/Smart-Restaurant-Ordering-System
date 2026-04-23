"""Cart-related Pydantic schemas."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class CartItemAdd(BaseModel):
    """Request schema for adding an item to the cart."""

    menu_item_id: int = Field(..., gt=0)
    quantity: int = Field(1, gt=0)


class CartItemUpdate(BaseModel):
    """Request schema for updating cart item quantity."""

    quantity: int = Field(..., ge=0, description="Set to 0 to remove item")


class CartItemDetail(BaseModel):
    """Detailed cart item with menu information."""

    id: int
    menu_item_id: int
    menu_item_name: str
    category: str
    unit_price: Decimal = Field(..., decimal_places=2)
    quantity: int
    subtotal: Decimal = Field(..., decimal_places=2, description="unit_price * quantity")
    added_at: datetime

    class Config:
        from_attributes = True


class CartResponse(BaseModel):
    """Response schema for cart contents."""

    items: list[CartItemDetail] = Field(default_factory=list)
    total_price: Decimal = Field(..., decimal_places=2, description="Sum of all item subtotals")
    item_count: int = Field(..., description="Total number of distinct items")
