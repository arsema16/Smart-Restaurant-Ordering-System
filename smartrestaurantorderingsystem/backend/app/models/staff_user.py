"""StaffUser model for restaurant staff authentication and authorization."""

from sqlalchemy import Boolean, Column, Integer, String

from app.database import Base


class StaffUser(Base):
    """
    Represents a staff member with access to the staff dashboard.
    
    Staff users authenticate via JWT and have role-based permissions.
    The 'admin' role can manage menu items, while 'staff' role can
    manage orders.
    
    Requirements: 9.1
    """
    
    __tablename__ = "staff_users"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(128), unique=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(String(32), nullable=False, default="staff")
    is_active = Column(Boolean, nullable=False, default=True)
    
    def __repr__(self) -> str:
        return f"<StaffUser(id={self.id}, username='{self.username}', role='{self.role}', active={self.is_active})>"
