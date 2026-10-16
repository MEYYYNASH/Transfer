from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    APP_NAME: str = "LINKORA API"
    APP_ENV: str = "development"
    APP_PORT: int = 8000
    APP_HOST: str = "0.0.0.0"
    SECRET_KEY: str = "linkora-super-secret-key-change-in-production-12345"

    # CORS
    CORS_ORIGINS: List[str] = ["*"]

    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./linkora_backend.db"

    # S3 Object Storage
    S3_ENDPOINT_URL: str = "http://localhost:9000"
    S3_ACCESS_KEY_ID: str = "minioadmin"
    S3_SECRET_ACCESS_KEY: str = "minioadmin"
    S3_BUCKET_NAME: str = "linkora-shares"
    S3_REGION: str = "us-east-1"
    S3_USE_SSL: bool = False

    # Quotas & Limits
    MAX_UPLOAD_SIZE_BYTES: int = 10 * 1024 * 1024 * 1024 # 10 GB
    RATE_LIMIT_PER_MINUTE: int = 120
    DEFAULT_EXPIRY_HOURS: int = 48
    MAX_EXPIRY_HOURS: int = 168 # 7 Days

    class Config:
        env_file = ".env"
        extra = "allow"

settings = Settings()
