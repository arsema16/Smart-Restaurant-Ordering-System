from redis.asyncio import Redis, ConnectionPool
from typing import Optional

from app.config import settings

# Global Redis connection pool
_redis_pool: Optional[ConnectionPool] = None
_redis_client: Optional[Redis] = None


async def init_redis() -> None:
    """Initialize Redis connection pool."""
    global _redis_pool, _redis_client
    
    _redis_pool = ConnectionPool.from_url(
        settings.redis_url,
        decode_responses=True,
        max_connections=50,
    )
    _redis_client = Redis(connection_pool=_redis_pool)


async def close_redis() -> None:
    """Close Redis connection pool."""
    global _redis_pool, _redis_client
    
    if _redis_client:
        await _redis_client.close()
    if _redis_pool:
        await _redis_pool.disconnect()


async def get_redis() -> Redis:
    """Dependency for getting Redis client."""
    if _redis_client is None:
        await init_redis()
    return _redis_client
