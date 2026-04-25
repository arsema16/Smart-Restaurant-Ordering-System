"""
WebSocket Connection Manager with Redis Pub/Sub

Manages WebSocket connections for guests and staff, handles real-time event broadcasting
via Redis pub/sub for multi-instance deployments.
"""

import asyncio
import json
import logging
from typing import Dict, List, Optional
from uuid import UUID
from datetime import datetime

from fastapi import WebSocket
from redis.asyncio import Redis

from app.redis_client import get_redis


logger = logging.getLogger(__name__)


class ConnectionManager:
    """
    Manages WebSocket connections and Redis pub/sub for real-time updates.
    
    Maintains separate connection pools for guest and staff clients, and uses
    Redis pub/sub to fan out events across multiple server instances.
    """
    
    def __init__(self):
        # guest_connections: dict[session_id, list[WebSocket]]
        self.guest_connections: Dict[str, List[WebSocket]] = {}
        
        # staff_connections: list[WebSocket]
        self.staff_connections: List[WebSocket] = []
        
        # Redis client for pub/sub
        self._redis: Optional[Redis] = None
        
        # Pub/sub listener task
        self._pubsub_task: Optional[asyncio.Task] = None
        
        # Lock for thread-safe connection management
        self._lock = asyncio.Lock()
    
    async def initialize(self) -> None:
        """Initialize Redis connection and start pub/sub listener."""
        self._redis = await get_redis()
        
        # Start pub/sub listener in background
        self._pubsub_task = asyncio.create_task(self._listen_to_redis())
        logger.info("WebSocket ConnectionManager initialized")
    
    async def shutdown(self) -> None:
        """Shutdown pub/sub listener and close all connections."""
        if self._pubsub_task:
            self._pubsub_task.cancel()
            try:
                await self._pubsub_task
            except asyncio.CancelledError:
                pass
        
        # Close all guest connections
        async with self._lock:
            for session_connections in self.guest_connections.values():
                for ws in session_connections:
                    try:
                        await ws.close()
                    except Exception as e:
                        logger.error(f"Error closing guest WebSocket: {e}")
            
            # Close all staff connections
            for ws in self.staff_connections:
                try:
                    await ws.close()
                except Exception as e:
                    logger.error(f"Error closing staff WebSocket: {e}")
        
        logger.info("WebSocket ConnectionManager shutdown complete")
    
    async def connect_guest(self, session_id: str, ws: WebSocket) -> None:
        """
        Add a guest WebSocket connection and subscribe to relevant Redis channels.
        
        Args:
            session_id: The table session ID
            ws: The WebSocket connection
        """
        await ws.accept()
        
        async with self._lock:
            if session_id not in self.guest_connections:
                self.guest_connections[session_id] = []
            self.guest_connections[session_id].append(ws)
        
        logger.info(f"Guest connected: session_id={session_id}, total_guests={sum(len(conns) for conns in self.guest_connections.values())}")
    
    async def connect_staff(self, ws: WebSocket) -> None:
        """
        Add a staff WebSocket connection and subscribe to relevant Redis channels.
        
        Args:
            ws: The WebSocket connection
        """
        await ws.accept()
        
        async with self._lock:
            self.staff_connections.append(ws)
        
        logger.info(f"Staff connected: total_staff={len(self.staff_connections)}")
    
    async def disconnect(self, ws: WebSocket) -> None:
        """
        Remove a WebSocket connection from guest or staff pools.
        
        Args:
            ws: The WebSocket connection to remove
        """
        async with self._lock:
            # Try to remove from guest connections
            for session_id, connections in list(self.guest_connections.items()):
                if ws in connections:
                    connections.remove(ws)
                    if not connections:
                        del self.guest_connections[session_id]
                    logger.info(f"Guest disconnected: session_id={session_id}")
                    return
            
            # Try to remove from staff connections
            if ws in self.staff_connections:
                self.staff_connections.remove(ws)
                logger.info(f"Staff disconnected: total_staff={len(self.staff_connections)}")
                return
    
    async def broadcast_to_session(self, session_id: str, event: dict) -> None:
        """
        Send an event to all guest connections for a specific session.
        
        Args:
            session_id: The table session ID
            event: The event payload to send
        """
        async with self._lock:
            connections = self.guest_connections.get(session_id, [])
        
        if not connections:
            logger.debug(f"No active connections for session {session_id}")
            return
        
        # Add timestamp if not present
        if "timestamp" not in event:
            event["timestamp"] = datetime.utcnow().isoformat()
        
        message = json.dumps(event)
        
        # Send to all connections, remove dead ones
        dead_connections = []
        for ws in connections:
            try:
                await ws.send_text(message)
            except Exception as e:
                logger.error(f"Error sending to guest WebSocket: {e}")
                dead_connections.append(ws)
        
        # Clean up dead connections
        if dead_connections:
            async with self._lock:
                for ws in dead_connections:
                    if session_id in self.guest_connections and ws in self.guest_connections[session_id]:
                        self.guest_connections[session_id].remove(ws)
                if session_id in self.guest_connections and not self.guest_connections[session_id]:
                    del self.guest_connections[session_id]
    
    async def broadcast_to_staff(self, event: dict) -> None:
        """
        Send an event to all staff connections.
        
        Args:
            event: The event payload to send
        """
        async with self._lock:
            connections = self.staff_connections.copy()
        
        if not connections:
            logger.debug("No active staff connections")
            return
        
        # Add timestamp if not present
        if "timestamp" not in event:
            event["timestamp"] = datetime.utcnow().isoformat()
        
        message = json.dumps(event)
        
        # Send to all connections, remove dead ones
        dead_connections = []
        for ws in connections:
            try:
                await ws.send_text(message)
            except Exception as e:
                logger.error(f"Error sending to staff WebSocket: {e}")
                dead_connections.append(ws)
        
        # Clean up dead connections
        if dead_connections:
            async with self._lock:
                for ws in dead_connections:
                    if ws in self.staff_connections:
                        self.staff_connections.remove(ws)
    
    async def broadcast_order_status(self, order_id: str, new_status: str, session_id: Optional[str] = None) -> None:
        """
        Publish order status update to Redis for distribution to all server instances.
        
        Args:
            order_id: The order ID
            new_status: The new order status
            session_id: Optional session ID for targeted guest broadcast
        """
        if not self._redis:
            logger.error("Redis client not initialized")
            return
        
        event = {
            "event": "order_status_updated",
            "payload": {
                "order_id": order_id,
                "new_status": new_status,
                "session_id": session_id,
            },
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Publish to Redis channel
        channel = f"orders:{order_id}:status"
        await self._redis.publish(channel, json.dumps(event))
        logger.debug(f"Published order status update to Redis: {channel}")
    
    async def publish_new_order(self, order_id: str, order_number: str, table_identifier: str, items: list, status: str) -> None:
        """
        Publish new order event to Redis for staff dashboard.
        
        Args:
            order_id: The order ID
            order_number: Human-readable order number
            table_identifier: Table identifier
            items: List of order items
            status: Initial order status
        """
        if not self._redis:
            logger.error("Redis client not initialized")
            return
        
        event = {
            "event": "order_created",
            "payload": {
                "order_id": order_id,
                "order_number": order_number,
                "table_identifier": table_identifier,
                "items": items,
                "status": status,
            },
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Publish to Redis channel
        await self._redis.publish("orders:new", json.dumps(event))
        logger.debug(f"Published new order to Redis: order_number={order_number}")
    
    async def publish_menu_availability_change(self, item_id: int, is_available: bool, item_name: str) -> None:
        """
        Publish menu item availability change to Redis for all guests.
        
        Args:
            item_id: The menu item ID
            is_available: New availability status
            item_name: Menu item name
        """
        if not self._redis:
            logger.error("Redis client not initialized")
            return
        
        event = {
            "event": "menu_item_availability_changed",
            "payload": {
                "item_id": item_id,
                "is_available": is_available,
                "item_name": item_name,
            },
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Publish to Redis channel
        await self._redis.publish("menu:availability", json.dumps(event))
        logger.debug(f"Published menu availability change to Redis: item_id={item_id}, is_available={is_available}")
    
    async def publish_cart_item_removed(self, session_id: str, item_id: int, item_name: str) -> None:
        """
        Publish cart item removal notification (due to unavailability) to specific session.
        
        Args:
            session_id: The table session ID
            item_id: The menu item ID
            item_name: Menu item name
        """
        if not self._redis:
            logger.error("Redis client not initialized")
            return
        
        event = {
            "event": "cart_item_removed_unavailable",
            "payload": {
                "item_id": item_id,
                "item_name": item_name,
            },
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Publish to Redis channel for specific session
        channel = f"session:{session_id}:cart"
        await self._redis.publish(channel, json.dumps(event))
        logger.debug(f"Published cart item removal to Redis: session_id={session_id}, item_id={item_id}")
    
    async def _listen_to_redis(self) -> None:
        """
        Background task that listens to Redis pub/sub channels and broadcasts to WebSocket clients.
        
        Subscribes to:
        - orders:new (for staff)
        - orders:*:status (for guests and staff)
        - menu:availability (for all guests)
        - session:*:cart (for specific guest sessions)
        """
        if not self._redis:
            logger.error("Redis client not initialized for pub/sub listener")
            return
        
        try:
            # Create a separate Redis connection for pub/sub
            pubsub = self._redis.pubsub()
            
            # Subscribe to channels with pattern matching
            await pubsub.psubscribe(
                "orders:new",
                "orders:*:status",
                "menu:availability",
                "session:*:cart",
            )
            
            logger.info("Redis pub/sub listener started")
            
            async for message in pubsub.listen():
                if message["type"] not in ("pmessage", "message"):
                    continue
                
                try:
                    # Extract channel and data
                    channel = message["channel"]
                    if isinstance(channel, bytes):
                        channel = channel.decode("utf-8")
                    
                    data = message["data"]
                    if isinstance(data, bytes):
                        data = data.decode("utf-8")
                    
                    event = json.loads(data)
                    
                    # Route event to appropriate connections
                    await self._route_redis_event(channel, event)
                    
                except Exception as e:
                    logger.error(f"Error processing Redis pub/sub message: {e}")
        
        except asyncio.CancelledError:
            logger.info("Redis pub/sub listener cancelled")
            raise
        except Exception as e:
            logger.error(f"Redis pub/sub listener error: {e}")
    
    async def _route_redis_event(self, channel: str, event: dict) -> None:
        """
        Route a Redis pub/sub event to the appropriate WebSocket connections.
        
        Args:
            channel: The Redis channel name
            event: The event payload
        """
        event_type = event.get("event")
        
        # Route to staff: orders:new
        if channel == "orders:new" and event_type == "order_created":
            await self.broadcast_to_staff(event)
        
        # Route to guests and staff: orders:{order_id}:status
        elif channel.startswith("orders:") and channel.endswith(":status") and event_type == "order_status_updated":
            payload = event.get("payload", {})
            session_id = payload.get("session_id")
            
            # Broadcast to staff
            await self.broadcast_to_staff(event)
            
            # Broadcast to specific guest session if session_id provided
            if session_id:
                await self.broadcast_to_session(session_id, event)
        
        # Route to all guests: menu:availability
        elif channel == "menu:availability" and event_type == "menu_item_availability_changed":
            # Broadcast to all guest sessions
            async with self._lock:
                session_ids = list(self.guest_connections.keys())
            
            for session_id in session_ids:
                await self.broadcast_to_session(session_id, event)
        
        # Route to specific guest session: session:{session_id}:cart
        elif channel.startswith("session:") and channel.endswith(":cart") and event_type == "cart_item_removed_unavailable":
            # Extract session_id from channel name
            session_id = channel.split(":")[1]
            await self.broadcast_to_session(session_id, event)


# Global connection manager instance
connection_manager = ConnectionManager()
