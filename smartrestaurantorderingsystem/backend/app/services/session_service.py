"""Session management service for table-based user sessions.

This service handles:
- Session token generation
- Session creation and resumption
- Session validation
- Redis caching for fast token lookup

Requirements: 1.1, 1.2, 1.3, 1.4, 1.6
"""

import secrets
from datetime import datetime, timedelta
from typing import Optional
from uuid import UUID

from fastapi import HTTPException, status
from redis.asyncio import Redis
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.table_session import TableSession


# Redis cache TTL for session tokens (24 hours)
SESSION_CACHE_TTL = 86400


def generate_session_token() -> str:
    """
    Generate a unique, non-guessable session token.
    
    Uses secrets.token_urlsafe for cryptographically strong random generation.
    Format: "tok_" + 43 URL-safe characters (32 bytes base64-encoded).
    
    Requirements: 1.2
    
    Returns:
        str: A unique session token (e.g., "tok_abc123...")
    """
    return "tok_" + secrets.token_urlsafe(32)


async def create_session(
    db: AsyncSession,
    redis: Redis,
    table_identifier: str,
    persistent_user_id: Optional[str] = None,
) -> TableSession:
    """
    Create a new table session with a unique token.
    
    The session is persisted to PostgreSQL and the token is cached in Redis
    for fast lookup. The session token allows users to resume their session
    across page reloads and device switches.
    
    Requirements: 1.1, 1.2, 1.3
    
    Args:
        db: Async database session
        redis: Redis client
        table_identifier: Unique identifier for the restaurant table
        persistent_user_id: Optional user ID that survives session changes
    
    Returns:
        TableSession: The newly created session
    """
    # Generate unique session token
    session_token = generate_session_token()
    
    # Create session record
    session = TableSession(
        table_identifier=table_identifier,
        session_token=session_token,
        persistent_user_id=persistent_user_id,
        created_at=datetime.utcnow(),
        last_active_at=datetime.utcnow(),
        is_active=True,
    )
    
    db.add(session)
    await db.flush()  # Get the generated UUID
    
    # Cache token in Redis for fast lookup: session:{token} -> session_id
    cache_key = f"session:{session_token}"
    await redis.setex(
        cache_key,
        SESSION_CACHE_TTL,
        str(session.id),
    )
    
    return session


async def resume_session(
    db: AsyncSession,
    redis: Redis,
    session_token: str,
) -> Optional[TableSession]:
    """
    Resume an existing session using a session token.
    
    First checks Redis cache for fast lookup, falls back to database if not cached.
    Updates last_active_at timestamp to track session activity.
    
    Requirements: 1.3, 1.4
    
    Args:
        db: Async database session
        redis: Redis client
        session_token: The session token to look up
    
    Returns:
        TableSession if found and active, None otherwise
    """
    session: Optional[TableSession] = None
    
    # Try Redis cache first
    cache_key = f"session:{session_token}"
    cached_session_id = await redis.get(cache_key)
    
    if cached_session_id:
        # Cache hit - fetch from database by ID
        result = await db.execute(
            select(TableSession).where(TableSession.id == UUID(cached_session_id))
        )
        session = result.scalar_one_or_none()
    else:
        # Cache miss - query database by token
        result = await db.execute(
            select(TableSession).where(TableSession.session_token == session_token)
        )
        session = result.scalar_one_or_none()
        
        # Repopulate cache if found
        if session:
            await redis.setex(
                cache_key,
                SESSION_CACHE_TTL,
                str(session.id),
            )
    
    # Update last_active_at if session found and active
    if session and session.is_active:
        session.last_active_at = datetime.utcnow()
        await db.flush()
        return session
    
    return None


async def validate_session_token(
    db: AsyncSession,
    redis: Redis,
    token: str,
) -> UUID:
    """
    Validate a session token and return the session ID.
    
    Raises HTTP 401 if the token is invalid, expired, or the session is inactive.
    
    Requirements: 1.6
    
    Args:
        db: Async database session
        redis: Redis client
        token: The session token to validate
    
    Returns:
        UUID: The session ID if valid
    
    Raises:
        HTTPException: 401 if token is invalid or expired
    """
    session = await resume_session(db, redis, token)
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session token",
        )
    
    return session.id
