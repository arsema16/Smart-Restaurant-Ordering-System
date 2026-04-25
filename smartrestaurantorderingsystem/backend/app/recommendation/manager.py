"""Global recommendation service manager."""

from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from redis.asyncio import Redis

from app.recommendation.service import RecommendationService

# Global recommendation service instance
_recommendation_service: Optional[RecommendationService] = None


async def init_recommendation_service(db: AsyncSession, redis: Redis) -> None:
    """
    Initialize the global recommendation service and start background tasks.
    
    Should be called during application startup.
    """
    global _recommendation_service
    
    _recommendation_service = RecommendationService(db, redis)
    _recommendation_service.start_background_tasks()
    print("Recommendation service initialized with background tasks")


def stop_recommendation_service() -> None:
    """
    Stop the recommendation service background tasks.
    
    Should be called during application shutdown.
    """
    global _recommendation_service
    
    if _recommendation_service:
        _recommendation_service.stop_background_tasks()
        _recommendation_service = None
        print("Recommendation service stopped")


def get_recommendation_service() -> Optional[RecommendationService]:
    """Get the global recommendation service instance."""
    return _recommendation_service
