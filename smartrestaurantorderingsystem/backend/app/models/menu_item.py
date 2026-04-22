"""MenuItem model for restaurant menu items."""

from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, Column, DateTime, Integer, Numeric, String, CheckConstraint

from app.database import Base


class MenuItem(Base):
    """
    Represents a single item in the restaurant menu.
    
    Each menu item has a name, category, price, preparation time, and
    availability status. Staff can update availability in real-time.
    
    Requirements: 2.1
    """
    
    __tablename__ = "menu_items"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    category = Column(String(128), nullable=False)
    price = Column(Numeric(10, 2), nullable=False)
    prep_time_minutes = Column(Integer, nullable=False)
    is_available = Column(Boolean, nullable=False, default=True)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        CheckConstraint('price > 0', name='check_price_positive'),
        CheckConstraint('prep_time_minutes > 0', name='check_prep_time_positive'),
    )
    
    def __repr__(self) -> str:
        return f"<MenuItem(id={self.id}, name='{self.name}', category='{self.category}', available={self.is_available})>"
