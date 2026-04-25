"""Cart management endpoints for guests."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.session import validate_session_token
from app.schemas.cart import CartItemAdd, CartItemUpdate, CartResponse
from app.services.cart_service import CartService

router = APIRouter(prefix="/cart", tags=["cart"])


@router.get("", response_model=CartResponse)
async def get_cart(
    session_id: Annotated[UUID, Depends(validate_session_token)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CartResponse:
    """
    Get current cart contents for the session.
    
    Returns all items in the cart with quantities, prices, and total.
    
    Requirements: 3.4
    
    Args:
        session_id: Validated session ID from token (injected)
        db: Database session (injected)
    
    Returns:
        CartResponse with items and total_price
    """
    cart_service = CartService(db)
    return await cart_service.get_cart(session_id)


@router.post("/items", response_model=CartResponse, status_code=status.HTTP_201_CREATED)
async def add_cart_item(
    item: CartItemAdd,
    session_id: Annotated[UUID, Depends(validate_session_token)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CartResponse:
    """
    Add an item to the cart or increment quantity if already present.
    
    Validates that the menu item exists and is available before adding.
    
    Requirements: 3.1, 3.2, 2.3
    
    Args:
        item: Cart item to add with menu_item_id and quantity
        session_id: Validated session ID from token (injected)
        db: Database session (injected)
    
    Returns:
        Updated CartResponse
    
    Raises:
        HTTPException: 404 if menu item not found, 409 if unavailable
    """
    cart_service = CartService(db)
    return await cart_service.add_item(
        session_id,
        item.menu_item_id,
        item.quantity,
    )


@router.patch("/items/{item_id}", response_model=CartResponse)
async def update_cart_item(
    item_id: int,
    update: CartItemUpdate,
    session_id: Annotated[UUID, Depends(validate_session_token)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CartResponse:
    """
    Update the quantity of an item in the cart.
    
    Set quantity to 0 to remove the item from the cart.
    
    Requirements: 3.3
    
    Args:
        item_id: Menu item ID to update
        update: New quantity (0 to remove)
        session_id: Validated session ID from token (injected)
        db: Database session (injected)
    
    Returns:
        Updated CartResponse
    
    Raises:
        HTTPException: 404 if item not in cart
    """
    cart_service = CartService(db)
    return await cart_service.update_item_quantity(
        session_id,
        item_id,
        update.quantity,
    )


@router.delete("/items/{item_id}", response_model=CartResponse)
async def remove_cart_item(
    item_id: int,
    session_id: Annotated[UUID, Depends(validate_session_token)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CartResponse:
    """
    Remove an item from the cart.
    
    Requirements: 3.3
    
    Args:
        item_id: Menu item ID to remove
        session_id: Validated session ID from token (injected)
        db: Database session (injected)
    
    Returns:
        Updated CartResponse
    
    Raises:
        HTTPException: 404 if item not in cart
    """
    cart_service = CartService(db)
    return await cart_service.remove_item(session_id, item_id)
