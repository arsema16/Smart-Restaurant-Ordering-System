"""Staff order management endpoints."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.auth import get_current_staff
from app.models.staff_user import StaffUser
from app.redis_client import get_redis
from app.schemas.order import OrderResponse, OrderStatusUpdate
from app.services.order_service import OrderService

router = APIRouter(prefix="/staff/orders", tags=["staff-orders"])


@router.get("", response_model=list[OrderResponse])
async def get_active_orders(
    staff: Annotated[StaffUser, Depends(get_current_staff)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
) -> list[OrderResponse]:
    """
    Get all active orders (status != "Delivered") for staff dashboard.
    
    Returns orders sorted by creation time (oldest first) to help staff
    prioritize kitchen operations.
    
    Requirements: 5.1, 5.2
    
    Args:
        staff: Authenticated staff user (injected)
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        List of active OrderResponse objects
    """
    order_service = OrderService(db, redis)
    return await order_service.get_all_active_orders()


@router.patch("/{order_id}/status", response_model=OrderResponse)
async def update_order_status(
    order_id: UUID,
    status_update: OrderStatusUpdate,
    staff: Annotated[StaffUser, Depends(get_current_staff)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
) -> OrderResponse:
    """
    Update order status with transition validation.
    
    Validates that the status transition follows the allowed sequence:
    Received → Cooking → Ready → Delivered
    
    Broadcasts the status change to all connected clients in real-time.
    
    Requirements: 5.3, 5.4, 5.5
    
    Args:
        order_id: The order UUID to update
        status_update: New status to set
        staff: Authenticated staff user (injected)
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        Updated OrderResponse
    
    Raises:
        HTTPException: 404 if order not found, 422 if invalid transition
    """
    order_service = OrderService(db, redis)
    return await order_service.update_order_status(order_id, status_update.status)
