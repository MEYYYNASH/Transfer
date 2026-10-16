import secrets
import hashlib
import hmac

def generate_secure_token(nbytes: int = 32) -> str:
    """Generates a cryptographically secure URL-safe random token."""
    return secrets.token_urlsafe(nbytes)

def hash_share_token(token: str) -> str:
    """Computes SHA-256 hash of a share token for non-reversible DB persistence."""
    return hashlib.sha256(token.encode("utf-8")).hexdigest()

def hash_password(password: str, salt: str | None = None) -> str:
    """Hashes a share password using PBKDF2-HMAC-SHA256 with 100,000 iterations."""
    if salt is None:
        salt = secrets.token_hex(16)
    key = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        100000,
    )
    return f"{salt}${key.hex()}"

def verify_password(plain_password: str, stored_hash: str) -> bool:
    """Verifies a plain password against the stored salt$hash string."""
    try:
        salt, expected_hex = stored_hash.split("$", 1)
        actual_key = hashlib.pbkdf2_hmac(
            "sha256",
            plain_password.encode("utf-8"),
            salt.encode("utf-8"),
            100000,
        )
        return hmac.compare_digest(actual_key.hex(), expected_hex)
    except Exception:
        return False
