"""Menu service for CRUD operations and availability management."""

import json
from typing import Optional

from fastapi import HTTPException
from redis.asyncio import Redis
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.menu_item import MenuItem
from app.schemas.menu import (
    MenuGroupedResponse,
    MenuItemCreate,
    MenuItemResponse,
    MenuItemUpdate,
)


class MenuService:
    """
    Service for managing menu items.
    
    Handles CRUD operations, availability toggling, and real-time
    availability change broadcasting via Redis pub/sub.
    
    Requirements: 2.1, 2.2, 2.3, 2.4, 9.1, 9.2, 9.3, 9.4
    """

    def __init__(self, db: AsyncSession, redis: Redis):
        self.db = db
        self.redis = redis

    async def get_menu_grouped_by_category(self) -> MenuGroupedResponse:
        """
        Get all menu items grouped by category.
        
        Returns a dictionary where keys are category names and values are
        lists of menu items in that category.
        
        Requirements: 2.1, 2.2
        """
        result = await self.db.execute(select(MenuItem))
        items = result.scalars().all()
        
        # Group items by category
        categories: dict[str, list[MenuItemResponse]] = {}
        for item in items:
            item_response = MenuItemResponse.model_validate(item)
            if item.category not in categories:
                categories[item.category] = []
            categories[item.category].append(item_response)
        
        return MenuGroupedResponse(
            categories=categories,
            total_items=len(items)
        )

    async def get_menu_item(self, item_id: int) -> MenuItem:
        """
        Get a single menu item by ID.
        
        Args:
            item_id: The menu item ID
            
        Returns:
            MenuItem model instance
            
        Raises:
            HTTPException: 404 if item not found
            
        Requirements: 2.1
        """
        result = await self.db.execute(
            select(MenuItem).where(MenuItem.id == item_id)
        )
        item = result.scalar_one_or_none()
        
        if item is None:
            raise HTTPException(status_code=404, detail=f"Menu item {item_id} not found")
        
        return item

    async def create_menu_item(self, data: MenuItemCreate) -> MenuItem:
        """
        Create a new menu item.
        
        Validates that price and prep_time_minutes are positive.
        Admin-only operation (enforced at router level).
        
        Args:
            data: Menu item creation data
            
        Returns:
            Created MenuItem model instance
            
        Requirements: 9.1, 9.2, 9.3
        """
        # Validation is handled by Pydantic schema
        menu_item = MenuItem(
            name=data.name,
            category=data.category,
            price=data.price,
            prep_time_minutes=data.prep_time_minutes,
            is_available=data.is_available,
        )
        
        self.db.add(menu_item)
        await self.db.flush()
        await self.db.refresh(menu_item)
        
        return menu_item

    async def update_menu_item(self, item_id: int, data: MenuItemUpdate) -> MenuItem:
        """
        Update an existing menu item.
        
        Only updates fields that are provided in the request.
        Validates that price and prep_time_minutes are positive if provided.
        
        Args:
            item_id: The menu item ID to update
            data: Menu item update data (partial)
            
        Returns:
            Updated MenuItem model instance
            
        Raises:
            HTTPException: 404 if item not found
            
        Requirements: 9.1, 9.2, 9.3, 9.4
        """
        item = await self.get_menu_item(item_id)
        
        # Update only provided fields
        update_data = data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(item, field, value)
        
        await self.db.flush()
        await self.db.refresh(item)
        
        return item

    async def toggle_availability(
        self, item_id: int, is_available: bool
    ) -> MenuItem:
        """
        Toggle menu item availability and broadcast change to all clients.
        
        Publishes a Redis event to the 'menu:availability' channel so that
        all connected guests receive real-time updates.
        
        Args:
            item_id: The menu item ID
            is_available: New availability status
            
        Returns:
            Updated MenuItem model instance
            
        Raises:
            HTTPException: 404 if item not found
            
        Requirements: 2.3, 2.4, 9.4
        """
        item = await self.get_menu_item(item_id)
        
        # Update availability
        item.is_available = is_available
        await self.db.flush()
        await self.db.refresh(item)
        
        # Publish availability change event to Redis
        event = {
            "event": "menu_item_availability_changed",
            "payload": {
                "item_id": item_id,
                "is_available": is_available,
                "item_name": item.name,
            }
        }
        await self.redis.publish("menu:availability", json.dumps(event))
        
        return item


async def get_menu_service(
    db: AsyncSession,
    redis: Redis,
) -> MenuService:
    """Dependency for getting MenuService instance."""
    return MenuService(db, redis)
