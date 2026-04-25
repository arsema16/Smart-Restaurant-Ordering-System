"""Cart service for managing user shopping carts."""

from decimal import Decimal
from typing import Optional
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models.cart import CartItem
from app.models.menu_item import MenuItem
from app.schemas.cart import CartItemDetail, CartResponse


class CartService:
    """
    Service for managing cart operations.
    
    Handles adding, updating, removing items from carts, and calculating totals.
    Validates menu item availability before cart operations.
    
    Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
    """
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_cart(self, session_id: UUID) -> CartResponse:
        """
        Get the current cart for a session.
        
        Returns cart with all items, their details, and total price.
        
        Args:
            session_id: The table session UUID
            
        Returns:
            CartResponse with items and total_price
            
        Requirements: 3.4
        """
        # Query cart items with joined menu item data
        query = (
            select(CartItem, MenuItem)
            .join(MenuItem, CartItem.menu_item_id == MenuItem.id)
            .where(CartItem.session_id == session_id)
            .order_by(CartItem.added_at)
        )
        
        result = await self.db.execute(query)
        rows = result.all()
        
        items = []
        total_price = Decimal("0.00")
        
        for cart_item, menu_item in rows:
            subtotal = menu_item.price * cart_item.quantity
            total_price += subtotal
            
            items.append(
                CartItemDetail(
                    id=cart_item.id,
                    menu_item_id=menu_item.id,
                    menu_item_name=menu_item.name,
                    category=menu_item.category,
                    unit_price=menu_item.price,
                    quantity=cart_item.quantity,
                    subtotal=subtotal,
                    added_at=cart_item.added_at,
                )
            )
        
        return CartResponse(
            items=items,
            total_price=total_price,
            item_count=len(items),
        )
    
    async def add_item(
        self,
        session_id: UUID,
        menu_item_id: int,
        quantity: int = 1,
    ) -> CartResponse:
        """
        Add an item to the cart or increment quantity if already present.
        
        Validates that the menu item exists and is available before adding.
        
        Args:
            session_id: The table session UUID
            menu_item_id: The menu item ID to add
            quantity: Quantity to add (default 1)
            
        Returns:
            Updated CartResponse
            
        Raises:
            HTTPException: 404 if menu item not found, 409 if unavailable
            
        Requirements: 3.1, 3.2, 2.3
        """
        # Validate menu item exists and is available
        menu_item = await self._get_menu_item(menu_item_id)
        
        if not menu_item.is_available:
            raise HTTPException(
                status_code=409,
                detail=f"Item '{menu_item.name}' is no longer available"
            )
        
        # Check if item already in cart
        query = select(CartItem).where(
            CartItem.session_id == session_id,
            CartItem.menu_item_id == menu_item_id
        )
        result = await self.db.execute(query)
        existing_item = result.scalar_one_or_none()
        
        if existing_item:
            # Increment quantity
            existing_item.quantity += quantity
        else:
            # Add new cart item
            new_item = CartItem(
                session_id=session_id,
                menu_item_id=menu_item_id,
                quantity=quantity,
            )
            self.db.add(new_item)
        
        await self.db.commit()
        
        return await self.get_cart(session_id)
    
    async def update_item_quantity(
        self,
        session_id: UUID,
        menu_item_id: int,
        quantity: int,
    ) -> CartResponse:
        """
        Update the quantity of an item in the cart.
        
        If quantity is zero, removes the item from the cart.
        
        Args:
            session_id: The table session UUID
            menu_item_id: The menu item ID to update
            quantity: New quantity (0 to remove)
            
        Returns:
            Updated CartResponse
            
        Raises:
            HTTPException: 404 if item not in cart
            
        Requirements: 3.3
        """
        # Find cart item
        query = select(CartItem).where(
            CartItem.session_id == session_id,
            CartItem.menu_item_id == menu_item_id
        )
        result = await self.db.execute(query)
        cart_item = result.scalar_one_or_none()
        
        if not cart_item:
            raise HTTPException(
                status_code=404,
                detail=f"Item with ID {menu_item_id} not found in cart"
            )
        
        if quantity == 0:
            # Remove item
            await self.db.delete(cart_item)
        else:
            # Update quantity
            cart_item.quantity = quantity
        
        await self.db.commit()
        
        return await self.get_cart(session_id)
    
    async def remove_item(
        self,
        session_id: UUID,
        menu_item_id: int,
    ) -> CartResponse:
        """
        Remove an item from the cart.
        
        Args:
            session_id: The table session UUID
            menu_item_id: The menu item ID to remove
            
        Returns:
            Updated CartResponse
            
        Raises:
            HTTPException: 404 if item not in cart
            
        Requirements: 3.3
        """
        # Find and delete cart item
        query = select(CartItem).where(
            CartItem.session_id == session_id,
            CartItem.menu_item_id == menu_item_id
        )
        result = await self.db.execute(query)
        cart_item = result.scalar_one_or_none()
        
        if not cart_item:
            raise HTTPException(
                status_code=404,
                detail=f"Item with ID {menu_item_id} not found in cart"
            )
        
        await self.db.delete(cart_item)
        await self.db.commit()
        
        return await self.get_cart(session_id)
    
    async def clear_cart(self, session_id: UUID) -> None:
        """
        Remove all items from the cart.
        
        Args:
            session_id: The table session UUID
            
        Requirements: 3.5
        """
        query = delete(CartItem).where(CartItem.session_id == session_id)
        await self.db.execute(query)
        await self.db.commit()
    
    async def remove_unavailable_items(self, session_id: UUID) -> list[str]:
        """
        Remove items from cart that are no longer available.
        
        Returns list of removed item names for notification purposes.
        
        Args:
            session_id: The table session UUID
            
        Returns:
            List of removed item names
            
        Requirements: 3.6
        """
        # Find cart items with unavailable menu items
        query = (
            select(CartItem, MenuItem)
            .join(MenuItem, CartItem.menu_item_id == MenuItem.id)
            .where(
                CartItem.session_id == session_id,
                MenuItem.is_available == False
            )
        )
        
        result = await self.db.execute(query)
        rows = result.all()
        
        removed_items = []
        
        for cart_item, menu_item in rows:
            removed_items.append(menu_item.name)
            await self.db.delete(cart_item)
        
        if removed_items:
            await self.db.commit()
        
        return removed_items
    
    async def _get_menu_item(self, menu_item_id: int) -> MenuItem:
        """
        Helper method to fetch a menu item by ID.
        
        Args:
            menu_item_id: The menu item ID
            
        Returns:
            MenuItem instance
            
        Raises:
            HTTPException: 404 if menu item not found
        """
        query = select(MenuItem).where(MenuItem.id == menu_item_id)
        result = await self.db.execute(query)
        menu_item = result.scalar_one_or_none()
        
        if not menu_item:
            raise HTTPException(
                status_code=404,
                detail=f"Menu item with ID {menu_item_id} not found"
            )
        
        return menu_item


# Dependency for getting cart service
async def get_cart_service(db: AsyncSession) -> CartService:
    """FastAPI dependency for cart service."""
    return CartService(db)
