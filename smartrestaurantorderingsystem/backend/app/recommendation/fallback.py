"""Popularity-based fallback recommendation engine."""

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from redis.asyncio import Redis

from app.models.menu_item import MenuItem
from app.models.order import OrderItem
from app.recommendation.engine import PreferenceProfile, RecommendedItem


class PopularityEngine:
    """
    Popularity-based recommendation engine.
    
    Ranks items by global order frequency. Used as fallback when user
    has no ordering history.
    
    Requirements: 8.5
    """
    
    def __init__(self, db: AsyncSession, redis: Redis):
        self.db = db
        self.redis = redis
        self.item_details: dict[int, dict] = {}
        self.item_categories: dict[int, str] = {}
    
    async def get_recommendations(
        self,
        profile: PreferenceProfile,
        cart_item_ids: list[int],
        available_item_ids: list[int],
        limit: int = 5,
    ) -> list[RecommendedItem]:
        """
        Generate popularity-based recommendations.
        
        Requirements: 8.1, 8.2, 8.3, 8.5
        """
        # Load item details if not loaded
        if not self.item_details:
            await self._load_item_details()
        
        # Get global order counts
        order_counts = await self._get_order_counts()
        
        # Filter and sort
        candidates = []
        for item_id, count in order_counts.items():
            # Skip if in cart or unavailable
            if item_id in cart_item_ids or item_id not in available_item_ids:
                continue
            
            if item_id in self.item_details:
                candidates.append((item_id, count))
        
        # Sort by count descending
        candidates.sort(key=lambda x: x[1], reverse=True)
        
        # Take top N
        top_candidates = candidates[:limit]
        
        # Build RecommendedItem objects
        recommendations = []
        max_count = top_candidates[0][1] if top_candidates else 1
        
        for item_id, count in top_candidates:
            details = self.item_details[item_id]
            recommendations.append(RecommendedItem(
                menu_item_id=item_id,
                name=details["name"],
                category=details["category"],
                price=float(details["price"]),
                prep_time_minutes=details["prep_time_minutes"],
                score=count / max_count,  # Normalize to 0-1
                reason="Popular choice"
            ))
        
        # Apply upsell rule
        recommendations = await self._apply_upsell_rule(
            recommendations, cart_item_ids, available_item_ids, limit
        )
        
        return recommendations
    
    async def _apply_upsell_rule(
        self,
        recommendations: list[RecommendedItem],
        cart_item_ids: list[int],
        available_item_ids: list[int],
        limit: int,
    ) -> list[RecommendedItem]:
        """
        Apply upsell rule: if cart has main_course and recommendations lack
        beverage/dessert, append one.
        
        Requirements: 8.4
        """
        # Check if cart has main course
        has_main_course = any(
            self.item_categories.get(item_id) == "main_course"
            for item_id in cart_item_ids
        )
        
        if not has_main_course:
            return recommendations
        
        # Check if recommendations already have beverage or dessert
        has_upsell = any(
            rec.category in ["beverage", "dessert"]
            for rec in recommendations
        )
        
        if has_upsell:
            return recommendations
        
        # Find highest-scoring available beverage or dessert not in cart
        upsell_candidates = [
            item_id for item_id in available_item_ids
            if item_id not in cart_item_ids
            and self.item_categories.get(item_id) in ["beverage", "dessert"]
        ]
        
        if not upsell_candidates:
            return recommendations
        
        # Get the first available upsell item
        upsell_id = upsell_candidates[0]
        if upsell_id in self.item_details:
            details = self.item_details[upsell_id]
            upsell_item = RecommendedItem(
                menu_item_id=upsell_id,
                name=details["name"],
                category=details["category"],
                price=float(details["price"]),
                prep_time_minutes=details["prep_time_minutes"],
                score=0.8,
                reason="Complements your main course"
            )
            
            # Append to recommendations (may exceed limit by 1)
            if len(recommendations) < limit:
                recommendations.append(upsell_item)
            else:
                # Replace lowest-scoring recommendation
                recommendations[-1] = upsell_item
        
        return recommendations
    
    async def _load_item_details(self) -> None:
        """Load menu item details into memory."""
        result = await self.db.execute(select(MenuItem))
        items = result.scalars().all()
        
        for item in items:
            self.item_details[item.id] = {
                "name": item.name,
                "category": item.category,
                "price": item.price,
                "prep_time_minutes": item.prep_time_minutes,
                "is_available": item.is_available,
            }
            self.item_categories[item.id] = item.category
    
    async def _get_order_counts(self) -> dict[int, int]:
        """Get global order counts for all menu items."""
        # Try cache first
        cached = await self.redis.get("popularity_counts")
        if cached:
            import json
            return {int(k): v for k, v in json.loads(cached).items()}
        
        # Query database
        result = await self.db.execute(
            select(
                OrderItem.menu_item_id,
                func.count(OrderItem.id).label("order_count")
            )
            .group_by(OrderItem.menu_item_id)
        )
        
        counts = {row.menu_item_id: row.order_count for row in result}
        
        # Cache for 5 minutes
        import json
        await self.redis.setex(
            "popularity_counts",
            300,
            json.dumps(counts)
        )
        
        return counts
