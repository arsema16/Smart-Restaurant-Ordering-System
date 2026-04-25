# Recommendation Engine

This module implements the AI-powered personalized recommendation system for the Smart Restaurant Ordering System.

## Architecture

The recommendation engine uses a two-tier approach:

1. **Collaborative Filtering** (when user has ordering history)
   - Uses item-item similarity based on co-occurrence in orders
   - Computes cosine similarity on order history
   - Weights recommendations by user's order frequency and recency

2. **Popularity Fallback** (when user is new)
   - Ranks items by global order frequency
   - Used when user has no ordering history

## Components

### `engine.py`
- `RecommendationEngine`: Protocol defining the interface
- `PreferenceProfile`: User preference data structure
- `RecommendedItem`: Recommendation result structure

### `collaborative.py`
- `CollaborativeEngine`: Item-item collaborative filtering implementation
- Builds similarity matrix from order history
- Caches recommendations in Redis (60s TTL)
- Implements upsell rules

### `fallback.py`
- `PopularityEngine`: Popularity-based recommendations
- Ranks by global order count
- Also implements upsell rules

### `service.py`
- `RecommendationService`: Unified service that selects appropriate engine
- Manages background tasks for similarity matrix refresh
- Handles cache invalidation

### `manager.py`
- Global service initialization and lifecycle management
- Used in FastAPI lifespan events

## Features

### Caching
- Recommendations cached in Redis with key: `rec:{user_id}:{cart_hash}`
- 60-second TTL
- Cache invalidated on cart changes

### Upsell Rules
If cart contains a main course and recommendations don't include beverage/dessert, the engine automatically appends one complementary item.

### Background Tasks
- Similarity matrix rebuilt every 15 minutes
- Uses APScheduler for task scheduling
- Runs asynchronously without blocking requests

## Usage Example

```python
from sqlalchemy.ext.asyncio import AsyncSession
from redis.asyncio import Redis
from app.recommendation.service import RecommendationService
from app.recommendation.engine import PreferenceProfile

# Initialize service
db: AsyncSession = ...
redis: Redis = ...
service = RecommendationService(db, redis)

# Start background tasks
service.start_background_tasks()

# Create user profile
profile = PreferenceProfile(
    persistent_user_id="user123",
    most_ordered_items=[
        {"item_id": 5, "count": 3},
        {"item_id": 12, "count": 2}
    ],
    recently_ordered_items=[5, 12, 8]
)

# Get recommendations
cart_item_ids = [5]  # Items currently in cart
available_item_ids = [1, 2, 3, 4, 6, 7, 8, 9, 10]  # Available menu items

recommendations, algorithm = await service.get_recommendations(
    profile=profile,
    cart_item_ids=cart_item_ids,
    available_item_ids=available_item_ids,
    limit=5
)

# recommendations is a list of RecommendedItem objects
# algorithm is either "collaborative" or "popularity"

# Invalidate cache when user places order
await service.invalidate_cache("user123")

# Stop background tasks on shutdown
service.stop_background_tasks()
```

## Integration with FastAPI

Add to `app/main.py`:

```python
from app.recommendation.manager import (
    init_recommendation_service,
    stop_recommendation_service,
    get_recommendation_service
)
from app.database import get_db
from app.redis_client import get_redis

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_redis()
    
    # Initialize recommendation service
    db = await anext(get_db())
    redis = await get_redis()
    await init_recommendation_service(db, redis)
    
    yield
    
    # Shutdown
    stop_recommendation_service()
    await close_redis()
```

## Requirements Mapping

- **8.1**: Generates up to 5 recommendations based on profile
- **8.2**: Excludes items already in cart
- **8.3**: Excludes unavailable items
- **8.4**: Implements upsell rule for main course + beverage/dessert
- **8.5**: Falls back to popularity ranking for new users
- **8.6**: Updates recommendations within 1s via caching; background refresh every 15min

## Testing

Property-based tests validate:
- Recommendation exclusion and size limits (Property 16)
- Upsell inclusion when main course present (Property 17)
- Popularity fallback ordering (Property 18)

See `tests/unit/test_recommendation_*.py` for test implementations.
