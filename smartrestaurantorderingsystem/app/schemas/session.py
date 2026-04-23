"""Session-related Pydantic schemas."""

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class SessionCreateRequest(BaseModel):
    """Request body for creating or resuming a session."""

    table_identifier: str = Field(..., min_length=1, max_length=64)
    session_token: Optional[str] = Field(None, description="Existing token to resume session")
    persistent_user_id: Optional[str] = Field(None, max_length=128, description="User ID that survives session changes")


class SessionCreateResponse(BaseModel):
    """Response after creating or resuming a session."""

    session_id: UUID
    session_token: str
    table_identifier: str
    is_new: bool = Field(..., description="True if new session created, False if resumed")


class SessionStateResponse(BaseModel):
    """Full session state including cart and orders."""

    session_id: UUID
    table_identifier: str
    created_at: datetime
    last_active_at: datetime
    is_active: bool
    cart: "CartResponse"  # Forward reference
    orders: list["OrderResponse"]  # Forward reference

    class Config:
        from_attributes = True


# Import here to avoid circular dependency
from app.schemas.cart import CartResponse
from app.schemas.order import OrderResponse

SessionStateResponse.model_rebuild()
