"""Test utilities and helper functions."""
from typing import Any, Dict
from datetime import datetime, timedelta
import secrets


def generate_test_session_token() -> str:
    """Generate a test session token."""
    return f"tok_{secrets.token_urlsafe(32)}"


def generate_test_jwt(username: str = "test_staff", role: str = "staff") -> str:
    """Generate a test JWT token.
    
    This is a placeholder - actual implementation will use the JWT service.
    """
    # TODO: Implement using actual JWT service once available
    return f"test_jwt_{username}_{role}"


def create_test_menu_item(
    name: str = "Test Item",
    category: str = "main_course",
    price: float = 12.99,
    prep_time_minutes: int = 15,
    is_available: bool = True
) -> Dict[str, Any]:
    """Create test menu item data."""
    return {
        "name": name,
        "category": category,
        "price": price,
        "prep_time_minutes": prep_time_minutes,
        "is_available": is_available,
    }


def create_test_order_data(
    session_id: str,
    items: list[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """Create test order data."""
    if items is None:
        items = [{"menu_item_id": 1, "quantity": 2}]
    
    return {
        "session_id": session_id,
        "items": items,
    }


def assert_timestamp_recent(timestamp: datetime, max_age_seconds: int = 5):
    """Assert that a timestamp is recent (within max_age_seconds)."""
    now = datetime.utcnow()
    age = (now - timestamp).total_seconds()
    assert age <= max_age_seconds, f"Timestamp is {age}s old, expected <= {max_age_seconds}s"


def assert_valid_uuid(uuid_string: str):
    """Assert that a string is a valid UUID."""
    import uuid
    try:
        uuid.UUID(uuid_string)
    except (ValueError, AttributeError):
        raise AssertionError(f"Invalid UUID: {uuid_string}")


def assert_valid_session_token(token: str):
    """Assert that a token has the expected format."""
    assert token.startswith("tok_"), f"Token should start with 'tok_', got: {token}"
    assert len(token) > 40, f"Token should be > 40 chars, got: {len(token)}"


def assert_valid_order_number(order_number: str):
    """Assert that an order number has the expected format."""
    assert order_number.startswith("ORD-"), f"Order number should start with 'ORD-', got: {order_number}"
    assert len(order_number) >= 8, f"Order number should be >= 8 chars, got: {len(order_number)}"


class MockWebSocket:
    """Mock WebSocket for testing."""
    
    def __init__(self):
        self.messages = []
        self.closed = False
    
    async def send_json(self, data: Dict[str, Any]):
        """Mock send_json method."""
        self.messages.append(data)
    
    async def receive_json(self) -> Dict[str, Any]:
        """Mock receive_json method."""
        if self.messages:
            return self.messages.pop(0)
        return {}
    
    async def close(self):
        """Mock close method."""
        self.closed = True


class AsyncContextManager:
    """Helper for creating async context managers in tests."""
    
    def __init__(self, value):
        self.value = value
    
    async def __aenter__(self):
        return self.value
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        pass
