"""Example unit tests to demonstrate testing patterns."""
import pytest


@pytest.mark.unit
def test_example_sync():
    """Example synchronous unit test."""
    assert 1 + 1 == 2


@pytest.mark.unit
async def test_example_async():
    """Example asynchronous unit test."""
    # Simulate async operation
    result = await async_add(1, 1)
    assert result == 2


async def async_add(a: int, b: int) -> int:
    """Helper function for testing."""
    return a + b


@pytest.mark.unit
class TestExampleClass:
    """Example test class grouping related tests."""
    
    def test_method_one(self):
        """Test method one."""
        assert True
    
    def test_method_two(self):
        """Test method two."""
        assert not False
