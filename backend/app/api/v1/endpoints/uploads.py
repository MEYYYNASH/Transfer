from datetime import datetime, timedelta, timezone
import uuid
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ....models.database import get_db
from ....models.shares import UploadSession, ShareLink, AuditLog
from ....schemas.shares import (
    UploadCreateRequest,
    UploadCreateResponse,
    UploadCompleteRequest,
)
from ....security.auth import generate_secure_token, hash_share_token, hash_password
from ....services.s3_service import s3_service
from ....config.settings import settings

router = APIRouter(prefix="/uploads", tags=["Uploads"])

@router.post("", response_model=UploadCreateResponse, status_code=status.HTTP_201_CREATED)
async def create_upload_session(
    payload: UploadCreateRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    # Enforce file size limit
    if payload.file_size_bytes > settings.MAX_UPLOAD_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File exceeds maximum allowed size of {settings.MAX_UPLOAD_SIZE_BYTES / (1024**3):.1f} GB",
        )

    upload_id = str(uuid.uuid4())
    s3_key = f"uploads/{upload_id}/{payload.file_name}"
    share_token = generate_secure_token(32)
    share_token_hash = hash_share_token(share_token)

    expiry_hours = min(payload.expiry_hours or settings.DEFAULT_EXPIRY_HOURS, settings.MAX_EXPIRY_HOURS)
    expires_at = datetime.now(timezone.utc) + timedelta(hours=expiry_hours)

    pw_hash = hash_password(payload.password) if payload.password else None

    # Create UploadSession
    session_record = UploadSession(
        upload_id=upload_id,
        file_name=payload.file_name,
        file_size_bytes=payload.file_size_bytes,
        sha256_checksum=payload.sha256_checksum,
        s3_key=s3_key,
        status="pending",
    )
    db.add(session_record)

    # Create ShareLink
    share_record = ShareLink(
        id=str(uuid.uuid4()),
        share_token_hash=share_token_hash,
        s3_key=s3_key,
        file_name=payload.file_name,
        file_size_bytes=payload.file_size_bytes,
        sha256_checksum=payload.sha256_checksum,
        password_hash=pw_hash,
        max_downloads=payload.max_downloads,
        expires_at=expires_at,
    )
    db.add(share_record)

    # Log audit event
    client_ip = request.client.host if request.client else "unknown"
    audit = AuditLog(
        id=str(uuid.uuid4()),
        event_type="upload_created",
        share_id=share_record.id,
        ip_address=client_ip,
    )
    db.add(audit)

    await db.commit()

    upload_url = s3_service.generate_presigned_upload_url(s3_key)
    base_url = str(request.base_url).rstrip("/")
    share_url = f"{base_url}/s/{share_token}"

    return UploadCreateResponse(
        upload_id=upload_id,
        upload_url=upload_url,
        share_token=share_token,
        share_url=share_url,
        expires_at=expires_at,
    )

@router.post("/{upload_id}/complete")
async def complete_upload_session(
    upload_id: str,
    payload: UploadCompleteRequest,
    db: AsyncSession = Depends(get_db),
):
    stmt = select(UploadSession).where(UploadSession.upload_id == upload_id)
    res = await db.execute(stmt)
    session = res.scalar_one_or_none()

    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Upload session not found")

    session.status = "completed"
    if payload.actual_sha256:
        session.sha256_checksum = payload.actual_sha256

    await db.commit()
    return {"status": "success", "upload_id": upload_id}

@router.get("/{upload_id}")
async def get_upload_status(
    upload_id: str,
    db: AsyncSession = Depends(get_db),
):
    stmt = select(UploadSession).where(UploadSession.upload_id == upload_id)
    res = await db.execute(stmt)
    session = res.scalar_one_or_none()

    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Upload session not found")

    return {
        "upload_id": session.upload_id,
        "file_name": session.file_name,
        "file_size_bytes": session.file_size_bytes,
        "status": session.status,
        "created_at": session.created_at,
    }
