# LINKORA Implementation Checklist

## Milestone 1: Core Framework, Design System, Database, Navigation
- [x] Project architecture and folder layout
- [x] Design token system (colors, typography, dark/AMOLED theme)
- [x] Drift SQLite database schema and tables (transfers, items, queue, share links, trusted devices, update history, settings)
- [x] Khmer + English localization structure
- [x] Router and navigation model (Home, Transfers, Share, Devices, Settings + Secondary screens)

## Milestone 2: File Selection, Storage, Transfer History, Integrity
- [x] File selection abstractions and metadata models
- [x] Path sanitization and traversal prevention
- [x] SHA-256 integrity calculation stream service
- [x] Transfer queue management and state machine
- [x] Transfer history repository and persistence

## Milestone 3: Real Wi-Fi / LAN Device-to-Device Transfer
- [x] Local network discovery and IP socket protocol
- [x] Streaming bounded chunk reader/writer
- [x] QR code pairing payload generator and parser
- [x] Sender/Receiver handshake with approval modal
- [x] SHA-256 verification and file saving

## Milestone 4: Backend Cloud Sharing Service (FastAPI + PostgreSQL + S3)
- [x] FastAPI REST API skeleton and routers
- [x] Pydantic V2 schemas for uploads, shares, and authorizations
- [x] S3/R2 presigned URL generator service
- [x] Password hashing and token hashing
- [x] Expiration and download count enforcement
- [x] SQLAlchemy models and Alembic migrations

## Milestone 5: Link Security, Quotas, Rate Limiting & Abuse Controls
- [x] Rate limiting middleware
- [x] Upload quotas and max file size enforcement
- [x] Revocation endpoint and audit logging
- [x] Error handling and HTTP status codes

## Milestone 6: GitHub Auto Update System
- [x] GitHub Releases API client
- [x] Semantic version comparison utility
- [x] Checksum and digital signature manifest verification
- [x] Android APK download and install intent helper
- [x] Windows executable launcher and silent upgrade flow

## Milestone 7: Bluetooth Transport Abstraction & Platform Limiters
- [x] Bluetooth transport interface
- [x] Platform capability detector
- [x] Explicit unsupported-device messaging and Wi-Fi fallback guidance

## Milestone 8: Packaging, Docker, CI/CD & Verification Tests
- [x] Docker Compose for FastAPI + PostgreSQL + MinIO (local S3)
- [x] GitHub Actions workflow for Flutter & Backend
- [x] Inno Setup script for Windows installer
- [x] Unit tests for transfer states, hashing, and versioning
- [x] Backend tests for upload session, share links, and authorization
