"""UserProfile model for tracking user ordering behavior and preferences."""

from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, String
from sqlalchemy.dialects.postgresql import JSONB

from app.database import Base


class UserProfile(Base):
    """
    Represents a user's ordering history and preference profile.
    
    The profile tracks the most-ordered items (top 5 by count) and
    recently ordered items (last 10) to power personalized recommendations.
    It is keyed by persistent_user_id which survives across multiple
    table sessions.
    
    Requirements: 7.1
    """
    
    __tablename__ = "user_profiles"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    persistent_user_id = Column(String(128), unique=True, nullable=False)
    most_ordered_items = Column(JSONB, nullable=False, default=list)  # [{item_id, count}] top 5
    recently_ordered_items = Column(JSONB, nullable=False, default=list)  # [item_id] last 10
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self) -> str:
        return f"<UserProfile(id={self.id}, user='{self.persistent_user_id}')>"
