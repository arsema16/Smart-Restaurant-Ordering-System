"""Staff menu management endpoints."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.auth import get_current_staff, require_admin
from app.models.staff_user import StaffUser
from app.redis_client import get_redis
from app.schemas.menu import MenuGroupedResponse, MenuItemCreate, MenuItemResponse, MenuItemUpdate
from app.services.menu_service import MenuService

router = APIRouter(prefix="/staff/menu", tags=["staff-menu"])


@router.get("", response_model=MenuGroupedResponse)
async def get_all_menu_items(
    staff: Annotated[StaffUser, Depends(get_current_staff)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
) -> MenuGroupedResponse:
    """
    Get all menu items including unavailable ones (staff view).
    
    Requirements: 9.1
    
    Args:
        staff: Authenticated staff user (injected)
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        MenuGroupedResponse with all items grouped by category
    """
    menu_service = MenuService(db, redis)
    return await menu_service.get_menu_grouped_by_category()


@router.post("", response_model=MenuItemResponse, status_code=status.HTTP_201_CREATED)
async def create_menu_item(
    item: MenuItemCreate,
    staff: Annotated[StaffUser, Depends(require_admin)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
) -> MenuItemResponse:
    """
    Create a new menu item (admin only).
    
    Validates that price and prep_time_minutes are positive.
    
    Requirements: 9.1, 9.2, 9.3
    
    Args:
        item: Menu item creation data
        staff: Authenticated admin user (injected)
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        MenuItemResponse for the created item
    
    Raises:
        HTTPException: 403 if user is not admin, 422 if validation fails
    """
    menu_service = MenuService(db, redis)
    created_item = await menu_service.create_menu_item(item)
    await db.commit()
    
    return MenuItemResponse.model_validate(created_item)


@router.put("/{item_id}", response_model=MenuItemResponse)
async def update_menu_item(
    item_id: int,
    item: MenuItemUpdate,
    staff: Annotated[StaffUser, Depends(get_current_staff)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
) -> MenuItemResponse:
    """
    Update an existing menu item.
    
    Only updates fields that are provided in the request.
    Validates that price and prep_time_minutes are positive if provided.
    
    Requirements: 9.1, 9.2, 9.3, 9.4
    
    Args:
        item_id: The menu item ID to update
        item: Menu item update data (partial)
        staff: Authenticated staff user (injected)
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        MenuItemResponse for the updated item
    
    Raises:
        HTTPException: 404 if item not found, 422 if validation fails
    """
    menu_service = MenuService(db, redis)
    updated_item = await menu_service.update_menu_item(item_id, item)
    await db.commit()
    
    return MenuItemResponse.model_validate(updated_item)


@router.patch("/{item_id}/availability", response_model=MenuItemResponse)
async def toggle_menu_item_availability(
    item_id: int,
    is_available: bool,
    staff: Annotated[StaffUser, Depends(get_current_staff)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
) -> MenuItemResponse:
    """
    Toggle menu item availability and broadcast change to all clients.
    
    Publishes a Redis event so all connected guests receive real-time updates.
    
    Requirements: 2.3, 2.4, 9.4
    
    Args:
        item_id: The menu item ID
        is_available: New availability status
        staff: Authenticated staff user (injected)
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        MenuItemResponse for the updated item
    
    Raises:
        HTTPException: 404 if item not found
    """
    menu_service = MenuService(db, redis)
    updated_item = await menu_service.toggle_availability(item_id, is_available)
    await db.commit()
    
    return MenuItemResponse.model_validate(updated_item)
