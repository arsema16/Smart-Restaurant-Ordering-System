"""Session token validation middleware for guest endpoints."""

from typing import Annotated
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.redis_client import get_redis
from app.services.session_service import validate_session_token as validate_token


async def validate_session_token(
    x_session_token: Annotated[str, Header()],
    db: AsyncSession = Depends(get_db),
    redis: Redis = Depends(get_redis),
) -> UUID:
    """
    FastAPI dependency to validate session token from request header.
    
    Extracts the session token from the X-Session-Token header and validates it.
    Returns the session ID if valid, raises 401 if invalid or expired.
    
    This dependency should be applied to all guest endpoints that require
    an active table session.
    
    Requirements: 1.6
    
    Args:
        x_session_token: Session token from X-Session-Token header
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        UUID: The validated session ID
    
    Raises:
        HTTPException: 401 if token is invalid or expired
    
    Example:
        @router.get("/cart")
        async def get_cart(
            session_id: UUID = Depends(validate_session_token),
            db: AsyncSession = Depends(get_db)
        ):
            # session_id is now validated and available
            ...
    """
    if not x_session_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session token is required",
        )
    
    return await validate_token(db, redis, x_session_token)
