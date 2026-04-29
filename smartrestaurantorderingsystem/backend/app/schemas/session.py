from pydantic import BaseModel
from datetime import datetime
from uuid import UUID


class SessionCreateRequest(BaseModel):
    table_identifier: str
    persistent_user_id: str | None = None
    session_token: str | None = None


class SessionCreateResponse(BaseModel):
    session_id: UUID
    session_token: str
    table_identifier: str
    is_new: bool = True


class SessionStateResponse(BaseModel):
    session_id: UUID
    table_identifier: str
    persistent_user_id: str | None
    created_at: datetime
    last_active_at: datetime
    is_active: bool
