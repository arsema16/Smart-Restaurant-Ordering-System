"""Authentication schemas for staff login and token management."""

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    """Staff login request schema."""
    
    username: str = Field(..., min_length=3, max_length=128, description="Staff username")
    password: str = Field(..., min_length=6, description="Staff password")
    
    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "username": "staff",
                    "password": "password"
                }
            ]
        }
    }


class TokenResponse(BaseModel):
    """JWT token response schema."""
    
    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="JWT refresh token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(default=1800, description="Access token expiration time in seconds (30 minutes)")
    
    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                    "token_type": "bearer",
                    "expires_in": 1800
                }
            ]
        }
    }


class TokenRefreshRequest(BaseModel):
    """Token refresh request schema."""
    
    refresh_token: str = Field(..., description="JWT refresh token")


class StaffUserResponse(BaseModel):
    """Staff user response schema."""
    
    id: int
    username: str
    role: str
    is_active: bool
    
    model_config = {
        "from_attributes": True
    }
