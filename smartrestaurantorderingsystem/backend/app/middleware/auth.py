"""JWT authentication middleware for staff endpoints."""

from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.staff_user import StaffUser
from app.services.auth_service import decode_token

# OAuth2 scheme for JWT bearer token
security = HTTPBearer()


async def get_current_staff(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
    db: AsyncSession = Depends(get_db),
) -> StaffUser:
    """
    FastAPI dependency to validate JWT and return the current staff user.
    
    Extracts the JWT from the Authorization header, validates it, and returns
    the corresponding StaffUser from the database. Raises 401 if the token is
    invalid, expired, or the user is inactive.
    
    This dependency should be applied to all staff endpoints that require
    authentication.
    
    Requirements: 5.6
    
    Args:
        credentials: HTTP bearer credentials (JWT token)
        db: Database session (injected)
    
    Returns:
        StaffUser: The authenticated staff user
    
    Raises:
        HTTPException: 401 if token is invalid, expired, or user is inactive
    
    Example:
        @router.get("/staff/orders")
        async def get_orders(
            staff: StaffUser = Depends(get_current_staff),
            db: AsyncSession = Depends(get_db)
        ):
            # staff is now authenticated and available
            ...
    """
    token = credentials.credentials
    
    try:
        payload = decode_token(token)
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
    
    # Extract username from token payload
    username: str = payload.get("sub")
    if not username:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify token type is access token
    token_type: str = payload.get("type")
    if token_type != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Fetch staff user from database
    result = await db.execute(
        select(StaffUser).where(StaffUser.username == username)
    )
    staff = result.scalar_one_or_none()
    
    if not staff:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not staff.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Inactive user",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return staff


async def require_admin(
    staff: Annotated[StaffUser, Depends(get_current_staff)],
) -> StaffUser:
    """
    FastAPI dependency to require admin role.
    
    Validates that the authenticated staff user has the "admin" role.
    Raises 403 if the user does not have sufficient permissions.
    
    This dependency should be applied to endpoints that require admin
    privileges, such as menu item creation and deletion.
    
    Requirements: 2.5
    
    Args:
        staff: Authenticated staff user (injected via get_current_staff)
    
    Returns:
        StaffUser: The authenticated admin user
    
    Raises:
        HTTPException: 403 if user does not have admin role
    
    Example:
        @router.post("/staff/menu")
        async def create_menu_item(
            staff: StaffUser = Depends(require_admin),
            db: AsyncSession = Depends(get_db)
        ):
            # staff is now authenticated and verified as admin
            ...
    """
    if staff.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions",
        )
    
    return staff
