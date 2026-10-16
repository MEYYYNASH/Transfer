from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import time

from .config.settings import settings
from .models.database import engine, Base
from .api.v1.endpoints.uploads import router as uploads_router
from .api.v1.endpoints.shares import router as shares_router

# In-memory Rate Limiting State
request_counts: dict[str, list[float]] = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database tables on startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Cleanup on shutdown
    await engine.dispose()

app = FastAPI(
    title="LINKORA Secure Cloud API",
    description="Cross-platform high-throughput file sharing and transfer backend with S3/R2 presigned URLs and cryptographically hashed access tokens.",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rate Limiter Middleware
@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    client_ip = request.client.host if request.client else "127.0.0.1"
    now = time.time()
    window = 60.0 # 1 minute window

    if client_ip not in request_counts:
        request_counts[client_ip] = []

    # Clean old requests
    request_counts[client_ip] = [t for t in request_counts[client_ip] if now - t < window]

    if len(request_counts[client_ip]) >= settings.RATE_LIMIT_PER_MINUTE:
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={"detail": "Rate limit exceeded. Please wait a moment before retrying."},
        )

    request_counts[client_ip].append(now)
    response = await call_next(request)
    return response

# Routers
app.include_router(uploads_router, prefix="/api/v1")
app.include_router(shares_router, prefix="/api/v1")

@app.get("/health", tags=["Health"])
async def health_check():
    return {
        "status": "healthy",
        "service": "LINKORA API",
        "version": "1.0.0",
        "timestamp": time.time(),
    }

@app.get("/api/v1/app/config", tags=["Configuration"])
async def get_app_config():
    return {
        "max_upload_size_bytes": settings.MAX_UPLOAD_SIZE_BYTES,
        "default_expiry_hours": settings.DEFAULT_EXPIRY_HOURS,
        "max_expiry_hours": settings.MAX_EXPIRY_HOURS,
        "rate_limit_per_minute": settings.RATE_LIMIT_PER_MINUTE,
        "s3_storage_active": bool(settings.S3_ACCESS_KEY_ID),
    }
