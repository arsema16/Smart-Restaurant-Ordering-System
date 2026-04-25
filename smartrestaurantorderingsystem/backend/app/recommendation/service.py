"""Unified recommendation service with engine selection and background tasks."""

import asyncio
from typing import Optional
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from sqlalchemy.ext.asyncio import AsyncSession
from redis.asyncio import Redis

from app.recommendation.engine import PreferenceProfile, RecommendedItem
from app.recommendation.collaborative import CollaborativeEngine
from app.recommendation.fallback import PopularityEngine


class RecommendationService:
    """
    Unified recommendation service.
    
    Selects between collaborative filtering (when user has history) and
    popularity-based fallback (when user is new). Manages background tasks
    for similarity matrix refresh.
    
    Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
    """
    
    def __init__(self, db: AsyncSession, redis: Redis):
        self.db = db
        self.redis = redis
        self.collaborative_engine = CollaborativeEngine(db, redis)
        self.popularity_engine = PopularityEngine(db, redis)
        self.scheduler: Optional[AsyncIOScheduler] = None
    
    async def get_recommendations(
        self,
        profile: PreferenceProfile,
        cart_item_ids: list[int],
        available_item_ids: list[int],
        limit: int = 5,
    ) -> tuple[list[RecommendedItem], str]:
        """
        Generate personalized recommendations.
        
        Returns:
            Tuple of (recommendations, algorithm_used)
            
        Requirements: 8.1, 8.2, 8.3, 8.4, 8.5
        """
        # Choose engine based on profile
        if profile.most_ordered_items:
            # User has history - use collaborative filtering
            recommendations = await self.collaborative_engine.get_recommendations(
                profile, cart_item_ids, available_item_ids, limit
            )
            algorithm = "collaborative"
        else:
            # New user - use popularity fallback
            recommendations = await self.popularity_engine.get_recommendations(
                profile, cart_item_ids, available_item_ids, limit
            )
            algorithm = "popularity"
        
        return recommendations, algorithm
    
    def start_background_tasks(self) -> None:
        """
        Start background task to rebuild similarity matrix every 15 minutes.
        
        Requirements: 8.6
        """
        if self.scheduler is not None:
            return  # Already started
        
        self.scheduler = AsyncIOScheduler()
        
        # Schedule similarity matrix rebuild every 15 minutes
        self.scheduler.add_job(
            self._rebuild_similarity_matrix,
            'interval',
            minutes=15,
            id='rebuild_similarity_matrix',
            replace_existing=True
        )
        
        self.scheduler.start()
    
    def stop_background_tasks(self) -> None:
        """Stop background tasks."""
        if self.scheduler:
            self.scheduler.shutdown()
            self.scheduler = None
    
    async def _rebuild_similarity_matrix(self) -> None:
        """Background task to rebuild similarity matrix."""
        try:
            await self.collaborative_engine.rebuild_similarity_matrix()
            print("Similarity matrix rebuilt successfully")
        except Exception as e:
            print(f"Error rebuilding similarity matrix: {e}")
    
    async def invalidate_cache(self, persistent_user_id: str) -> None:
        """
        Invalidate recommendation cache for a user.
        
        Called when user places an order or cart changes significantly.
        
        Requirements: 8.6
        """
        # Delete all cache keys for this user
        pattern = f"rec:{persistent_user_id}:*"
        cursor = 0
        while True:
            cursor, keys = await self.redis.scan(cursor, match=pattern, count=100)
            if keys:
                await self.redis.delete(*keys)
            if cursor == 0:
                break
