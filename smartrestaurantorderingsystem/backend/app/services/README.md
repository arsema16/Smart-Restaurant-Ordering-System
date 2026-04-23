# Session Service

The session service manages table-based user sessions for the Smart Restaurant Ordering System.

## Overview

When a guest scans a QR code at their table, a unique session is created that persists across page reloads and device switches. The session service handles:

- **Token Generation**: Cryptographically secure session tokens
- **Session Creation**: Creating new sessions linked to table identifiers
- **Session Resumption**: Looking up existing sessions by token
- **Token Validation**: Verifying session tokens for authentication
- **Redis Caching**: Fast token lookup with 24-hour TTL

## API

### `generate_session_token() -> str`

Generates a unique, non-guessable session token using `secrets.token_urlsafe(32)`.

**Returns**: A session token string (e.g., "tok_abc123...")

**Example**:
```python
token = generate_session_token()
# "tok_xYz9_AbC123..."
```

### `create_session(db, redis, table_identifier, persistent_user_id=None) -> TableSession`

Creates a new table session with a unique token. The session is persisted to PostgreSQL and cached in Redis.

**Parameters**:
- `db`: Async database session
- `redis`: Redis client
- `table_identifier`: Unique identifier for the restaurant table (e.g., "table-7")
- `persistent_user_id`: Optional user ID that survives session changes

**Returns**: The newly created `TableSession` object

**Example**:
```python
session = await create_session(
    db=db,
    redis=redis,
    table_identifier="table-42",
    persistent_user_id="user-abc123"
)
```

### `resume_session(db, redis, session_token) -> Optional[TableSession]`

Resumes an existing session using a session token. Checks Redis cache first, falls back to database if not cached.

**Parameters**:
- `db`: Async database session
- `redis`: Redis client
- `session_token`: The session token to look up

**Returns**: `TableSession` if found and active, `None` otherwise

**Example**:
```python
session = await resume_session(
    db=db,
    redis=redis,
    session_token="tok_xYz9_AbC123..."
)
if session:
    print(f"Resumed session for table {session.table_identifier}")
```

### `validate_session_token(db, redis, token) -> UUID`

Validates a session token and returns the session ID. Raises HTTP 401 if invalid.

**Parameters**:
- `db`: Async database session
- `redis`: Redis client
- `token`: The session token to validate

**Returns**: The session ID (UUID)

**Raises**: `HTTPException(401)` if token is invalid or expired

**Example**:
```python
try:
    session_id = await validate_session_token(
        db=db,
        redis=redis,
        token=request_token
    )
    # Token is valid, proceed with request
except HTTPException:
    # Token is invalid, return 401
    pass
```

## Requirements Mapping

- **1.1**: QR-based session creation
- **1.2**: Unique session token generation
- **1.3**: Session restoration after page reload
- **1.4**: Session access from different devices
- **1.6**: Session token validation

## Redis Caching

Session tokens are cached in Redis with:
- **Key format**: `session:{token}`
- **Value**: Session ID (UUID as string)
- **TTL**: 24 hours (86400 seconds)

This provides fast token lookup without hitting the database on every request.

## Security

- Tokens use `secrets.token_urlsafe(32)` for cryptographically secure randomness
- Each token is 43+ characters long (32 bytes base64-encoded + "tok_" prefix)
- Tokens are URL-safe (no special characters requiring encoding)
- Invalid/expired tokens return HTTP 401
- Inactive sessions are rejected

## Testing

See `tests/unit/test_session_service.py` for unit tests and `tests/unit/test_session_properties.py` for property-based tests.
