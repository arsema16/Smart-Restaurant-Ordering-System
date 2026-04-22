"""Example integration tests to demonstrate testing patterns."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.integration
async def test_database_session(db_session: AsyncSession):
    """Example test using database session fixture."""
    # Database session is available and ready to use
    assert db_session is not None
    
    # Example: Execute a simple query
    result = await db_session.execute("SELECT 1 as value")
    row = result.fetchone()
    assert row[0] == 1


@pytest.mark.integration
async def test_redis_client(redis_client):
    """Example test using Redis client fixture."""
    # Redis client is available and ready to use
    assert redis_client is not None
    
    # Example: Set and get a value
    await redis_client.set("test_key", "test_value")
    value = await redis_client.get("test_key")
    assert value == "test_value"


@pytest.mark.integration
async def test_http_client(test_client: AsyncClient):
    """Example test using HTTP client fixture."""
    # Test client is available and ready to use
    assert test_client is not None
    
    # Example: Make a request (will fail until endpoints are implemented)
    # response = await test_client.get("/api/v1/health")
    # assert response.status_code == 200
