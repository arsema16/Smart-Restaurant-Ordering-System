"""Session management endpoints for QR code scanning and session resumption."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.redis_client import get_redis
from app.schemas.session import SessionCreateRequest, SessionCreateResponse
from app.services.session_service import create_session, resume_session

router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.post("", response_model=SessionCreateResponse, status_code=status.HTTP_201_CREATED)
async def create_or_resume_session(
    request: SessionCreateRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
) -> SessionCreateResponse:
    """
    Create a new table session or resume an existing one.
    
    When a user scans a QR code, this endpoint is called with the table identifier.
    If a session_token is provided, the existing session is resumed. Otherwise,
    a new session is created.
    
    Requirements: 1.1, 1.2, 1.3, 1.4
    
    Args:
        request: Session creation request with table_identifier and optional session_token
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        SessionCreateResponse with session_id, session_token, and is_new flag
    """
    # Try to resume existing session if token provided
    if request.session_token:
        existing_session = await resume_session(db, redis, request.session_token)
        if existing_session:
            return SessionCreateResponse(
                session_id=existing_session.id,
                session_token=existing_session.session_token,
                table_identifier=existing_session.table_identifier,
                is_new=False,
            )
    
    # Create new session
    new_session = await create_session(
        db,
        redis,
        request.table_identifier,
        request.persistent_user_id,
    )
    await db.commit()
    
    return SessionCreateResponse(
        session_id=new_session.id,
        session_token=new_session.session_token,
        table_identifier=new_session.table_identifier,
        is_new=True,
    )


@router.get("/{session_id}")
async def get_session_state(
    session_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """
    Get full session state including cart and order history.
    
    Used for session restoration after page reload or device switch.
    
    Requirements: 10.1, 10.2, 10.5
    
    Args:
        session_id: The table session UUID
        db: Database session (injected)
    
    Returns:
        Full session state with cart and orders
    
    Raises:
        HTTPException: 404 if session not found
    """
    from sqlalchemy import select
    from app.models.table_session import TableSession
    from app.services.cart_service import CartService
    from app.services.order_service import OrderService
    from app.redis_client import get_redis
    
    # Fetch session
    result = await db.execute(
        select(TableSession).where(TableSession.id == session_id)
    )
    session = result.scalar_one_or_none()
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Session with ID {session_id} not found"
        )
    
    # Get cart and orders
    redis = await get_redis()
    cart_service = CartService(db)
    order_service = OrderService(db, redis)
    
    cart = await cart_service.get_cart(session_id)
    orders = await order_service.get_orders_for_session(session_id)
    
    return {
        "session_id": session.id,
        "table_identifier": session.table_identifier,
        "created_at": session.created_at,
        "last_active_at": session.last_active_at,
        "is_active": session.is_active,
        "cart": cart,
        "orders": orders,
    }
