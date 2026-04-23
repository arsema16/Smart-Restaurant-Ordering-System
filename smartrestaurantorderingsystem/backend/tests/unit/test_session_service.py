"""Unit tests for session service.

This module contains example-based tests for specific scenarios
and edge cases in the session management service.
"""
import pytest
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from redis.asyncio import Redis

from app.services import session_service
from app.models.table_session import TableSession


@pytest.mark.asyncio
async def test_generate_session_token_format():
    """Test that generated tokens have the correct format."""
    token = session_service.generate_session_token()
    
    # Token should start with "tok_"
    assert token.startswith("tok_"), f"Token should start with 'tok_' but got: {token}"
    
    # Token should be sufficiently long (tok_ + 43 chars from urlsafe_b64encode(32 bytes))
    assert len(token) > 40, f"Token too short: {len(token)} chars"
    
    # Token should be URL-safe (no special chars that need encoding)
    assert all(c.isalnum() or c in "-_" for c in token[4:]), (
        "Token contains non-URL-safe characters"
    )


@pytest.mark.asyncio
async def test_generate_session_token_uniqueness():
    """Test that multiple token generations produce unique tokens."""
    tokens = [session_service.generate_session_token() for _ in range(100)]
    
    # All tokens should be unique
    assert len(tokens) == len(set(tokens)), "Generated tokens are not unique"


@pytest.mark.asyncio
async def test_create_session(db_session: AsyncSession, redis_client: Redis):
    """Test creating a new session."""
    table_id = "table-42"
    user_id = "user-abc123"
    
    session = await session_service.create_session(
        db=db_session,
        redis=redis_client,
        table_identifier=table_id,
        persistent_user_id=user_id,
    )
    
    # Verify session properties
    assert session.table_identifier == table_id
    assert session.persistent_user_id == user_id
    assert session.session_token.startswith("tok_")
    assert session.is_active is True
    assert isinstance(session.id, UUID)
    
    # Verify token is cached in Redis
    cache_key = f"session:{session.session_token}"
    cached_id = await redis_client.get(cache_key)
    assert cached_id == str(session.id)


@pytest.mark.asyncio
async def test_create_session_without_persistent_user_id(
    db_session: AsyncSession,
    redis_client: Redis
):
    """Test creating a session without a persistent user ID."""
    session = await session_service.create_session(
        db=db_session,
        redis=redis_client,
        table_identifier="table-7",
        persistent_user_id=None,
    )
    
    assert session.persistent_user_id is None
    assert session.is_active is True


@pytest.mark.asyncio
async def test_resume_session_from_cache(
    db_session: AsyncSession,
    redis_client: Redis
):
    """Test resuming a session from Redis cache."""
    # Create a session
    original_session = await session_service.create_session(
        db=db_session,
        redis=redis_client,
        table_identifier="table-10",
        persistent_user_id="user-xyz",
    )
    
    await db_session.commit()
    
    # Resume the session (should hit Redis cache)
    resumed_session = await session_service.resume_session(
        db=db_session,
        redis=redis_client,
        session_token=original_session.session_token,
    )
    
    assert resumed_session is not None
    assert resumed_session.id == original_session.id
    assert resumed_session.table_identifier == original_session.table_identifier
    assert resumed_session.persistent_user_id == original_session.persistent_user_id


@pytest.mark.asyncio
async def test_resume_session_from_database(
    db_session: AsyncSession,
    redis_client: Redis
):
    """Test resuming a session from database when cache misses."""
    # Create a session
    original_session = await session_service.create_session(
        db=db_session,
        redis=redis_client,
        table_identifier="table-20",
        persistent_user_id="user-123",
    )
    
    await db_session.commit()
    
    # Clear Redis cache to force database lookup
    cache_key = f"session:{original_session.session_token}"
    await redis_client.delete(cache_key)
    
    # Resume the session (should hit database and repopulate cache)
    resumed_session = await session_service.resume_session(
        db=db_session,
        redis=redis_client,
        session_token=original_session.session_token,
    )
    
    assert resumed_session is not None
    assert resumed_session.id == original_session.id
    
    # Verify cache was repopulated
    cached_id = await redis_client.get(cache_key)
    assert cached_id == str(original_session.id)


@pytest.mark.asyncio
async def test_resume_session_invalid_token(
    db_session: AsyncSession,
    redis_client: Redis
):
    """Test resuming with an invalid token returns None."""
    resumed_session = await session_service.resume_session(
        db=db_session,
        redis=redis_client,
        session_token="tok_invalid_token_12345",
    )
    
    assert resumed_session is None


@pytest.mark.asyncio
async def test_resume_session_inactive_session(
    db_session: AsyncSession,
    redis_client: Redis
):
    """Test resuming an inactive session returns None."""
    # Create a session
    session = await session_service.create_session(
        db=db_session,
        redis=redis_client,
        table_identifier="table-30",
    )
    
    # Mark session as inactive
    session.is_active = False
    await db_session.commit()
    
    # Try to resume
    resumed_session = await session_service.resume_session(
        db=db_session,
        redis=redis_client,
        session_token=session.session_token,
    )
    
    assert resumed_session is None


@pytest.mark.asyncio
async def test_validate_session_token_valid(
    db_session: AsyncSession,
    redis_client: Redis
):
    """Test validating a valid session token."""
    # Create a session
    session = await session_service.create_session(
        db=db_session,
        redis=redis_client,
        table_identifier="table-40",
    )
    
    await db_session.commit()
    
    # Validate the token
    session_id = await session_service.validate_session_token(
        db=db_session,
        redis=redis_client,
        token=session.session_token,
    )
    
    assert session_id == session.id


@pytest.mark.asyncio
async def test_validate_session_token_invalid(
    db_session: AsyncSession,
    redis_client: Redis
):
    """Test validating an invalid token raises 401."""
    with pytest.raises(HTTPException) as exc_info:
        await session_service.validate_session_token(
            db=db_session,
            redis=redis_client,
            token="tok_invalid_token_xyz",
        )
    
    assert exc_info.value.status_code == 401
    assert "Invalid or expired session token" in exc_info.value.detail


@pytest.mark.asyncio
async def test_validate_session_token_inactive(
    db_session: AsyncSession,
    redis_client: Redis
):
    """Test validating an inactive session token raises 401."""
    # Create a session
    session = await session_service.create_session(
        db=db_session,
        redis=redis_client,
        table_identifier="table-50",
    )
    
    # Mark as inactive
    session.is_active = False
    await db_session.commit()
    
    # Try to validate
    with pytest.raises(HTTPException) as exc_info:
        await session_service.validate_session_token(
            db=db_session,
            redis=redis_client,
            token=session.session_token,
        )
    
    assert exc_info.value.status_code == 401


@pytest.mark.asyncio
async def test_session_last_active_at_updates(
    db_session: AsyncSession,
    redis_client: Redis
):
    """Test that last_active_at is updated on session resume."""
    # Create a session
    session = await session_service.create_session(
        db=db_session,
        redis=redis_client,
        table_identifier="table-60",
    )
    
    original_last_active = session.last_active_at
    await db_session.commit()
    
    # Wait a moment and resume
    import asyncio
    await asyncio.sleep(0.1)
    
    resumed_session = await session_service.resume_session(
        db=db_session,
        redis=redis_client,
        session_token=session.session_token,
    )
    
    # last_active_at should be updated
    assert resumed_session.last_active_at > original_last_active
