# =============================================================================
# STORAGE SERVICE
# =============================================================================
# Abstraction layer for file storage. Supports both local storage and S3.
# This pattern allows switching storage backends without changing the rest of the code.

import os
import uuid
from typing import Optional, BinaryIO
from abc import ABC, abstractmethod

import boto3
from botocore.exceptions import ClientError

from app.config import settings


class StorageBackend(ABC):
    """Abstract base class for storage backends."""

    @abstractmethod
    def upload_file(
        self,
        file: BinaryIO,
        filename: str,
        folder: str,
        content_type: Optional[str] = None
    ) -> tuple[str, int]:
        """Upload a file and return (storage_path, file_size)."""
        pass

    @abstractmethod
    def delete_file(self, file_path: str) -> bool:
        """Delete a file. Returns True if successful."""
        pass

    @abstractmethod
    def get_download_url(self, file_path: str, expires_in: int = 3600) -> str:
        """Get a URL to download the file."""
        pass


class LocalStorage(StorageBackend):
    """Local filesystem storage (for development)."""

    def __init__(self, base_dir: str = "uploads"):
        self.base_dir = base_dir
        os.makedirs(base_dir, exist_ok=True)

    def upload_file(
        self,
        file: BinaryIO,
        filename: str,
        folder: str,
        content_type: Optional[str] = None
    ) -> tuple[str, int]:
        # Create folder
        folder_path = os.path.join(self.base_dir, folder)
        os.makedirs(folder_path, exist_ok=True)

        # Generate unique filename to avoid collisions
        unique_filename = f"{uuid.uuid4().hex}_{filename}"
        file_path = os.path.join(folder_path, unique_filename)

        # Write file
        with open(file_path, "wb") as f:
            content = file.read()
            f.write(content)
            file_size = len(content)

        return file_path, file_size

    def delete_file(self, file_path: str) -> bool:
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                return True
            return False
        except Exception:
            return False

    def get_download_url(self, file_path: str, expires_in: int = 3600) -> str:
        # For local storage, return the file path
        # In a real app, you'd serve this through an endpoint
        return f"/files/{file_path}"


class S3Storage(StorageBackend):
    """AWS S3 storage (for production)."""

    def __init__(
        self,
        bucket_name: str,
        region: str = "us-east-1",
        access_key_id: Optional[str] = None,
        secret_access_key: Optional[str] = None
    ):
        self.bucket_name = bucket_name
        self.region = region

        # Initialize S3 client
        # If credentials not provided, boto3 will use:
        # 1. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
        # 2. Shared credentials file (~/.aws/credentials)
        # 3. IAM role (when running on AWS)
        if access_key_id and secret_access_key:
            self.s3_client = boto3.client(
                "s3",
                region_name=region,
                aws_access_key_id=access_key_id,
                aws_secret_access_key=secret_access_key
            )
        else:
            self.s3_client = boto3.client("s3", region_name=region)

    def upload_file(
        self,
        file: BinaryIO,
        filename: str,
        folder: str,
        content_type: Optional[str] = None
    ) -> tuple[str, int]:
        # Generate unique key (path in S3)
        unique_filename = f"{uuid.uuid4().hex}_{filename}"
        s3_key = f"{folder}/{unique_filename}"

        # Read file content to get size
        content = file.read()
        file_size = len(content)

        # Reset file pointer
        file.seek(0)

        # Upload to S3
        extra_args = {}
        if content_type:
            extra_args["ContentType"] = content_type

        self.s3_client.put_object(
            Bucket=self.bucket_name,
            Key=s3_key,
            Body=content,
            **extra_args
        )

        return s3_key, file_size

    def delete_file(self, file_path: str) -> bool:
        try:
            self.s3_client.delete_object(
                Bucket=self.bucket_name,
                Key=file_path
            )
            return True
        except ClientError:
            return False

    def get_download_url(self, file_path: str, expires_in: int = 3600) -> str:
        """
        Generate a pre-signed URL for downloading.

        Pre-signed URLs allow temporary access to private S3 objects.
        They include a signature that expires after the specified time.
        """
        try:
            url = self.s3_client.generate_presigned_url(
                "get_object",
                Params={
                    "Bucket": self.bucket_name,
                    "Key": file_path
                },
                ExpiresIn=expires_in
            )
            return url
        except ClientError:
            return ""

    def get_upload_url(self, file_path: str, content_type: str, expires_in: int = 3600) -> str:
        """
        Generate a pre-signed URL for uploading directly from browser.

        This allows the frontend to upload directly to S3 without
        going through your server - faster and reduces server load.
        """
        try:
            url = self.s3_client.generate_presigned_url(
                "put_object",
                Params={
                    "Bucket": self.bucket_name,
                    "Key": file_path,
                    "ContentType": content_type
                },
                ExpiresIn=expires_in
            )
            return url
        except ClientError:
            return ""


def get_storage() -> StorageBackend:
    """
    Factory function to get the appropriate storage backend.
    Uses S3 if USE_S3=true and bucket is configured, otherwise local storage.
    """
    if settings.USE_S3 and settings.AWS_S3_BUCKET:
        return S3Storage(
            bucket_name=settings.AWS_S3_BUCKET,
            region=settings.AWS_REGION,
            access_key_id=settings.AWS_ACCESS_KEY_ID,
            secret_access_key=settings.AWS_SECRET_ACCESS_KEY
        )
    return LocalStorage()
