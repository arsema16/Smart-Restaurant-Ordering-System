"""Order and OrderItem models for managing customer orders."""

from datetime import datetime
from uuid import uuid4

from sqlalchemy import Column, DateTime, ForeignKey, Integer, Numeric, String, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class Order(Base):
    """
    Represents a confirmed order placed by a user.
    
    Orders are created from cart contents and track the lifecycle
    from receipt through cooking, ready, and delivery. Each order
    has a unique human-readable order number.
    
    Requirements: 4.1
    """
    
    __tablename__ = "orders"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    session_id = Column(
        UUID(as_uuid=True),
        ForeignKey("table_sessions.id"),
        nullable=False,
        index=True
    )
    order_number = Column(String(32), unique=True, nullable=False)
    status = Column(String(32), nullable=False, default="Received")
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        CheckConstraint(
            "status IN ('Received', 'Cooking', 'Ready', 'Delivered')",
            name='check_status_valid'
        ),
    )
    
    def __repr__(self) -> str:
        return f"<Order(id={self.id}, number='{self.order_number}', status='{self.status}')>"


class OrderItem(Base):
    """
    Represents a single item within an order.
    
    OrderItems snapshot the menu item details (including price) at the
    time of order placement to preserve historical accuracy even if
    menu prices change later.
    
    Requirements: 4.1
    """
    
    __tablename__ = "order_items"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    order_id = Column(
        UUID(as_uuid=True),
        ForeignKey("orders.id", ondelete="CASCADE"),
        nullable=False
    )
    menu_item_id = Column(
        Integer,
        ForeignKey("menu_items.id"),
        nullable=False
    )
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Numeric(10, 2), nullable=False)
    
    __table_args__ = (
        CheckConstraint('quantity > 0', name='check_order_item_quantity_positive'),
        CheckConstraint('unit_price > 0', name='check_unit_price_positive'),
    )
    
    def __repr__(self) -> str:
        return f"<OrderItem(id={self.id}, order={self.order_id}, item={self.menu_item_id}, qty={self.quantity})>"
