"""WebSocket endpoints for real-time updates."""

import asyncio
import json
import logging
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, status
from jose import JWTError
from redis.asyncio import Redis
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.staff_user import StaffUser
from app.models.table_session import TableSession
from app.redis_client import get_redis
from app.services.auth_service import decode_token
from app.services.websocket_manager import connection_manager

router = APIRouter(tags=["websocket"])

logger = logging.getLogger(__name__)

# Ping/pong keepalive interval (30 seconds)
KEEPALIVE_INTERVAL = 30


@router.websocket("/ws/guest/{session_id}")
async def guest_websocket(
    websocket: WebSocket,
    session_id: UUID,
    token: str = Query(..., description="Session token for authentication"),
) -> None:
    """
    WebSocket endpoint for guest real-time updates.
    
    Validates session token and maintains connection for order status updates,
    menu availability changes, and cart notifications.
    
    Implements ping/pong keepalive every 30 seconds.
    
    Requirements: 4.4, 6.1, 10.4
    
    Args:
        websocket: WebSocket connection
        session_id: Table session UUID from path
        token: Session token from query parameter
    """
    # Validate session token
    db_gen = get_db()
    db: AsyncSession = await anext(db_gen)
    redis: Redis = await get_redis()
    
    try:
        # Verify session exists and token matches
        result = await db.execute(
            select(TableSession).where(
                TableSession.id == session_id,
                TableSession.session_token == token,
                TableSession.is_active == True,
            )
        )
        session = result.scalar_one_or_none()
        
        if not session:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
        
        # Accept connection and register with connection manager
        await connection_manager.connect_guest(str(session_id), websocket)
        logger.info(f"Guest WebSocket connected: session_id={session_id}")
        
        # Start keepalive task
        keepalive_task = asyncio.create_task(
            _send_keepalive(websocket, KEEPALIVE_INTERVAL)
        )
        
        try:
            # Listen for client messages (mainly pong responses)
            while True:
                data = await websocket.receive_text()
                message = json.loads(data)
                
                # Handle ping/pong
                if message.get("event") == "ping":
                    await websocket.send_json({"event": "pong", "timestamp": message.get("timestamp")})
                elif message.get("event") == "pong":
                    # Client acknowledged our ping
                    pass
        
        except WebSocketDisconnect:
            logger.info(f"Guest WebSocket disconnected: session_id={session_id}")
        except Exception as e:
            logger.error(f"Guest WebSocket error: {e}")
        finally:
            # Clean up
            keepalive_task.cancel()
            await connection_manager.disconnect(websocket)
    
    finally:
        await db.close()


@router.websocket("/ws/staff")
async def staff_websocket(
    websocket: WebSocket,
    token: str = Query(..., description="JWT access token for authentication"),
) -> None:
    """
    WebSocket endpoint for staff real-time order updates.
    
    Validates JWT token and maintains connection for new order notifications
    and order status updates.
    
    Implements ping/pong keepalive every 30 seconds.
    
    Requirements: 5.1, 6.1, 10.4
    
    Args:
        websocket: WebSocket connection
        token: JWT access token from query parameter
    """
    # Validate JWT token
    db_gen = get_db()
    db: AsyncSession = await anext(db_gen)
    
    try:
        # Decode and validate token
        try:
            payload = decode_token(token)
        except JWTError:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
        
        # Verify token type
        if payload.get("type") != "access":
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
        
        # Fetch staff user
        username = payload.get("sub")
        if not username:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
        
        result = await db.execute(
            select(StaffUser).where(StaffUser.username == username)
        )
        staff = result.scalar_one_or_none()
        
        if not staff or not staff.is_active:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
        
        # Accept connection and register with connection manager
        await connection_manager.connect_staff(websocket)
        logger.info(f"Staff WebSocket connected: username={username}")
        
        # Start keepalive task
        keepalive_task = asyncio.create_task(
            _send_keepalive(websocket, KEEPALIVE_INTERVAL)
        )
        
        try:
            # Listen for client messages (mainly pong responses)
            while True:
                data = await websocket.receive_text()
                message = json.loads(data)
                
                # Handle ping/pong
                if message.get("event") == "ping":
                    await websocket.send_json({"event": "pong", "timestamp": message.get("timestamp")})
                elif message.get("event") == "pong":
                    # Client acknowledged our ping
                    pass
        
        except WebSocketDisconnect:
            logger.info(f"Staff WebSocket disconnected: username={username}")
        except Exception as e:
            logger.error(f"Staff WebSocket error: {e}")
        finally:
            # Clean up
            keepalive_task.cancel()
            await connection_manager.disconnect(websocket)
    
    finally:
        await db.close()


async def _send_keepalive(websocket: WebSocket, interval: int) -> None:
    """
    Send periodic ping messages to keep WebSocket connection alive.
    
    Args:
        websocket: WebSocket connection
        interval: Ping interval in seconds
    """
    try:
        while True:
            await asyncio.sleep(interval)
            await websocket.send_json({
                "event": "ping",
                "timestamp": asyncio.get_event_loop().time(),
            })
    except asyncio.CancelledError:
        pass
    except Exception as e:
        logger.error(f"Keepalive error: {e}")
