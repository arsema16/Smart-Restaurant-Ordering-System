"""Preference profile service for tracking user ordering behavior.

This service handles:
- Creating and retrieving user preference profiles
- Updating profiles when orders are placed
- Maintaining most-ordered items (top 5 by count)
- Maintaining recently ordered items (last 10)

Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
"""

from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_profile import UserProfile


async def get_or_create_profile(
    db: AsyncSession,
    persistent_user_id: str,
) -> UserProfile:
    """
    Get an existing user profile or create an empty one.
    
    If the user has no prior order history, initializes an empty profile
    with empty most_ordered_items and recently_ordered_items lists.
    
    Requirements: 7.4, 7.5
    
    Args:
        db: Async database session
        persistent_user_id: Unique identifier for the user across sessions
    
    Returns:
        UserProfile: The user's preference profile
    """
    # Try to fetch existing profile
    result = await db.execute(
        select(UserProfile).where(
            UserProfile.persistent_user_id == persistent_user_id
        )
    )
    profile = result.scalar_one_or_none()
    
    # Create empty profile if none exists
    if not profile:
        profile = UserProfile(
            persistent_user_id=persistent_user_id,
            most_ordered_items=[],
            recently_ordered_items=[],
        )
        db.add(profile)
        await db.flush()
    
    return profile


async def update_profile_on_order(
    db: AsyncSession,
    persistent_user_id: str,
    ordered_item_ids: list[int],
) -> UserProfile:
    """
    Update user preference profile when an order is placed.
    
    Updates:
    1. most_ordered_items: Increments count for each ordered item, keeps top 5
    2. recently_ordered_items: Prepends ordered items, keeps last 10
    
    Requirements: 7.1, 7.2, 7.3
    
    Args:
        db: Async database session
        persistent_user_id: Unique identifier for the user
        ordered_item_ids: List of menu item IDs from the order
    
    Returns:
        UserProfile: The updated profile
    """
    profile = await get_or_create_profile(db, persistent_user_id)
    
    # Update most_ordered_items
    # Convert to dict for easier manipulation: {item_id: count}
    most_ordered_dict = {
        item["item_id"]: item["count"]
        for item in profile.most_ordered_items
    }
    
    # Increment count for each ordered item
    for item_id in ordered_item_ids:
        most_ordered_dict[item_id] = most_ordered_dict.get(item_id, 0) + 1
    
    # Sort by count descending and take top 5
    sorted_items = sorted(
        most_ordered_dict.items(),
        key=lambda x: x[1],
        reverse=True,
    )[:5]
    
    profile.most_ordered_items = [
        {"item_id": item_id, "count": count}
        for item_id, count in sorted_items
    ]
    
    # Update recently_ordered_items
    # Prepend new items and keep last 10 unique items
    recent_items = list(ordered_item_ids)
    
    # Add existing recent items that aren't in the new order
    for item_id in profile.recently_ordered_items:
        if item_id not in recent_items:
            recent_items.append(item_id)
    
    # Keep only last 10
    profile.recently_ordered_items = recent_items[:10]
    
    await db.flush()
    
    return profile


async def get_most_ordered_items(
    db: AsyncSession,
    persistent_user_id: str,
) -> list[dict]:
    """
    Get the top 5 most-ordered items for a user.
    
    Requirements: 7.2
    
    Args:
        db: Async database session
        persistent_user_id: Unique identifier for the user
    
    Returns:
        list[dict]: List of dicts with item_id and count, max 5 items
    """
    profile = await get_or_create_profile(db, persistent_user_id)
    return profile.most_ordered_items


async def get_recently_ordered_items(
    db: AsyncSession,
    persistent_user_id: str,
) -> list[int]:
    """
    Get the last 10 ordered items for a user.
    
    Requirements: 7.3
    
    Args:
        db: Async database session
        persistent_user_id: Unique identifier for the user
    
    Returns:
        list[int]: List of menu item IDs, max 10 items
    """
    profile = await get_or_create_profile(db, persistent_user_id)
    return profile.recently_ordered_items
