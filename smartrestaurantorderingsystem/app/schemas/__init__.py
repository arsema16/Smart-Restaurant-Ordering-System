"""Pydantic schemas for request/response validation."""

from app.schemas.auth import LoginRequest, TokenResponse
from app.schemas.cart import CartItemAdd, CartItemDetail, CartItemUpdate, CartResponse
from app.schemas.menu import (
    MenuGroupedResponse,
    MenuItemCreate,
    MenuItemResponse,
    MenuItemUpdate,
)
from app.schemas.order import OrderItemDetail, OrderResponse, OrderStatusUpdate
from app.schemas.recommendation import RecommendedItem, RecommendationResponse
from app.schemas.session import (
    SessionCreateRequest,
    SessionCreateResponse,
    SessionStateResponse,
)

__all__ = [
    # Auth
    "LoginRequest",
    "TokenResponse",
    # Cart
    "CartItemAdd",
    "CartItemUpdate",
    "CartItemDetail",
    "CartResponse",
    # Menu
    "MenuItemResponse",
    "MenuItemCreate",
    "MenuItemUpdate",
    "MenuGroupedResponse",
    # Order
    "OrderItemDetail",
    "OrderResponse",
    "OrderStatusUpdate",
    # Recommendation
    "RecommendedItem",
    "RecommendationResponse",
    # Session
    "SessionCreateRequest",
    "SessionCreateResponse",
    "SessionStateResponse",
]
