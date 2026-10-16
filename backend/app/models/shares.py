from datetime import datetime, timezone
from sqlalchemy import Column, String, BigInteger, Integer, Boolean, DateTime
from .database import Base

class UploadSession(Base):
    __tablename__ = "upload_sessions"

    upload_id = Column(String(64), primary_key=True, index=True)
    file_name = Column(String(255), nullable=False)
    file_size_bytes = Column(BigInteger, nullable=False)
    sha256_checksum = Column(String(64), nullable=True)
    s3_key = Column(String(512), nullable=False)
    status = Column(String(32), default="pending", nullable=False) # pending, completed, expired
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

class ShareLink(Base):
    __tablename__ = "share_links"

    id = Column(String(64), primary_key=True, index=True)
    share_token_hash = Column(String(64), unique=True, index=True, nullable=False)
    s3_key = Column(String(512), nullable=False)
    file_name = Column(String(255), nullable=False)
    file_size_bytes = Column(BigInteger, nullable=False)
    sha256_checksum = Column(String(64), nullable=True)
    password_hash = Column(String(255), nullable=True)
    max_downloads = Column(Integer, nullable=True)
    download_count = Column(Integer, default=0, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    is_revoked = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String(64), primary_key=True, index=True)
    event_type = Column(String(64), nullable=False) # 'upload_created', 'link_accessed', 'link_downloaded', 'link_revoked'
    share_id = Column(String(64), nullable=True)
    ip_address = Column(String(45), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
