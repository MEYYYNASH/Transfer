from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class UploadCreateRequest(BaseModel):
    file_name: str = Field(..., min_length=1, max_length=255)
    file_size_bytes: int = Field(..., gt=0)
    sha256_checksum: Optional[str] = Field(None, max_length=64)
    password: Optional[str] = Field(None, max_length=128)
    max_downloads: Optional[int] = Field(None, gt=0, le=1000)
    expiry_hours: Optional[int] = Field(48, gt=0, le=168)

class UploadCreateResponse(BaseModel):
    upload_id: str
    upload_url: str
    share_token: str
    share_url: str
    expires_at: datetime

class UploadCompleteRequest(BaseModel):
    actual_sha256: Optional[str] = None

class ShareMetadataResponse(BaseModel):
    file_name: str
    file_size_bytes: int
    sha256_checksum: Optional[str] = None
    requires_password: bool
    remaining_downloads: Optional[int] = None
    expires_at: datetime
    download_url: Optional[str] = None

class AuthorizeShareRequest(BaseModel):
    password: Optional[str] = None

class AuthorizeShareResponse(BaseModel):
    authorized: bool
    download_url: str
    file_name: str
    file_size_bytes: int
    sha256_checksum: Optional[str] = None
