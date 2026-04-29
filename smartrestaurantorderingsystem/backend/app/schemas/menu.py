from pydantic import BaseModel, Field
from datetime import datetime


class MenuItemResponse(BaseModel):
    id: int
    name: str
    category: str
    price: float
    prep_time_minutes: int
    is_available: bool
    updated_at: datetime

    class Config:
        from_attributes = True


class MenuItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    category: str = Field(..., min_length=1, max_length=100)
    price: float = Field(..., gt=0)
    prep_time_minutes: int = Field(..., gt=0)
    is_available: bool = True


class MenuItemUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=200)
    category: str | None = Field(None, min_length=1, max_length=100)
    price: float | None = Field(None, gt=0)
    prep_time_minutes: int | None = Field(None, gt=0)
    is_available: bool | None = None


class MenuGroupedResponse(BaseModel):
    categories: dict[str, list[MenuItemResponse]]
