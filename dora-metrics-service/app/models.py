from datetime import datetime, timezone
from enum import Enum
from pydantic import BaseModel, Field


class DeploymentStatus(str, Enum):
    success = "success"
    failed = "failed"
    rollback = "rollback"


class DeploymentEvent(BaseModel):
    application: str = Field(..., examples=["demo-api"])
    environment: str = Field(default="dev", examples=["dev"])
    version: str = Field(..., examples=["sha-abc1234"])
    commit_sha: str = Field(..., examples=["abc123456789"])
    pipeline_url: str | None = None
    started_at: datetime
    finished_at: datetime
    status: DeploymentStatus = DeploymentStatus.success


class IncidentEvent(BaseModel):
    application: str
    environment: str = "dev"
    incident_id: str
    started_at: datetime
    resolved_at: datetime | None = None


class DoraSummary(BaseModel):
    application: str
    environment: str
    deployments_total: int
    successful_deployments: int
    failed_deployments: int
    deployment_frequency_per_day: float
    average_lead_time_seconds: float
    change_failure_rate_percent: float
    average_mttr_seconds: float
    calculated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
