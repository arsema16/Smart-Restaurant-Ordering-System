"""Pytest configuration and fixtures for testing."""
import asyncio
import os
from typing import AsyncGenerator, Generator

import pytest
import pytest_asyncio
from httpx import AsyncClient
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from app.database import Base, get_db
from app.redis_client import get_redis
from app.config import settings

# Test database URL (use a separate test database)
TEST_DATABASE_URL = settings.database_url.replace("/restaurant_db", "/restaurant_test_db")
TEST_REDIS_URL = os.getenv("TEST_REDIS_URL", "redis://localhost:6379/15")


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="function")
async def db_engine():
    """Create a test database engine."""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False, future=True)
    
    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    yield engine
    
    # Drop all tables after test
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    await engine.dispose()


@pytest_asyncio.fixture(scope="function")
async def db_session(db_engine) -> AsyncGenerator[AsyncSession, None]:
    """Create a test database session.
    
    This fixture provides a clean database session for each test.
    All changes are rolled back after the test completes.
    """
    # Create session factory
    async_session = async_sessionmaker(
        db_engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with async_session() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def redis_client() -> AsyncGenerator[Redis, None]:
    """Get Redis client for testing.
    
    Uses a separate Redis database (15) for testing to avoid
    conflicts with development data.
    """
    client = Redis.from_url(TEST_REDIS_URL, decode_responses=True)
    
    # Ensure we're using the test database
    await client.select(15)
    
    yield client
    
    # Clean up test data
    await client.flushdb()
    await client.close()


@pytest_asyncio.fixture
async def test_client(db_session: AsyncSession, redis_client: Redis) -> AsyncGenerator[AsyncClient, None]:
    """Create a test HTTP client with dependency overrides.
    
    This fixture provides a fully configured test client with:
    - Database session override
    - Redis client override
    - Base URL set to http://test
    """
    from app.main import app
    
    # Override database dependency
    async def override_get_db():
        yield db_session
    
    # Override Redis dependency
    async def override_get_redis():
        return redis_client
    
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_redis] = override_get_redis
    
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac
    
    app.dependency_overrides.clear()


# Hypothesis profile configuration
from hypothesis import settings as hypothesis_settings, Verbosity

# Register custom Hypothesis profiles
hypothesis_settings.register_profile("default", max_examples=200, deadline=5000)
hypothesis_settings.register_profile("ci", max_examples=500, deadline=10000)
hypothesis_settings.register_profile("dev", max_examples=50, deadline=2000)
hypothesis_settings.register_profile("debug", max_examples=10, verbosity=Verbosity.verbose)

# Load profile from environment or use default
hypothesis_settings.load_profile(os.getenv("HYPOTHESIS_PROFILE", "default"))
