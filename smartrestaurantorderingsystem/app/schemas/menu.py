"""Menu-related Pydantic schemas."""

from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field, field_validator


class MenuItemResponse(BaseModel):
    """Response schema for a single menu item."""

    id: int
    name: str
    category: str
    price: Decimal = Field(..., decimal_places=2)
    prep_time_minutes: int
    is_available: bool
    updated_at: datetime

    class Config:
        from_attributes = True


class MenuItemCreate(BaseModel):
    """Request schema for creating a menu item."""

    name: str = Field(..., min_length=1, max_length=255)
    category: str = Field(..., min_length=1, max_length=128)
    price: Decimal = Field(..., gt=0, decimal_places=2)
    prep_time_minutes: int = Field(..., gt=0)
    is_available: bool = True

    @field_validator("price")
    @classmethod
    def validate_price(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Price must be positive")
        return v

    @field_validator("prep_time_minutes")
    @classmethod
    def validate_prep_time(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("Preparation time must be positive")
        return v


class MenuItemUpdate(BaseModel):
    """Request schema for updating a menu item."""

    name: Optional[str] = Field(None, min_length=1, max_length=255)
    category: Optional[str] = Field(None, min_length=1, max_length=128)
    price: Optional[Decimal] = Field(None, gt=0, decimal_places=2)
    prep_time_minutes: Optional[int] = Field(None, gt=0)
    is_available: Optional[bool] = None

    @field_validator("price")
    @classmethod
    def validate_price(cls, v: Optional[Decimal]) -> Optional[Decimal]:
        if v is not None and v <= 0:
            raise ValueError("Price must be positive")
        return v

    @field_validator("prep_time_minutes")
    @classmethod
    def validate_prep_time(cls, v: Optional[int]) -> Optional[int]:
        if v is not None and v <= 0:
            raise ValueError("Preparation time must be positive")
        return v


class MenuGroupedResponse(BaseModel):
    """Response schema for menu items grouped by category."""

    categories: dict[str, list[MenuItemResponse]] = Field(
        ..., description="Menu items grouped by category name"
    )
    total_items: int = Field(..., description="Total number of menu items")
