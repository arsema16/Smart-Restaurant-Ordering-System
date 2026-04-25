"""FastAPI application factory and router registration."""

import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.redis_client import init_redis, close_redis
from app.services.websocket_manager import connection_manager

# Import routers
from app.routers import (
    auth,
    cart,
    menu,
    orders,
    recommendations,
    sessions,
    staff_menu,
    staff_orders,
    ws,
)

# Configure logging
logging.basicConfig(
    level=logging.INFO if not settings.debug else logging.DEBUG,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """
    Application lifespan manager.
    
    Handles startup and shutdown tasks:
    - Initialize Redis connection pool
    - Initialize WebSocket connection manager
    - Close connections on shutdown
    """
    # Startup
    logger.info("Starting application...")
    await init_redis()
    await connection_manager.initialize()
    logger.info("Application started successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down application...")
    await connection_manager.shutdown()
    await close_redis()
    logger.info("Application shutdown complete")


def create_app() -> FastAPI:
    """
    Create and configure the FastAPI application.
    
    Registers all routers, adds middleware, and configures error handlers.
    
    Returns:
        FastAPI: Configured application instance
    """
    app = FastAPI(
        title=settings.app_name,
        description="A digital platform for restaurant ordering with real-time updates and AI recommendations",
        version="1.0.0",
        lifespan=lifespan,
    )
    
    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Register guest routers with /api/v1 prefix
    app.include_router(sessions.router, prefix="/api/v1")
    app.include_router(menu.router, prefix="/api/v1")
    app.include_router(cart.router, prefix="/api/v1")
    app.include_router(orders.router, prefix="/api/v1")
    app.include_router(recommendations.router, prefix="/api/v1")
    
    # Register staff routers with /api/v1 prefix
    app.include_router(auth.router, prefix="/api/v1")
    app.include_router(staff_orders.router, prefix="/api/v1")
    app.include_router(staff_menu.router, prefix="/api/v1")
    
    # Register WebSocket router (no prefix, uses /ws paths)
    app.include_router(ws.router)
    
    # Add error handlers
    
    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request,
        exc: RequestValidationError,
    ) -> JSONResponse:
        """
        Handle Pydantic validation errors (422).
        
        Returns a structured error response with field-level details.
        """
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "detail": exc.errors(),
                "body": exc.body,
            },
        )
    
    @app.exception_handler(404)
    async def not_found_handler(request: Request, exc: Exception) -> JSONResponse:
        """Handle 404 Not Found errors."""
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"detail": "Resource not found"},
        )
    
    @app.exception_handler(401)
    async def unauthorized_handler(request: Request, exc: Exception) -> JSONResponse:
        """Handle 401 Unauthorized errors."""
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"detail": "Invalid or expired credentials"},
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    @app.exception_handler(403)
    async def forbidden_handler(request: Request, exc: Exception) -> JSONResponse:
        """Handle 403 Forbidden errors."""
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content={"detail": "Insufficient permissions"},
        )
    
    @app.exception_handler(500)
    async def internal_error_handler(request: Request, exc: Exception) -> JSONResponse:
        """Handle 500 Internal Server Error."""
        logger.error(f"Internal server error: {exc}", exc_info=True)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"detail": "Internal server error"},
        )
    
    # Health check endpoint
    @app.get("/health")
    async def health_check() -> dict:
        """Health check endpoint."""
        return {"status": "healthy", "app": settings.app_name}
    
    return app


# Create application instance
app = create_app()
