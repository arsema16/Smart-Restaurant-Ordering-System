# Testing Infrastructure

This directory contains the test suite for the Smart Restaurant Ordering System backend.

## Directory Structure

```
tests/
├── conftest.py           # Pytest configuration and shared fixtures
├── unit/                 # Unit tests for individual components
├── integration/          # Integration tests for component interactions
└── e2e/                  # End-to-end tests for full workflows
```

## Test Types

### Unit Tests (`tests/unit/`)
- Test individual functions, classes, and methods in isolation
- Mock external dependencies (database, Redis, external APIs)
- Fast execution (< 1 second per test)
- High coverage of edge cases and error conditions

### Integration Tests (`tests/integration/`)
- Test interactions between multiple components
- Use real database and Redis instances (test databases)
- Test API endpoints with full request/response cycle
- Verify WebSocket connections and real-time updates

### End-to-End Tests (`tests/e2e/`)
- Test complete user workflows from start to finish
- Simulate real user scenarios (guest ordering, staff management)
- Verify system behavior across all layers

### Property-Based Tests
- Use Hypothesis to generate test cases automatically
- Validate universal correctness properties
- Tagged with `@pytest.mark.property`
- Configured to run 200 examples per property

## Running Tests

### Run all tests
```bash
pytest
```

### Run specific test types
```bash
pytest -m unit              # Run only unit tests
pytest -m integration       # Run only integration tests
pytest -m e2e              # Run only end-to-end tests
pytest -m property         # Run only property-based tests
```

### Run tests in a specific directory
```bash
pytest tests/unit/
pytest tests/integration/
pytest tests/e2e/
```

### Run with coverage
```bash
pytest --cov=app --cov-report=html --cov-report=term-missing
```

### Run with different Hypothesis profiles
```bash
HYPOTHESIS_PROFILE=dev pytest      # Fast (50 examples)
HYPOTHESIS_PROFILE=default pytest  # Standard (200 examples)
HYPOTHESIS_PROFILE=ci pytest       # Thorough (500 examples)
HYPOTHESIS_PROFILE=debug pytest    # Verbose debugging (10 examples)
```

## Fixtures

### Database Fixtures
- `db_engine`: Async SQLAlchemy engine with test database
- `db_session`: Async database session (function-scoped, auto-rollback)

### Redis Fixtures
- `redis_client`: Redis client connected to test database (DB 15)

### HTTP Client Fixtures
- `test_client`: AsyncClient with dependency overrides for testing API endpoints

## Configuration

### Pytest Configuration
- `pytest.ini`: Main pytest configuration
- `pyproject.toml`: Tool-specific settings (pytest, hypothesis)

### Hypothesis Configuration
- Max examples: 200 (default profile)
- Deadline: 5000ms per test
- Profiles: default, ci, dev, debug

### Test Database
- Uses separate database: `restaurant_test_db`
- Tables created/dropped for each test
- Isolated from development data

### Test Redis
- Uses separate Redis database: DB 15
- Flushed after each test
- Isolated from development data

## Writing Tests

### Example Unit Test
```python
import pytest
from app.services.session_service import generate_session_token

@pytest.mark.unit
def test_generate_session_token():
    token = generate_session_token()
    assert token.startswith("tok_")
    assert len(token) > 40
```

### Example Integration Test
```python
import pytest

@pytest.mark.integration
async def test_create_session(test_client):
    response = await test_client.post(
        "/api/v1/sessions",
        json={"table_identifier": "table-1"}
    )
    assert response.status_code == 201
    data = response.json()
    assert "session_token" in data
```

### Example Property-Based Test
```python
import pytest
from hypothesis import given, strategies as st

# Feature: smart-restaurant-ordering-system, Property 1: Session Token Uniqueness
@pytest.mark.property
@given(st.lists(st.text(min_size=1, max_size=20), min_size=2, max_size=100, unique=True))
def test_session_token_uniqueness(table_identifiers):
    tokens = [generate_session_token() for _ in table_identifiers]
    assert len(tokens) == len(set(tokens))
```

## Best Practices

1. **Isolation**: Each test should be independent and not rely on other tests
2. **Cleanup**: Use fixtures to ensure proper cleanup after tests
3. **Naming**: Use descriptive test names that explain what is being tested
4. **Markers**: Tag tests with appropriate markers (unit, integration, e2e, property)
5. **Async**: Use `async def` for async tests and `await` for async operations
6. **Fixtures**: Reuse fixtures from `conftest.py` instead of duplicating setup code
7. **Property Tags**: Include property reference comments for property-based tests

## Troubleshooting

### Database Connection Errors
- Ensure PostgreSQL is running
- Check that `restaurant_test_db` exists
- Verify connection string in `app/config.py`

### Redis Connection Errors
- Ensure Redis is running
- Check Redis URL in environment variables
- Verify test Redis database (15) is accessible

### Async Test Failures
- Ensure `pytest-asyncio` is installed
- Use `async def` for async tests
- Use `await` for async operations
- Check `asyncio_mode = auto` in pytest.ini

### Hypothesis Failures
- Review the failing example in test output
- Use `@example()` decorator to add specific test cases
- Adjust strategies if generating invalid data
- Increase deadline if tests are timing out
