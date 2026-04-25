"""Personalized recommendation endpoints for guests."""

from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from redis.asyncio import Redis
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.session import validate_session_token
from app.models.menu_item import MenuItem
from app.models.table_session import TableSession
from app.redis_client import get_redis
from app.recommendation.engine import PreferenceProfile
from app.recommendation.service import RecommendationService
from app.schemas.recommendation import RecommendationResponse, RecommendedItem
from app.services.cart_service import CartService
from app.services.preference_profile_service import get_or_create_profile

router = APIRouter(prefix="/recommendations", tags=["recommendations"])


@router.get("", response_model=RecommendationResponse)
async def get_recommendations(
    session_id: Annotated[UUID, Depends(validate_session_token)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[Redis, Depends(get_redis)],
    limit: int = Query(5, ge=1, le=10, description="Maximum number of recommendations"),
) -> RecommendationResponse:
    """
    Get personalized menu recommendations for the current user.
    
    Uses collaborative filtering when the user has order history, falls back
    to popularity-based recommendations for new users. Excludes items already
    in the cart and unavailable items. Includes upsell suggestions when
    appropriate.
    
    Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
    
    Args:
        session_id: Validated session ID from token (injected)
        db: Database session (injected)
        redis: Redis client (injected)
        limit: Maximum number of recommendations (default 5)
    
    Returns:
        RecommendationResponse with up to 5 recommended items
    """
    # Get session to retrieve persistent_user_id
    result = await db.execute(
        select(TableSession).where(TableSession.id == session_id)
    )
    session = result.scalar_one_or_none()
    
    if not session or not session.persistent_user_id:
        # No persistent user ID - return empty recommendations
        return RecommendationResponse(
            recommendations=[],
            has_profile=False,
            algorithm_used="none",
        )
    
    # Get user preference profile
    profile_model = await get_or_create_profile(db, session.persistent_user_id)
    
    # Convert to engine format
    profile = PreferenceProfile(
        persistent_user_id=profile_model.persistent_user_id,
        most_ordered_items=profile_model.most_ordered_items,
        recently_ordered_items=profile_model.recently_ordered_items,
    )
    
    # Get current cart items
    cart_service = CartService(db)
    cart = await cart_service.get_cart(session_id)
    cart_item_ids = [item.menu_item_id for item in cart.items]
    
    # Get all available menu items
    result = await db.execute(
        select(MenuItem.id).where(MenuItem.is_available == True)
    )
    available_item_ids = [row[0] for row in result.all()]
    
    # Get recommendations
    recommendation_service = RecommendationService(db, redis)
    recommendations, algorithm = await recommendation_service.get_recommendations(
        profile=profile,
        cart_item_ids=cart_item_ids,
        available_item_ids=available_item_ids,
        limit=limit,
    )
    
    has_profile = bool(profile.most_ordered_items)
    
    return RecommendationResponse(
        recommendations=recommendations,
        has_profile=has_profile,
        algorithm_used=algorithm,
    )
