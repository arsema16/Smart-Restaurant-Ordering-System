from pydantic_settings import BaseSettings, SettingsConfigDict
import json


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Database
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/restaurant_db"
    
    # Redis
    redis_url: str = "redis://localhost:6379/0"
    
    # JWT Authentication
    jwt_secret: str = "your-secret-key-change-in-production"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 30
    jwt_refresh_token_expire_hours: int = 8
    
    # Application
    app_name: str = "Smart Restaurant Ordering System"
    debug: bool = False
    
    # CORS - allow all origins for development
    cors_origins: list[str] = ["*"]
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False
    )


settings = Settings()
