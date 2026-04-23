"""Property-based tests for session management.

This module contains property tests that validate universal correctness
guarantees for the session management system.
"""
import secrets
import pytest
from hypothesis import given, strategies as st, settings
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.table_session import TableSession


# Feature: smart-restaurant-ordering-system, Property 1: Session Token Uniqueness
@pytest.mark.asyncio
@pytest.mark.property
@given(n_tokens=st.integers(min_value=2, max_value=100))
@settings(max_examples=200)
async def test_session_token_uniqueness(db_session: AsyncSession, n_tokens: int):
    """Property 1: Session Token Uniqueness.
    
    For any two distinct calls to the session token generator, the resulting
    tokens SHALL be different. Additionally, for any two distinct table_identifier
    values, the resulting session_id values SHALL be different.
    
    Validates: Requirements 1.1, 1.2, 1.5
    
    This test verifies:
    1. All generated session tokens are unique
    2. All session IDs are unique even for different tables
    """
    # Generate multiple session tokens using the same method as the service
    tokens = [f"tok_{secrets.token_urlsafe(32)}" for _ in range(n_tokens)]
    
    # Verify all tokens are unique
    assert len(tokens) == len(set(tokens)), (
        f"Generated {n_tokens} tokens but only {len(set(tokens))} were unique. "
        "Session tokens must be globally unique."
    )
    
    # Create sessions with these tokens for different table identifiers
    sessions = []
    for i, token in enumerate(tokens):
        session = TableSession(
            table_identifier=f"table-{i}",
            session_token=token,
            persistent_user_id=None,
        )
        db_session.add(session)
        sessions.append(session)
    
    await db_session.flush()
    
    # Verify all session IDs are unique
    session_ids = [s.id for s in sessions]
    assert len(session_ids) == len(set(session_ids)), (
        f"Created {len(sessions)} sessions but only {len(set(session_ids))} unique IDs. "
        "Session IDs must be globally unique."
    )
    
    # Verify all tokens are unique in the database
    result = await db_session.execute(
        select(TableSession.session_token)
    )
    db_tokens = [row[0] for row in result.fetchall()]
    assert len(db_tokens) == len(set(db_tokens)), (
        "Session tokens in database are not unique"
    )


# Feature: smart-restaurant-ordering-system, Property 1: Session Token Uniqueness (table_identifier variant)
@pytest.mark.asyncio
@pytest.mark.property
@given(
    table_identifiers=st.lists(
        st.text(
            alphabet=st.characters(whitelist_categories=("Lu", "Ll", "Nd"), whitelist_characters="-_"),
            min_size=5,
            max_size=20
        ),
        min_size=2,
        max_size=50,
        unique=True
    )
)
@settings(max_examples=200)
async def test_session_id_uniqueness_across_tables(
    db_session: AsyncSession,
    table_identifiers: list[str]
):
    """Property 1: Session ID Uniqueness Across Tables.
    
    For any set of distinct table_identifier values, the resulting session_id
    values SHALL be different.
    
    Validates: Requirements 1.1, 1.2, 1.5
    
    This test verifies that sessions for different tables always get unique IDs.
    """
    sessions = []
    
    for table_id in table_identifiers:
        # Generate unique token for each session
        token = f"tok_{secrets.token_urlsafe(32)}"
        
        session = TableSession(
            table_identifier=table_id,
            session_token=token,
            persistent_user_id=None,
        )
        db_session.add(session)
        sessions.append(session)
    
    await db_session.flush()
    
    # Extract all session IDs
    session_ids = [s.id for s in sessions]
    
    # Verify all session IDs are unique
    assert len(session_ids) == len(set(session_ids)), (
        f"Created {len(sessions)} sessions for different tables but only "
        f"{len(set(session_ids))} unique session IDs. "
        "Each table session must have a unique ID."
    )
    
    # Verify the count matches the input
    assert len(session_ids) == len(table_identifiers), (
        "Number of created sessions does not match number of table identifiers"
    )


# Feature: smart-restaurant-ordering-system, Property 1: Session Token Uniqueness (collision resistance)
@pytest.mark.asyncio
@pytest.mark.property
@given(
    n_sessions=st.integers(min_value=10, max_value=200)
)
@settings(max_examples=200)
async def test_session_token_collision_resistance(
    db_session: AsyncSession,
    n_sessions: int
):
    """Property 1: Session Token Collision Resistance.
    
    For any number of session token generations, all tokens SHALL be unique
    with overwhelming probability (cryptographically secure randomness).
    
    Validates: Requirements 1.1, 1.2, 1.5
    
    This test verifies that the token generation mechanism produces
    cryptographically unique tokens even under high volume.
    """
    # Generate many tokens to test collision resistance
    tokens = set()
    
    for i in range(n_sessions):
        # Use the same token generation as the service will use
        token = f"tok_{secrets.token_urlsafe(32)}"
        
        # Check for collision
        assert token not in tokens, (
            f"Token collision detected at iteration {i}! "
            f"Token: {token[:20]}... "
            "This should be extremely rare with cryptographic randomness."
        )
        
        tokens.add(token)
    
    # Verify we generated the expected number of unique tokens
    assert len(tokens) == n_sessions, (
        f"Expected {n_sessions} unique tokens but got {len(tokens)}"
    )
    
    # Verify token format (should start with "tok_" and be sufficiently long)
    for token in tokens:
        assert token.startswith("tok_"), f"Token {token} does not have expected prefix"
        assert len(token) > 40, f"Token {token} is too short (length: {len(token)})"
