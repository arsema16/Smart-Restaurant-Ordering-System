from pydantic import BaseModel, Field
from datetime import datetime


class CartItemAdd(BaseModel):
    menu_item_id: int
    quantity: int = Field(..., gt=0)


class CartItemUpdate(BaseModel):
    quantity: int = Field(..., gt=0)


class CartItemDetail(BaseModel):
    id: int
    menu_item_id: int
    menu_item_name: str
    menu_item_price: float
    quantity: int
    added_at: datetime
    subtotal: float

    class Config:
        from_attributes = True


class CartResponse(BaseModel):
    session_id: int
    items: list[CartItemDetail]
    total: float
