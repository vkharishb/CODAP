from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration for CODAP DORA metrics service."""

    service_name: str = "codap-dora-metrics-service"
    environment: str = "dev"
    log_level: str = "INFO"

    # Optional integrations. The service still runs without these values and
    # can receive deployment events through the REST API.
    github_owner: str | None = None
    github_repo: str | None = None
    github_token: str | None = None
    argocd_url: str | None = None
    argocd_token: str | None = None

    model_config = SettingsConfigDict(env_prefix="CODAP_", env_file=".env", extra="ignore")


settings = Settings()
