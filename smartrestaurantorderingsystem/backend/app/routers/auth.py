"""Authentication endpoints for staff login and token refresh."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.staff_user import StaffUser
from app.schemas.auth import LoginRequest, TokenResponse
from app.services.auth_service import (
    create_access_token,
    create_refresh_token,
    decode_token,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
async def login(
    credentials: LoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """
    Staff login endpoint.
    
    Validates username and password, returns JWT access and refresh tokens.
    
    Requirements: 5.6
    
    Args:
        credentials: Login credentials with username and password
        db: Database session (injected)
    
    Returns:
        TokenResponse with access_token, refresh_token, and expiration
    
    Raises:
        HTTPException: 401 if credentials are invalid or user is inactive
    """
    # Fetch staff user by username
    result = await db.execute(
        select(StaffUser).where(StaffUser.username == credentials.username)
    )
    staff = result.scalar_one_or_none()
    
    # Validate user exists and is active
    if not staff or not staff.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify password
    if not verify_password(credentials.password, staff.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Generate tokens
    access_token = create_access_token(staff.username, staff.role)
    refresh_token = create_refresh_token(staff.username)
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=1800,  # 30 minutes in seconds
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    refresh_token: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """
    Refresh access token using a valid refresh token.
    
    Requirements: 5.6
    
    Args:
        refresh_token: Valid refresh token
        db: Database session (injected)
    
    Returns:
        TokenResponse with new access_token and refresh_token
    
    Raises:
        HTTPException: 401 if refresh token is invalid or expired
    """
    try:
        # Decode and validate refresh token
        payload = decode_token(refresh_token)
        
        # Verify token type
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Extract username
        username = payload.get("sub")
        if not username:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Fetch staff user
        result = await db.execute(
            select(StaffUser).where(StaffUser.username == username)
        )
        staff = result.scalar_one_or_none()
        
        if not staff or not staff.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Generate new tokens
        new_access_token = create_access_token(staff.username, staff.role)
        new_refresh_token = create_refresh_token(staff.username)
        
        return TokenResponse(
            access_token=new_access_token,
            refresh_token=new_refresh_token,
            token_type="bearer",
            expires_in=1800,  # 30 minutes in seconds
        )
    
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
