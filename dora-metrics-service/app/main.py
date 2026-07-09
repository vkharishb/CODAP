from __future__ import annotations

from datetime import datetime, timezone, timedelta
from typing import Annotated

from fastapi import FastAPI, Response, status
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest

from app.metrics import record_deployment, record_incident, summarize
from app.models import DeploymentEvent, IncidentEvent
from app.settings import settings

app = FastAPI(
    title="CODAP DORA Metrics Service",
    description="Centralised Observability & Deployment Analytics Platform API",
    version="1.0.0",
)

# In-memory storage keeps the project zero-budget and demo-friendly. For real
# production use, replace this with Postgres using db/schema.sql.
deployments: list[DeploymentEvent] = []
incidents: list[IncidentEvent] = []


@app.on_event("startup")
async def seed_demo_data() -> None:
    if deployments:
        return
    now = datetime.now(timezone.utc)
    demo_events = [
        DeploymentEvent(
            application="demo-api",
            environment=settings.environment,
            version="v1.0.0",
            commit_sha="demo001",
            pipeline_url="https://github.com/example/codap/actions/runs/1",
            started_at=now - timedelta(hours=5, minutes=15),
            finished_at=now - timedelta(hours=5),
            status="success",
        ),
        DeploymentEvent(
            application="demo-api",
            environment=settings.environment,
            version="v1.0.1",
            commit_sha="demo002",
            pipeline_url="https://github.com/example/codap/actions/runs/2",
            started_at=now - timedelta(hours=3, minutes=20),
            finished_at=now - timedelta(hours=3),
            status="failed",
        ),
        DeploymentEvent(
            application="demo-api",
            environment=settings.environment,
            version="v1.0.2",
            commit_sha="demo003",
            pipeline_url="https://github.com/example/codap/actions/runs/3",
            started_at=now - timedelta(hours=1, minutes=10),
            finished_at=now - timedelta(hours=1),
            status="success",
        ),
    ]
    for event in demo_events:
        deployments.append(event)
        record_deployment(event)

    incident = IncidentEvent(
        application="demo-api",
        environment=settings.environment,
        incident_id="INC-DEMO-001",
        started_at=now - timedelta(hours=3),
        resolved_at=now - timedelta(hours=2, minutes=40),
    )
    incidents.append(incident)
    record_incident(incident)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": settings.service_name, "environment": settings.environment}


@app.get("/api/v1/deployments")
def list_deployments() -> list[DeploymentEvent]:
    return deployments


@app.post("/api/v1/deployments", status_code=status.HTTP_202_ACCEPTED)
def create_deployment(event: DeploymentEvent) -> dict[str, str]:
    deployments.append(event)
    record_deployment(event)
    return {"status": "accepted", "application": event.application, "version": event.version}


@app.post("/api/v1/incidents", status_code=status.HTTP_202_ACCEPTED)
def create_incident(incident: IncidentEvent) -> dict[str, str]:
    incidents.append(incident)
    record_incident(incident)
    return {"status": "accepted", "incident_id": incident.incident_id}


@app.get("/api/v1/dora/summary")
def dora_summary():
    return summarize(deployments, incidents)


@app.get("/metrics")
def metrics() -> Response:
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)
