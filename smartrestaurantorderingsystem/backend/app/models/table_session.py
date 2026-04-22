"""TableSession model for managing table-based user sessions."""

from datetime import datetime
from uuid import uuid4

from sqlalchemy import Boolean, Column, DateTime, String
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class TableSession(Base):
    """
    Represents a unique session bound to a restaurant table.
    
    A TableSession is created when a user scans a QR code and persists
    for the duration of their dining experience. It can be resumed across
    page reloads and device switches using the session_token.
    
    Requirements: 1.1, 1.2, 1.5
    """
    
    __tablename__ = "table_sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    table_identifier = Column(String(64), nullable=False, index=True)
    session_token = Column(String(128), unique=True, nullable=False, index=True)
    persistent_user_id = Column(String(128), nullable=True)  # Survives session changes
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    last_active_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    is_active = Column(Boolean, nullable=False, default=True)
    
    def __repr__(self) -> str:
        return f"<TableSession(id={self.id}, table={self.table_identifier}, token={self.session_token[:10]}...)>"
