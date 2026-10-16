# LINKORA — High-Speed Cross-Platform File Sharing & Transfer

LINKORA is a secure, cross-platform file transfer platform built with Flutter and FastAPI, targeting **Android APK** and **Windows 10/11 Desktop EXE**.

---

## 🌟 Key Features

1. **Direct Nearby Transfer (Wi-Fi / LAN / Hotspot)**
   - Streaming TCP socket engine transferring data in bounded 64 KB chunks.
   - Zero cloud internet dependency for local device-to-device transfers.
   - Cryptographic SHA-256 verification computed on-the-fly.
   - Quick pairing via local IP or QR code scanning.
   - Interactive receiver confirmation prompt to prevent unauthorized incoming transfers.

2. **Secure Cloud Sharing (FastAPI + S3 / Cloudflare R2)**
   - Direct-to-storage presigned upload and download URLs (up to 10 GB per file).
   - Zero storage of access tokens in plaintext: share tokens are hashed using SHA-256 in PostgreSQL.
   - Optional password protection hashed using salted PBKDF2-HMAC-SHA256.
   - Configurable link expiration (12h, 24h, 48h, 7d) and maximum download limits.
   - Instant link revocation and audit logging.

3. **Bluetooth Transport Interface**
   - Platform capability detection for Android and Windows.
   - Honest limitation reporting for restricted desktop OS profiles, automatically guiding users to high-speed Wi-Fi Direct/LAN.

4. **GitHub Auto Updates**
   - Direct integration with official GitHub Releases API.
   - Semantic version checking (`VersionComparator`).
   - Digital hash and manifest integrity verification before execution.
   - Android package installer intent invocation.
   - Windows silent executable installer execution (`Inno Setup`).

5. **Premium UI/UX Design System**
   - Electric Violet (`#9878FF`) and Cyan Mint (`#55D6C2`) futuristic accents.
   - Deep Obsidian (`#0D0F14`) Dark Theme + True AMOLED Black (`#000000`) Mode.
   - Fully bilingual: Khmer (ភាសាខ្មែរ) and English.

---

## 🏗️ Architecture

```
linkora/
├── lib/
│   ├── core/              # Theme tokens, Localization (KM/EN), Routing, Utils (Hash, Paths)
│   ├── database/          # Drift SQLite local tables (Transfers, Queue, Security, Settings)
│   ├── features/          # Home, Uploads, Downloads, Sharing, Devices, Updates, Settings
│   ├── services/          # Local Network TCP sockets, Cloud Dio client, Bluetooth, Notifications
│   ├── shared/            # Riverpod providers, Transfer models
│   ├── app.dart           # App root
│   └── main.dart          # Entrypoint
├── backend/
│   ├── app/
│   │   ├── api/v1/        # REST Endpoints (/uploads, /shares, /app/config)
│   │   ├── models/        # SQLAlchemy async models
│   │   ├── schemas/       # Pydantic V2 validation
│   │   ├── security/      # Cryptographic token hashing & password salts
│   │   ├── services/      # S3 / Cloudflare R2 presigned URL generator
│   │   └── main.py        # FastAPI app, Lifespan, Rate limiter
│   ├── tests/             # Pytest asynchronous API integration test suite
│   ├── requirements.txt
│   └── Dockerfile
├── deploy/
│   └── docker-compose.yml # PostgreSQL 16 + MinIO (S3) + FastAPI backend
├── installer/
│   └── linkora_setup.iss  # Inno Setup Windows installer script
├── .github/workflows/     # CI tests + Release APK/EXE packaging
└── docs/                  # Architecture & Checklist documents
```

---

## 🚀 Getting Started

### 1. Backend Local Setup (FastAPI + SQLite or Postgres)

To run the backend with Python 3:
```bash
cd backend
py -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn backend.app.main:app --reload --port 8000
```
Open interactive Swagger OpenAPI docs at: `http://localhost:8000/docs`.

Or launch using Docker Compose (with PostgreSQL and MinIO):
```bash
docker-compose -f deploy/docker-compose.yml up -d
```

### 2. Run Backend Integration Tests

```bash
pytest backend/tests -v
```

### 3. Flutter Application Development

Ensure the Flutter SDK is installed and added to your `PATH`:
```bash
# Check environment
flutter doctor -v

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run Windows Desktop
flutter run -d windows

# Run Android
flutter run -d <android-device-id>
```

### 4. Build Production Artifacts

#### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Windows EXE & Installer
```bash
flutter build windows --release
# Output directory: build/windows/x64/runner/Release/

# Compile installer via Inno Setup
iscc installer/linkora_setup.iss
# Output: build/installer/LINKORA-windows-x64-setup.exe
```
