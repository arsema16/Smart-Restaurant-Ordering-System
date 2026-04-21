# Smart Restaurant Ordering System - Backend

Backend API for the Smart Restaurant Ordering System built with FastAPI, PostgreSQL, and Redis.

## Prerequisites

- Python 3.11+
- Docker and Docker Compose
- Poetry (Python package manager)

## Setup

1. Install dependencies:
```bash
poetry install
```

2. Copy environment variables:
```bash
cp .env.example .env
```

3. Start infrastructure services:
```bash
docker-compose up -d postgres redis
```

4. Run database migrations:
```bash
poetry run alembic upgrade head
```

5. Start the development server:
```bash
poetry run uvicorn app.main:app --reload
```

The API will be available at http://localhost:8000

## Docker Compose

To run the entire stack (PostgreSQL, Redis, and FastAPI):

```bash
docker-compose up
```

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── config.py          # Application settings
│   ├── database.py        # Database connection
│   ├── redis_client.py    # Redis connection
│   ├── main.py            # FastAPI app (to be created)
│   ├── models/            # SQLAlchemy models
│   ├── schemas/           # Pydantic schemas
│   ├── routers/           # API endpoints
│   ├── services/          # Business logic
│   ├── middleware/        # Auth and session middleware
│   └── recommendation/    # AI recommendation engine
├── tests/
│   ├── unit/              # Unit tests
│   ├── integration/       # Integration tests
│   └── e2e/               # End-to-end tests
├── alembic/               # Database migrations
├── pyproject.toml         # Dependencies
└── docker-compose.yml     # Infrastructure setup
```

## Testing

Run all tests:
```bash
poetry run pytest
```

Run property-based tests:
```bash
poetry run pytest -m hypothesis
```

## API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
