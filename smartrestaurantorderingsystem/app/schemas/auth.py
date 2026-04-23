"""Authentication-related Pydantic schemas."""

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    """Request schema for staff login."""

    username: str = Field(..., min_length=1, max_length=128)
    password: str = Field(..., min_length=1)


class TokenResponse(BaseModel):
    """Response schema for authentication tokens."""

    access_token: str
    refresh_token: str
    token_type: str = Field(default="bearer")
    expires_in: int = Field(..., description="Access token expiration time in seconds")
