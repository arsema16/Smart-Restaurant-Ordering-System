"""Menu browsing endpoints for guests."""

from typing import Annotated

from fastapi import APIRouter, Depends
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.redis_client import get_redis
from app.schemas.menu import MenuGroupedResponse
from app.services.menu_service import MenuService

router = APIRouter(prefix="/menu", tags=["menu"])


@router.get("", response_model=MenuGroupedResponse)
async def get_menu(
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
) -> MenuGroupedResponse:
    """
    Get all menu items grouped by category.
    
    Returns the complete menu with items organized by category. Includes
    availability status for each item.
    
    Requirements: 2.1, 2.2
    
    Args:
        db: Database session (injected)
        redis: Redis client (injected)
    
    Returns:
        MenuGroupedResponse with items grouped by category
    """
    menu_service = MenuService(db, redis)
    return await menu_service.get_menu_grouped_by_category()
