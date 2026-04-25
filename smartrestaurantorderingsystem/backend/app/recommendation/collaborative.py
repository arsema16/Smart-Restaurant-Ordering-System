"""Collaborative filtering recommendation engine using item-item similarity."""

import hashlib
import json
from typing import Optional
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from redis.asyncio import Redis

from app.models.menu_item import MenuItem
from app.models.order import Order, OrderItem
from app.recommendation.engine import PreferenceProfile, RecommendedItem


class CollaborativeEngine:
    """
    Collaborative filtering engine using item-item similarity.
    
    Uses cosine similarity on a co-occurrence matrix built from order history.
    Implements caching and upsell rules.
    
    Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
    """
    
    def __init__(self, db: AsyncSession, redis: Redis):
        self.db = db
        self.redis = redis
        self.similarity_matrix: Optional[dict[int, dict[int, float]]] = None
        self.item_categories: dict[int, str] = {}
        self.item_details: dict[int, dict] = {}
    
    async def get_recommendations(
        self,
        profile: PreferenceProfile,
        cart_item_ids: list[int],
        available_item_ids: list[int],
        limit: int = 5,
    ) -> list[RecommendedItem]:
        """
        Generate personalized recommendations using collaborative filtering.
        
        Requirements: 8.1, 8.2, 8.3, 8.4, 8.6
        """
        # Check cache first
        cart_hash = self._compute_cart_hash(cart_item_ids)
        cache_key = f"rec:{profile.persistent_user_id}:{cart_hash}"
        
        cached = await self.redis.get(cache_key)
        if cached:
            return self._deserialize_recommendations(cached)
        
        # Load item details if not loaded
        if not self.item_details:
            await self._load_item_details()
        
        # Load similarity matrix if not loaded
        if self.similarity_matrix is None:
            await self._load_similarity_matrix()
        
        # Generate recommendations
        recommendations = await self._generate_recommendations(
            profile, cart_item_ids, available_item_ids, limit
        )
        
        # Apply upsell rule
        recommendations = await self._apply_upsell_rule(
            recommendations, cart_item_ids, available_item_ids, limit
        )
        
        # Cache results
        await self.redis.setex(
            cache_key,
            60,  # 60 seconds TTL
            self._serialize_recommendations(recommendations)
        )
        
        return recommendations
    
    async def _generate_recommendations(
        self,
        profile: PreferenceProfile,
        cart_item_ids: list[int],
        available_item_ids: list[int],
        limit: int,
    ) -> list[RecommendedItem]:
        """Generate recommendations based on user profile and similarity."""
        if not profile.most_ordered_items:
            # Empty profile - no personalized recommendations
            return []
        
        # Score candidates based on similarity to user's most ordered items
        candidate_scores: dict[int, float] = {}
        
        for ordered_item in profile.most_ordered_items:
            item_id = ordered_item.get("item_id")
            count = ordered_item.get("count", 1)
            
            if item_id not in self.similarity_matrix:
                continue
            
            # Get similar items
            similar_items = self.similarity_matrix[item_id]
            
            for candidate_id, similarity in similar_items.items():
                # Skip if in cart or unavailable
                if candidate_id in cart_item_ids or candidate_id not in available_item_ids:
                    continue
                
                # Weight by order count and recency
                recency_weight = 1.0
                if candidate_id in profile.recently_ordered_items:
                    # Boost recently ordered items
                    recency_weight = 1.2
                
                score = similarity * count * recency_weight
                candidate_scores[candidate_id] = candidate_scores.get(candidate_id, 0) + score
        
        # Sort by score and take top N
        sorted_candidates = sorted(
            candidate_scores.items(),
            key=lambda x: x[1],
            reverse=True
        )[:limit]
        
        # Build RecommendedItem objects
        recommendations = []
        for item_id, score in sorted_candidates:
            if item_id in self.item_details:
                details = self.item_details[item_id]
                recommendations.append(RecommendedItem(
                    menu_item_id=item_id,
                    name=details["name"],
                    category=details["category"],
                    price=float(details["price"]),
                    prep_time_minutes=details["prep_time_minutes"],
                    score=min(score / 10.0, 1.0),  # Normalize to 0-1
                    reason="Based on your ordering history"
                ))
        
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
    
    async def _load_similarity_matrix(self) -> None:
        """
        Load or build item-item similarity matrix.
        
        The matrix is cached in Redis and rebuilt periodically by a background task.
        """
        # Try to load from Redis cache
        cached_matrix = await self.redis.get("similarity_matrix")
        if cached_matrix:
            self.similarity_matrix = json.loads(cached_matrix)
            # Convert string keys back to integers
            self.similarity_matrix = {
                int(k): {int(k2): v2 for k2, v2 in v.items()}
                for k, v in self.similarity_matrix.items()
            }
            return
        
        # Build from scratch
        await self._build_similarity_matrix()
    
    async def _build_similarity_matrix(self) -> None:
        """
        Build item-item similarity matrix from order history.
        
        Uses cosine similarity on co-occurrence matrix.
        """
        # Get all order items
        result = await self.db.execute(
            select(OrderItem.order_id, OrderItem.menu_item_id)
        )
        order_items = result.all()
        
        if not order_items:
            self.similarity_matrix = {}
            return
        
        # Build co-occurrence matrix
        # orders_by_item[item_id] = set of order_ids containing this item
        orders_by_item: dict[int, set] = {}
        for order_id, item_id in order_items:
            if item_id not in orders_by_item:
                orders_by_item[item_id] = set()
            orders_by_item[item_id].add(order_id)
        
        # Get unique item IDs
        item_ids = sorted(orders_by_item.keys())
        n_items = len(item_ids)
        
        if n_items == 0:
            self.similarity_matrix = {}
            return
        
        # Create binary matrix: rows = items, cols = orders
        # This is memory-efficient for sparse data
        item_id_to_idx = {item_id: idx for idx, item_id in enumerate(item_ids)}
        
        # Build co-occurrence counts
        co_occurrence = np.zeros((n_items, n_items))
        
        for item_id, order_set in orders_by_item.items():
            idx = item_id_to_idx[item_id]
            for other_item_id, other_order_set in orders_by_item.items():
                other_idx = item_id_to_idx[other_item_id]
                # Count how many orders contain both items
                co_occurrence[idx, other_idx] = len(order_set & other_order_set)
        
        # Compute cosine similarity
        # Avoid division by zero
        norms = np.sqrt(np.diag(co_occurrence))
        norms[norms == 0] = 1  # Prevent division by zero
        
        similarity = co_occurrence / (norms[:, None] * norms[None, :])
        
        # Convert to dict format: {item_id: {similar_item_id: score}}
        self.similarity_matrix = {}
        for idx, item_id in enumerate(item_ids):
            similar_items = {}
            for other_idx, other_item_id in enumerate(item_ids):
                if idx != other_idx and similarity[idx, other_idx] > 0.1:  # Threshold
                    similar_items[other_item_id] = float(similarity[idx, other_idx])
            
            # Sort by similarity and keep top 10
            sorted_similar = sorted(
                similar_items.items(),
                key=lambda x: x[1],
                reverse=True
            )[:10]
            self.similarity_matrix[item_id] = dict(sorted_similar)
        
        # Cache in Redis (convert int keys to strings for JSON)
        cache_data = {
            str(k): {str(k2): v2 for k2, v2 in v.items()}
            for k, v in self.similarity_matrix.items()
        }
        await self.redis.setex(
            "similarity_matrix",
            900,  # 15 minutes TTL
            json.dumps(cache_data)
        )
    
    async def rebuild_similarity_matrix(self) -> None:
        """Public method to rebuild similarity matrix (called by background task)."""
        await self._build_similarity_matrix()
    
    def _compute_cart_hash(self, cart_item_ids: list[int]) -> str:
        """Compute SHA-256 hash of sorted cart item IDs."""
        sorted_ids = sorted(cart_item_ids)
        cart_str = ",".join(map(str, sorted_ids))
        return hashlib.sha256(cart_str.encode()).hexdigest()[:16]
    
    def _serialize_recommendations(self, recommendations: list[RecommendedItem]) -> str:
        """Serialize recommendations to JSON string."""
        data = [
            {
                "menu_item_id": rec.menu_item_id,
                "name": rec.name,
                "category": rec.category,
                "price": rec.price,
                "prep_time_minutes": rec.prep_time_minutes,
                "score": rec.score,
                "reason": rec.reason,
            }
            for rec in recommendations
        ]
        return json.dumps(data)
    
    def _deserialize_recommendations(self, data: str) -> list[RecommendedItem]:
        """Deserialize recommendations from JSON string."""
        items = json.loads(data)
        return [
            RecommendedItem(
                menu_item_id=item["menu_item_id"],
                name=item["name"],
                category=item["category"],
                price=item["price"],
                prep_time_minutes=item["prep_time_minutes"],
                score=item["score"],
                reason=item["reason"],
            )
            for item in items
        ]
