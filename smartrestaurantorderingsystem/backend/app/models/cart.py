"""CartItem model for managing user shopping carts."""

from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, UniqueConstraint, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class CartItem(Base):
    """
    Represents an item in a user's cart within a table session.
    
    Cart items are temporary selections that persist until the user
    places an order or the session expires. Each cart item references
    a menu item and tracks quantity.
    
    Requirements: 3.1
    """
    
    __tablename__ = "cart_items"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(
        UUID(as_uuid=True),
        ForeignKey("table_sessions.id", ondelete="CASCADE"),
        nullable=False
    )
    menu_item_id = Column(
        Integer,
        ForeignKey("menu_items.id"),
        nullable=False
    )
    quantity = Column(Integer, nullable=False)
    added_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    
    __table_args__ = (
        UniqueConstraint('session_id', 'menu_item_id', name='uq_session_menu_item'),
        CheckConstraint('quantity > 0', name='check_quantity_positive'),
    )
    
    def __repr__(self) -> str:
        return f"<CartItem(id={self.id}, session={self.session_id}, item={self.menu_item_id}, qty={self.quantity})>"
