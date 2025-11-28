import json
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from app.config import settings


def get_database_url() -> str:
    """
    Get database URL, optionally fetching credentials from Secrets Manager.
    """
    # If using Secrets Manager (production), fetch credentials
    if settings.USE_SECRETS_MANAGER and settings.DB_SECRET_NAME:
        import boto3
        client = boto3.client("secretsmanager", region_name=settings.AWS_REGION)
        response = client.get_secret_value(SecretId=settings.DB_SECRET_NAME)
        secret = json.loads(response["SecretString"])
        return secret["url"]  # Pre-built connection URL from Secrets Manager

    # Otherwise use DATABASE_URL from environment
    return settings.DATABASE_URL


def create_db_engine():
    """
    Create SQLAlchemy engine with appropriate settings for SQLite or PostgreSQL.
    """
    db_url = get_database_url()

    # SQLite requires check_same_thread=False
    if db_url.startswith("sqlite"):
        return create_engine(db_url, connect_args={"check_same_thread": False})

    # PostgreSQL with connection pooling
    return create_engine(
        db_url,
        pool_size=5,
        max_overflow=10,
        pool_pre_ping=True,  # Verify connections before use
    )


engine = create_db_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
