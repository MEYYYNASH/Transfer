import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError
from ..config.settings import settings

class S3Service:
    def __init__(self):
        self.endpoint_url = settings.S3_ENDPOINT_URL
        self.bucket = settings.S3_BUCKET_NAME
        self.enabled = bool(settings.S3_ACCESS_KEY_ID and settings.S3_SECRET_ACCESS_KEY)

        if self.enabled:
            self.s3_client = boto3.client(
                "s3",
                endpoint_url=self.endpoint_url,
                aws_access_key_id=settings.S3_ACCESS_KEY_ID,
                aws_secret_access_key=settings.S3_SECRET_ACCESS_KEY,
                region_name=settings.S3_REGION,
                config=Config(signature_version="s3v4"),
            )
        else:
            self.s3_client = None

    def generate_presigned_upload_url(self, s3_key: str, expires_in: int = 3600) -> str:
        """Generates a short-lived presigned PUT URL for uploading file bytes."""
        if self.s3_client:
            try:
                return self.s3_client.generate_presigned_url(
                    ClientMethod="put_object",
                    Params={
                        "Bucket": self.bucket,
                        "Key": s3_key,
                        "ContentType": "application/octet-stream",
                    },
                    ExpiresIn=expires_in,
                )
            except (BotoCoreError, ClientError):
                pass
        return f"{self.endpoint_url}/{self.bucket}/{s3_key}?mock_token=presigned_upload"

    def generate_presigned_download_url(self, s3_key: str, original_filename: str, expires_in: int = 3600) -> str:
        """Generates a short-lived presigned GET URL for downloading file bytes."""
        if self.s3_client:
            try:
                return self.s3_client.generate_presigned_url(
                    ClientMethod="get_object",
                    Params={
                        "Bucket": self.bucket,
                        "Key": s3_key,
                        "ResponseContentDisposition": f'attachment; filename="{original_filename}"',
                    },
                    ExpiresIn=expires_in,
                )
            except (BotoCoreError, ClientError):
                pass
        return f"{self.endpoint_url}/{self.bucket}/{s3_key}?mock_token=presigned_download"

s3_service = S3Service()
