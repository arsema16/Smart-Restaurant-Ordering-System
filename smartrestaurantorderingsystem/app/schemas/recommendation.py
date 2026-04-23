"""Recommendation-related Pydantic schemas."""

from decimal import Decimal

from pydantic import BaseModel, Field


class RecommendedItem(BaseModel):
    """A single recommended menu item with score."""

    menu_item_id: int
    name: str
    category: str
    price: Decimal = Field(..., decimal_places=2)
    prep_time_minutes: int
    score: float = Field(..., ge=0, le=1, description="Recommendation confidence score (0-1)")
    reason: str = Field(..., description="Why this item was recommended")

    class Config:
        from_attributes = True


class RecommendationResponse(BaseModel):
    """Response schema for personalized recommendations."""

    recommendations: list[RecommendedItem] = Field(
        ..., max_length=5, description="Up to 5 recommended items"
    )
    has_profile: bool = Field(..., description="Whether user has ordering history")
    algorithm_used: str = Field(..., description="collaborative or popularity")
