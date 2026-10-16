from datetime import datetime, timezone
import uuid
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ....models.database import get_db
from ....models.shares import ShareLink, AuditLog
from ....schemas.shares import (
    ShareMetadataResponse,
    AuthorizeShareRequest,
    AuthorizeShareResponse,
)
from ....security.auth import hash_share_token, verify_password
from ....services.s3_service import s3_service

router = APIRouter(prefix="/shares", tags=["Shares"])

@router.get("/{share_token}", response_model=ShareMetadataResponse)
async def get_share_metadata(
    share_token: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    token_hash = hash_share_token(share_token)
    stmt = select(ShareLink).where(ShareLink.share_token_hash == token_hash)
    res = await db.execute(stmt)
    share = res.scalar_one_or_none()

    if not share or share.is_revoked:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Share link not found or has been revoked")

    now_utc = datetime.now(timezone.utc)
    if share.expires_at.tzinfo is None:
        share_expires = share.expires_at.replace(tzinfo=timezone.utc)
    else:
        share_expires = share.expires_at

    if now_utc > share_expires:
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="Share link has expired")

    if share.max_downloads and share.download_count >= share.max_downloads:
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="Maximum download limit reached for this link")

    remaining = (share.max_downloads - share.download_count) if share.max_downloads else None
    download_url = None
    if not share.password_hash:
        download_url = s3_service.generate_presigned_download_url(share.s3_key, share.file_name)

    return ShareMetadataResponse(
        file_name=share.file_name,
        file_size_bytes=share.file_size_bytes,
        sha256_checksum=share.sha256_checksum,
        requires_password=bool(share.password_hash),
        remaining_downloads=remaining,
        expires_at=share.expires_at,
        download_url=download_url,
    )

@router.post("/{share_token}/authorize", response_model=AuthorizeShareResponse)
async def authorize_share(
    share_token: str,
    payload: AuthorizeShareRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    token_hash = hash_share_token(share_token)
    stmt = select(ShareLink).where(ShareLink.share_token_hash == token_hash)
    res = await db.execute(stmt)
    share = res.scalar_one_or_none()

    if not share or share.is_revoked:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Share link not found")

    now_utc = datetime.now(timezone.utc)
    share_expires = share.expires_at.replace(tzinfo=timezone.utc) if share.expires_at.tzinfo is None else share.expires_at
    if now_utc > share_expires:
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="Share link has expired")

    if share.max_downloads and share.download_count >= share.max_downloads:
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="Maximum download limit reached")

    # Verify password if required
    if share.password_hash:
        if not payload.password or not verify_password(payload.password, share.password_hash):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid password for protected share")

    # Increment download count
    share.download_count += 1

    # Audit log
    client_ip = request.client.host if request.client else "unknown"
    audit = AuditLog(
        id=str(uuid.uuid4()),
        event_type="link_downloaded",
        share_id=share.id,
        ip_address=client_ip,
    )
    db.add(audit)
    await db.commit()

    download_url = s3_service.generate_presigned_download_url(share.s3_key, share.file_name)

    return AuthorizeShareResponse(
        authorized=True,
        download_url=download_url,
        file_name=share.file_name,
        file_size_bytes=share.file_size_bytes,
        sha256_checksum=share.sha256_checksum,
    )

@router.delete("/{share_id}")
async def revoke_share(
    share_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    stmt = select(ShareLink).where(ShareLink.id == share_id)
    res = await db.execute(stmt)
    share = res.scalar_one_or_none()

    if not share:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Share link not found")

    share.is_revoked = True

    client_ip = request.client.host if request.client else "unknown"
    audit = AuditLog(
        id=str(uuid.uuid4()),
        event_type="link_revoked",
        share_id=share.id,
        ip_address=client_ip,
    )
    db.add(audit)
    await db.commit()

    return {"status": "revoked", "share_id": share_id}
