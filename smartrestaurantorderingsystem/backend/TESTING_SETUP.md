# Testing Infrastructure Setup Guide

This guide explains how to set up and use the testing infrastructure for the Smart Restaurant Ordering System.

## Prerequisites

1. **Python 3.11+** installed
2. **PostgreSQL 15** running locally
3. **Redis 7** running locally
4. **Poetry** (recommended) or **pip** for dependency management

## Installation

### Option 1: Using Poetry (Recommended)

```bash
cd backend

# Install all dependencies including dev dependencies
poetry install

# Activate the virtual environment
poetry shell
```

### Option 2: Using pip

```bash
cd backend

# Create a virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements-test.txt

# Install main dependencies from pyproject.toml
pip install fastapi uvicorn sqlalchemy asyncpg redis python-jose bcrypt pydantic pydantic-settings alembic python-multipart websockets apscheduler scikit-learn numpy
```

## Database Setup

### Create Test Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create test database
CREATE DATABASE restaurant_test_db;

# Exit psql
\q
```

### Configure Database Connection

Create a `.env` file in the `backend/` directory:

```env
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/restaurant_db
TEST_DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/restaurant_test_db
REDIS_URL=redis://localhost:6379/0
TEST_REDIS_URL=redis://localhost:6379/15
JWT_SECRET=your-secret-key-change-in-production
DEBUG=False
```

## Running Tests

### Run All Tests

```bash
pytest
```

### Run Specific Test Types

```bash
# Unit tests only
pytest -m unit

# Integration tests only
pytest -m integration

# End-to-end tests only
pytest -m e2e

# Property-based tests only
pytest -m property
```

### Run Tests in Specific Directory

```bash
pytest tests/unit/
pytest tests/integration/
pytest tests/e2e/
```

### Run with Coverage

```bash
pytest --cov=app --cov-report=html --cov-report=term-missing
```

The HTML coverage report will be generated in `htmlcov/index.html`.

### Run with Different Hypothesis Profiles

```bash
# Fast development testing (50 examples)
HYPOTHESIS_PROFILE=dev pytest

# Standard testing (200 examples)
HYPOTHESIS_PROFILE=default pytest

# Thorough CI testing (500 examples)
HYPOTHESIS_PROFILE=ci pytest

# Debug mode (10 examples, verbose)
HYPOTHESIS_PROFILE=debug pytest
```

### Run Specific Test File

```bash
pytest tests/unit/test_example.py -v
```

### Run Specific Test Function

```bash
pytest tests/unit/test_example.py::test_example_sync -v
```

## Test Structure

```
tests/
├── conftest.py              # Shared fixtures and configuration
├── utils.py                 # Test helper functions
├── README.md               # Testing documentation
├── unit/                   # Unit tests
│   ├── __init__.py
│   ├── test_example.py
│   └── test_properties_example.py
├── integration/            # Integration tests
│   ├── __init__.py
│   └── test_example.py
└── e2e/                    # End-to-end tests
    ├── __init__.py
    └── test_example.py
```

## Available Fixtures

### Database Fixtures

- **`db_engine`**: Async SQLAlchemy engine with test database
- **`db_session`**: Async database session (function-scoped, auto-rollback)

Example:
```python
async def test_database_operation(db_session):
    result = await db_session.execute("SELECT 1")
    assert result.scalar() == 1
```

### Redis Fixtures

- **`redis_client`**: Redis client connected to test database (DB 15)

Example:
```python
async def test_redis_operation(redis_client):
    await redis_client.set("key", "value")
    value = await redis_client.get("key")
    assert value == "value"
```

### HTTP Client Fixtures

- **`test_client`**: AsyncClient with dependency overrides for testing API endpoints

Example:
```python
async def test_api_endpoint(test_client):
    response = await test_client.get("/api/v1/menu")
    assert response.status_code == 200
```

## Writing Tests

### Unit Test Example

```python
import pytest

@pytest.mark.unit
def test_function():
    result = my_function(1, 2)
    assert result == 3
```

### Async Test Example

```python
import pytest

@pytest.mark.unit
async def test_async_function():
    result = await my_async_function()
    assert result is not None
```

### Property-Based Test Example

```python
import pytest
from hypothesis import given, strategies as st

# Feature: smart-restaurant-ordering-system, Property 1: Session Token Uniqueness
@pytest.mark.property
@given(st.integers(min_value=1, max_value=100))
def test_property(n):
    tokens = [generate_token() for _ in range(n)]
    assert len(tokens) == len(set(tokens))
```

### Integration Test Example

```python
import pytest

@pytest.mark.integration
async def test_api_integration(test_client, db_session):
    # Create test data
    # Make API request
    # Verify database state
    pass
```

## Troubleshooting

### Database Connection Errors

**Error**: `could not connect to server`

**Solution**:
1. Ensure PostgreSQL is running: `pg_ctl status`
2. Check connection string in `.env`
3. Verify test database exists: `psql -U postgres -l`

### Redis Connection Errors

**Error**: `Connection refused`

**Solution**:
1. Ensure Redis is running: `redis-cli ping`
2. Check Redis URL in `.env`
3. Verify Redis is listening on port 6379

### Import Errors

**Error**: `ModuleNotFoundError: No module named 'app'`

**Solution**:
1. Ensure you're in the `backend/` directory
2. Activate virtual environment
3. Install dependencies: `poetry install` or `pip install -r requirements-test.txt`

### Async Test Failures

**Error**: `RuntimeError: Event loop is closed`

**Solution**:
1. Ensure `pytest-asyncio` is installed
2. Check `asyncio_mode = auto` in `pytest.ini`
3. Use `async def` for async tests

### Hypothesis Timeout Errors

**Error**: `Hypothesis test exceeded deadline`

**Solution**:
1. Increase deadline in `pyproject.toml`: `deadline = 10000`
2. Use faster Hypothesis profile: `HYPOTHESIS_PROFILE=dev pytest`
3. Optimize test logic to run faster

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          cd backend
          pip install poetry
          poetry install
      
      - name: Run tests
        env:
          HYPOTHESIS_PROFILE: ci
        run: |
          cd backend
          poetry run pytest --cov=app --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## Best Practices

1. **Write tests first** (TDD approach)
2. **Keep tests isolated** - each test should be independent
3. **Use descriptive names** - test names should explain what is being tested
4. **Test edge cases** - don't just test the happy path
5. **Use fixtures** - reuse setup code via fixtures
6. **Mock external dependencies** - in unit tests, mock database, Redis, etc.
7. **Tag tests appropriately** - use markers (unit, integration, e2e, property)
8. **Keep tests fast** - unit tests should run in milliseconds
9. **Document complex tests** - add docstrings explaining what is being tested
10. **Review test coverage** - aim for >80% coverage on critical paths

## Next Steps

1. Install dependencies: `poetry install` or `pip install -r requirements-test.txt`
2. Set up test database: Create `restaurant_test_db` in PostgreSQL
3. Configure environment: Create `.env` file with database and Redis URLs
4. Run example tests: `pytest tests/unit/test_example.py -v`
5. Start implementing actual tests for the system components

## Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [Hypothesis Documentation](https://hypothesis.readthedocs.io/)
- [pytest-asyncio Documentation](https://pytest-asyncio.readthedocs.io/)
- [FastAPI Testing Guide](https://fastapi.tiangolo.com/tutorial/testing/)
