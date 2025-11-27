from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "TaskFlow"
    DATABASE_URL: str = "sqlite:///./taskflow.db"
    SECRET_KEY: str = "dev-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    class Config:
        env_file = ".env"


settings = Settings()
