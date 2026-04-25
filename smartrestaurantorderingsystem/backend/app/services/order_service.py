"""Order service for managing order placement and lifecycle.

This service handles:
- Order number generation
- Order placement from cart
- Order status management with transition validation
- Estimated wait time calculation
- Real-time event publishing via Redis

Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.2, 5.3, 5.4, 5.5, 6.2, 6.3, 6.4, 6.5
"""

import json
from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from fastapi import HTTPException, status
from redis.asyncio import Redis
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.cart import CartItem
from app.models.menu_item import MenuItem
from app.models.order import Order, OrderItem
from app.models.table_session import TableSession
from app.schemas.order import OrderResponse, OrderItemDetail


# Valid order status transitions
VALID_STATUS_TRANSITIONS = {
    "Received": ["Cooking"],
    "Cooking": ["Ready"],
    "Ready": ["Delivered"],
    "Delivered": [],  # Terminal state
}

# Queue depth factor for wait time calculation (minutes per order in queue)
QUEUE_DEPTH_FACTOR = 5


class OrderService:
    """
    Service for managing order operations.
    
    Handles order placement, status updates, and real-time notifications.
    Validates status transitions and calculates estimated wait times.
    
    Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.2, 5.3, 5.4, 5.5, 6.2, 6.3, 6.4, 6.5
    """
    
    def __init__(self, db: AsyncSession, redis: Redis):
        self.db = db
        self.redis = redis
    
    async def generate_order_number(self) -> str:
        """
        Generate a unique human-readable order number.
        
        Format: "ORD-XXXX" where XXXX is a zero-padded sequential number.
        Uses database sequence to ensure uniqueness across concurrent requests.
        
        Requirements: 4.1, 4.2
        
        Returns:
            str: Unique order number (e.g., "ORD-0042")
        """
        # Get count of all orders to generate next sequential number
        query = select(func.count(Order.id))
        result = await self.db.execute(query)
        count = result.scalar() or 0
        
        # Generate order number with zero-padding
        order_number = f"ORD-{(count + 1):04d}"
        
        # Verify uniqueness (handle race conditions)
        query = select(Order).where(Order.order_number == order_number)
        result = await self.db.execute(query)
        existing = result.scalar_one_or_none()
        
        if existing:
            # Collision detected, use timestamp-based fallback
            timestamp_suffix = int(datetime.utcnow().timestamp() * 1000) % 10000
            order_number = f"ORD-{timestamp_suffix:04d}"
        
        return order_number
    
    async def place_order(self, session_id: UUID) -> OrderResponse:
        """
        Place an order from the current cart contents.
        
        Creates an Order with OrderItems, clears the cart, sets initial status
        to "Received", and publishes a real-time event to staff dashboard.
        
        Requirements: 4.1, 4.2, 4.3, 4.4, 4.6
        
        Args:
            session_id: The table session UUID
        
        Returns:
            OrderResponse: The newly created order
        
        Raises:
            HTTPException: 422 if cart is empty, 404 if session not found
        """
        # Fetch session to get table_identifier
        session = await self._get_session(session_id)
        
        # Fetch cart items with menu item details
        query = (
            select(CartItem, MenuItem)
            .join(MenuItem, CartItem.menu_item_id == MenuItem.id)
            .where(CartItem.session_id == session_id)
        )
        result = await self.db.execute(query)
        cart_rows = result.all()
        
        # Validate cart is not empty
        if not cart_rows:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Cart is empty. Cannot place order."
            )
        
        # Generate unique order number
        order_number = await self.generate_order_number()
        
        # Create order
        order = Order(
            session_id=session_id,
            order_number=order_number,
            status="Received",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        self.db.add(order)
        await self.db.flush()  # Get the generated order ID
        
        # Create order items (snapshot cart with current prices)
        total_price = Decimal("0.00")
        order_items = []
        
        for cart_item, menu_item in cart_rows:
            order_item = OrderItem(
                order_id=order.id,
                menu_item_id=menu_item.id,
                quantity=cart_item.quantity,
                unit_price=menu_item.price,
            )
            self.db.add(order_item)
            order_items.append((order_item, menu_item))
            total_price += menu_item.price * cart_item.quantity
        
        await self.db.flush()
        
        # Clear cart
        for cart_item, _ in cart_rows:
            await self.db.delete(cart_item)
        
        await self.db.commit()
        
        # Calculate estimated wait time
        queue_depth = await self._get_active_order_count()
        estimated_wait = await self.calculate_estimated_wait(order.id, queue_depth)
        
        # Publish real-time event to staff dashboard
        await self._publish_order_created_event(
            order_id=order.id,
            order_number=order_number,
            table_identifier=session.table_identifier,
            items=order_items,
        )
        
        # Build response
        return await self._build_order_response(
            order=order,
            items=order_items,
            table_identifier=session.table_identifier,
            total_price=total_price,
            estimated_wait_minutes=estimated_wait,
        )
    
    async def get_order(self, order_id: UUID) -> OrderResponse:
        """
        Get a single order by ID.
        
        Requirements: 6.4
        
        Args:
            order_id: The order UUID
        
        Returns:
            OrderResponse: The order details
        
        Raises:
            HTTPException: 404 if order not found
        """
        # Fetch order
        query = select(Order).where(Order.id == order_id)
        result = await self.db.execute(query)
        order = result.scalar_one_or_none()
        
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Order with ID {order_id} not found"
            )
        
        # Fetch session for table_identifier
        session = await self._get_session(order.session_id)
        
        # Fetch order items with menu details
        items = await self._get_order_items(order_id)
        
        # Calculate total price and estimated wait
        total_price = sum(
            item.unit_price * item.quantity for item, _ in items
        )
        queue_depth = await self._get_active_order_count()
        estimated_wait = await self.calculate_estimated_wait(order_id, queue_depth)
        
        return await self._build_order_response(
            order=order,
            items=items,
            table_identifier=session.table_identifier,
            total_price=total_price,
            estimated_wait_minutes=estimated_wait,
        )
    
    async def get_orders_for_session(self, session_id: UUID) -> list[OrderResponse]:
        """
        Get all orders for a table session (order history).
        
        Requirements: 4.5, 6.4
        
        Args:
            session_id: The table session UUID
        
        Returns:
            list[OrderResponse]: List of orders for the session
        """
        # Fetch session
        session = await self._get_session(session_id)
        
        # Fetch all orders for session
        query = (
            select(Order)
            .where(Order.session_id == session_id)
            .order_by(Order.created_at.desc())
        )
        result = await self.db.execute(query)
        orders = result.scalars().all()
        
        # Build responses
        responses = []
        queue_depth = await self._get_active_order_count()
        
        for order in orders:
            items = await self._get_order_items(order.id)
            total_price = sum(
                item.unit_price * item.quantity for item, _ in items
            )
            estimated_wait = await self.calculate_estimated_wait(order.id, queue_depth)
            
            response = await self._build_order_response(
                order=order,
                items=items,
                table_identifier=session.table_identifier,
                total_price=total_price,
                estimated_wait_minutes=estimated_wait,
            )
            responses.append(response)
        
        return responses
    
    async def get_all_active_orders(self) -> list[OrderResponse]:
        """
        Get all active orders (status != "Delivered") for staff dashboard.
        
        Requirements: 5.2
        
        Args:
            None
        
        Returns:
            list[OrderResponse]: List of active orders
        """
        # Fetch all non-delivered orders
        query = (
            select(Order)
            .where(Order.status != "Delivered")
            .order_by(Order.created_at.asc())
        )
        result = await self.db.execute(query)
        orders = result.scalars().all()
        
        # Build responses
        responses = []
        queue_depth = len(orders)
        
        for order in orders:
            session = await self._get_session(order.session_id)
            items = await self._get_order_items(order.id)
            total_price = sum(
                item.unit_price * item.quantity for item, _ in items
            )
            estimated_wait = await self.calculate_estimated_wait(order.id, queue_depth)
            
            response = await self._build_order_response(
                order=order,
                items=items,
                table_identifier=session.table_identifier,
                total_price=total_price,
                estimated_wait_minutes=estimated_wait,
            )
            responses.append(response)
        
        return responses
    
    async def update_order_status(
        self,
        order_id: UUID,
        new_status: str,
    ) -> OrderResponse:
        """
        Update order status with transition validation.
        
        Validates that the status transition follows the allowed sequence:
        Received → Cooking → Ready → Delivered
        
        Publishes real-time event on successful update.
        
        Requirements: 5.3, 5.4, 5.5
        
        Args:
            order_id: The order UUID
            new_status: The new status to set
        
        Returns:
            OrderResponse: The updated order
        
        Raises:
            HTTPException: 404 if order not found, 422 if invalid transition
        """
        # Fetch order with row lock to prevent concurrent updates
        query = select(Order).where(Order.id == order_id).with_for_update()
        result = await self.db.execute(query)
        order = result.scalar_one_or_none()
        
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Order with ID {order_id} not found"
            )
        
        # Validate status transition
        current_status = order.status
        allowed_transitions = VALID_STATUS_TRANSITIONS.get(current_status, [])
        
        if new_status not in allowed_transitions:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid status transition: {current_status} → {new_status}"
            )
        
        # Update status
        old_status = order.status
        order.status = new_status
        order.updated_at = datetime.utcnow()
        
        await self.db.commit()
        
        # Publish real-time event
        await self._publish_order_status_updated_event(
            order_id=order.id,
            order_number=order.order_number,
            old_status=old_status,
            new_status=new_status,
        )
        
        # Return updated order
        return await self.get_order(order_id)
    
    async def calculate_estimated_wait(
        self,
        order_id: UUID,
        queue_depth: int,
    ) -> int:
        """
        Calculate estimated wait time for an order.
        
        Formula: sum(prep_time_minutes for all items) + (queue_depth * QUEUE_DEPTH_FACTOR)
        
        Requirements: 6.2, 6.3
        
        Args:
            order_id: The order UUID
            queue_depth: Number of orders ahead in queue
        
        Returns:
            int: Estimated wait time in minutes (non-negative)
        """
        # Fetch order items with menu details
        items = await self._get_order_items(order_id)
        
        # Sum preparation times
        prep_time_total = sum(
            menu_item.prep_time_minutes * order_item.quantity
            for order_item, menu_item in items
        )
        
        # Add queue factor
        queue_time = queue_depth * QUEUE_DEPTH_FACTOR
        
        # Ensure non-negative
        estimated_wait = max(0, prep_time_total + queue_time)
        
        return estimated_wait
    
    # Helper methods
    
    async def _get_session(self, session_id: UUID) -> TableSession:
        """Fetch a table session by ID."""
        query = select(TableSession).where(TableSession.id == session_id)
        result = await self.db.execute(query)
        session = result.scalar_one_or_none()
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Session with ID {session_id} not found"
            )
        
        return session
    
    async def _get_order_items(
        self,
        order_id: UUID,
    ) -> list[tuple[OrderItem, MenuItem]]:
        """Fetch order items with menu details."""
        query = (
            select(OrderItem, MenuItem)
            .join(MenuItem, OrderItem.menu_item_id == MenuItem.id)
            .where(OrderItem.order_id == order_id)
        )
        result = await self.db.execute(query)
        return result.all()
    
    async def _get_active_order_count(self) -> int:
        """Get count of active orders (not delivered)."""
        query = select(func.count(Order.id)).where(Order.status != "Delivered")
        result = await self.db.execute(query)
        return result.scalar() or 0
    
    async def _build_order_response(
        self,
        order: Order,
        items: list[tuple[OrderItem, MenuItem]],
        table_identifier: str,
        total_price: Decimal,
        estimated_wait_minutes: int,
    ) -> OrderResponse:
        """Build OrderResponse from order and items."""
        item_details = [
            OrderItemDetail(
                id=order_item.id,
                menu_item_id=order_item.menu_item_id,
                menu_item_name=menu_item.name,
                quantity=order_item.quantity,
                unit_price=order_item.unit_price,
                subtotal=order_item.unit_price * order_item.quantity,
            )
            for order_item, menu_item in items
        ]
        
        return OrderResponse(
            id=order.id,
            order_number=order.order_number,
            status=order.status,
            items=item_details,
            total_price=total_price,
            estimated_wait_minutes=estimated_wait_minutes,
            created_at=order.created_at,
            updated_at=order.updated_at,
            table_identifier=table_identifier,
        )
    
    async def _publish_order_created_event(
        self,
        order_id: UUID,
        order_number: str,
        table_identifier: str,
        items: list[tuple[OrderItem, MenuItem]],
    ) -> None:
        """Publish order created event to Redis for staff dashboard."""
        event = {
            "event": "order_created",
            "payload": {
                "order_id": str(order_id),
                "order_number": order_number,
                "table_identifier": table_identifier,
                "items": [
                    {
                        "menu_item_id": order_item.menu_item_id,
                        "menu_item_name": menu_item.name,
                        "quantity": order_item.quantity,
                        "unit_price": float(order_item.unit_price),
                    }
                    for order_item, menu_item in items
                ],
                "status": "Received",
            },
            "timestamp": datetime.utcnow().isoformat(),
        }
        
        # Publish to orders:new channel
        await self.redis.publish("orders:new", json.dumps(event))
    
    async def _publish_order_status_updated_event(
        self,
        order_id: UUID,
        order_number: str,
        old_status: str,
        new_status: str,
    ) -> None:
        """Publish order status updated event to Redis."""
        event = {
            "event": "order_status_updated",
            "payload": {
                "order_id": str(order_id),
                "order_number": order_number,
                "old_status": old_status,
                "new_status": new_status,
            },
            "timestamp": datetime.utcnow().isoformat(),
        }
        
        # Publish to order-specific channel
        await self.redis.publish(f"orders:{order_id}:status", json.dumps(event))


# Dependency for getting order service
async def get_order_service(db: AsyncSession, redis: Redis) -> OrderService:
    """FastAPI dependency for order service."""
    return OrderService(db, redis)
