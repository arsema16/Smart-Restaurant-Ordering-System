"""Order placement and tracking endpoints for guests."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.session import validate_session_token
from app.redis_client import get_redis
from app.schemas.order import OrderResponse
from app.services.order_service import OrderService

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post("", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def place_order(
    session_id: Annotated[UUID, Depends(validate_session_token)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
) -> OrderResponse:
    """
    Place an order from the current cart contents.
    
    Creates an Order with items from the cart, clears the cart, sets initial
    status to "Received", and notifies staff dashboard in real-time.
    
    Requirements: 4.1, 4.2, 4.3, 4.4, 4.6
    
    Args:
        session_id: Validated session ID from token (injected)
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        OrderResponse with order details and estimated wait time
    
    Raises:
        HTTPException: 422 if cart is empty
    """
    order_service = OrderService(db, redis)
    return await order_service.place_order(session_id)


@router.get("", response_model=list[OrderResponse])
async def get_orders(
    session_id: Annotated[UUID, Depends(validate_session_token)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
) -> list[OrderResponse]:
    """
    Get all orders for the current session (order history).
    
    Returns all orders placed within the current table session, including
    delivered orders.
    
    Requirements: 4.5, 6.4
    
    Args:
        session_id: Validated session ID from token (injected)
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        List of OrderResponse for the session
    """
    order_service = OrderService(db, redis)
    return await order_service.get_orders_for_session(session_id)
