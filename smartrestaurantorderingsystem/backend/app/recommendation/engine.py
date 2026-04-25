"""Recommendation engine interface and base types."""

from typing import Protocol, runtime_checkable
from dataclasses import dataclass


@dataclass
class PreferenceProfile:
    """User preference profile for recommendations."""
    
    persistent_user_id: str
    most_ordered_items: list[dict]  # [{item_id: int, count: int}]
    recently_ordered_items: list[int]  # [item_id]


@dataclass
class RecommendedItem:
    """A recommended menu item with metadata."""
    
    menu_item_id: int
    name: str
    category: str
    price: float
    prep_time_minutes: int
    score: float
    reason: str


@runtime_checkable
class RecommendationEngine(Protocol):
    """
    Protocol defining the recommendation engine interface.
    
    Implementations must provide personalized recommendations based on
    user preference profiles, current cart state, and available menu items.
    
    Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
    """
    
    async def get_recommendations(
        self,
        profile: PreferenceProfile,
        cart_item_ids: list[int],
        available_item_ids: list[int],
        limit: int = 5,
    ) -> list[RecommendedItem]:
        """
        Generate personalized recommendations.
        
        Args:
            profile: User's preference profile with ordering history
            cart_item_ids: Items currently in the user's cart
            available_item_ids: Menu items that are currently available
            limit: Maximum number of recommendations to return (default 5)
            
        Returns:
            List of recommended items, excluding cart items and unavailable items
            
        Requirements: 8.1, 8.2, 8.3
        """
        ...
