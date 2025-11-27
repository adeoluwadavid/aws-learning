from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    APP_NAME: str = "TaskFlow"
    DATABASE_URL: str = "sqlite:///./taskflow.db"
    SECRET_KEY: str = "dev-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # S3 Configuration
    # Set USE_S3=true to use S3 instead of local storage
    USE_S3: bool = False
    AWS_S3_BUCKET: Optional[str] = None
    AWS_REGION: str = "us-east-1"
    # AWS credentials are loaded from environment or ~/.aws/credentials
    AWS_ACCESS_KEY_ID: Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None

    class Config:
        env_file = ".env"


settings = Settings()
