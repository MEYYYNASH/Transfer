import pytest
from httpx import AsyncClient, ASGITransport
from backend.app.main import app

@pytest.mark.asyncio
async def test_health_check():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "LINKORA API"

@pytest.mark.asyncio
async def test_app_config():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.get("/api/v1/app/config")
        assert response.status_code == 200
        data = response.json()
        assert "max_upload_size_bytes" in data
        assert data["rate_limit_per_minute"] > 0

@pytest.mark.asyncio
async def test_create_upload_and_preview_share():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. Create upload session
        payload = {
            "file_name": "document.pdf",
            "file_size_bytes": 1048576, # 1 MB
            "sha256_checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            "expiry_hours": 24,
            "max_downloads": 5,
        }
        res = await ac.post("/api/v1/uploads", json=payload)
        assert res.status_code == 201
        data = res.json()
        assert "upload_id" in data
        assert "share_token" in data
        assert "upload_url" in data

        share_token = data["share_token"]
        upload_id = data["upload_id"]

        # Complete upload
        comp_res = await ac.post(f"/api/v1/uploads/{upload_id}/complete", json={})
        assert comp_res.status_code == 200

        # 2. Preview metadata
        preview_res = await ac.get(f"/api/v1/shares/{share_token}")
        assert preview_res.status_code == 200
        preview_data = preview_res.json()
        assert preview_data["file_name"] == "document.pdf"
        assert preview_data["requires_password"] is False
        assert preview_data["remaining_downloads"] == 5

@pytest.mark.asyncio
async def test_password_protected_share():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # Create share with password
        payload = {
            "file_name": "confidential.zip",
            "file_size_bytes": 500000,
            "password": "MySuperSecretPassword123",
            "expiry_hours": 12,
        }
        res = await ac.post("/api/v1/uploads", json=payload)
        assert res.status_code == 201
        share_token = res.json()["share_token"]

        # Preview requires password
        meta_res = await ac.get(f"/api/v1/shares/{share_token}")
        assert meta_res.status_code == 200
        assert meta_res.json()["requires_password"] is True
        assert meta_res.json()["download_url"] is None

        # Authorize with incorrect password -> 401
        bad_auth = await ac.post(f"/api/v1/shares/{share_token}/authorize", json={"password": "WrongPassword"})
        assert bad_auth.status_code == 401

        # Authorize with correct password -> 200
        good_auth = await ac.post(f"/api/v1/shares/{share_token}/authorize", json={"password": "MySuperSecretPassword123"})
        assert good_auth.status_code == 200
        assert good_auth.json()["authorized"] is True
        assert "download_url" in good_auth.json()

@pytest.mark.asyncio
async def test_file_size_limit_rejection():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        huge_payload = {
            "file_name": "too_big.iso",
            "file_size_bytes": 100 * 1024 * 1024 * 1024, # 100 GB exceeds 10 GB limit
        }
        res = await ac.post("/api/v1/uploads", json=huge_payload)
        assert res.status_code == 413
