from __future__ import annotations

from collections import defaultdict
from datetime import datetime, timezone
from statistics import mean
from typing import Iterable

from prometheus_client import Counter, Gauge, Histogram

from app.models import DeploymentEvent, DoraSummary, IncidentEvent


deployments_total = Counter(
    "codap_deployments_total",
    "Total deployments tracked by CODAP",
    ["application", "environment", "status"],
)

change_failures_total = Counter(
    "codap_change_failures_total",
    "Deployments that failed or triggered rollback",
    ["application", "environment"],
)

lead_time_seconds = Histogram(
    "codap_lead_time_seconds",
    "Commit to deployment lead time in seconds",
    ["application", "environment"],
    buckets=(60, 300, 900, 1800, 3600, 7200, 14400, 28800, 86400, 172800),
)

mttr_seconds = Histogram(
    "codap_mttr_seconds",
    "Mean time to restore service in seconds",
    ["application", "environment"],
    buckets=(60, 300, 900, 1800, 3600, 7200, 14400, 28800, 86400),
)

latest_deployment_timestamp = Gauge(
    "codap_latest_deployment_timestamp",
    "Unix timestamp of the latest deployment",
    ["application", "environment", "version"],
)


def duration_seconds(start: datetime, end: datetime) -> float:
    return max((end - start).total_seconds(), 0.0)


def record_deployment(event: DeploymentEvent) -> None:
    deployments_total.labels(event.application, event.environment, event.status.value).inc()
    if event.status.value in {"failed", "rollback"}:
        change_failures_total.labels(event.application, event.environment).inc()
    lead_time_seconds.labels(event.application, event.environment).observe(
        duration_seconds(event.started_at, event.finished_at)
    )
    latest_deployment_timestamp.labels(
        event.application, event.environment, event.version
    ).set(event.finished_at.timestamp())


def record_incident(incident: IncidentEvent) -> None:
    if incident.resolved_at:
        mttr_seconds.labels(incident.application, incident.environment).observe(
            duration_seconds(incident.started_at, incident.resolved_at)
        )


def summarize(
    deployments: Iterable[DeploymentEvent], incidents: Iterable[IncidentEvent]
) -> list[DoraSummary]:
    grouped: dict[tuple[str, str], list[DeploymentEvent]] = defaultdict(list)
    incident_grouped: dict[tuple[str, str], list[IncidentEvent]] = defaultdict(list)

    for event in deployments:
        grouped[(event.application, event.environment)].append(event)
    for incident in incidents:
        incident_grouped[(incident.application, incident.environment)].append(incident)

    summaries: list[DoraSummary] = []
    for (application, environment), events in grouped.items():
        successful = [e for e in events if e.status.value == "success"]
        failed = [e for e in events if e.status.value in {"failed", "rollback"}]
        lead_times = [duration_seconds(e.started_at, e.finished_at) for e in events]
        first = min(e.finished_at for e in events)
        last = max(e.finished_at for e in events)
        days = max((last - first).total_seconds() / 86400, 1.0)

        related_incidents = incident_grouped.get((application, environment), [])
        mttrs = [
            duration_seconds(i.started_at, i.resolved_at)
            for i in related_incidents
            if i.resolved_at is not None
        ]

        summaries.append(
            DoraSummary(
                application=application,
                environment=environment,
                deployments_total=len(events),
                successful_deployments=len(successful),
                failed_deployments=len(failed),
                deployment_frequency_per_day=round(len(events) / days, 2),
                average_lead_time_seconds=round(mean(lead_times), 2) if lead_times else 0.0,
                change_failure_rate_percent=round((len(failed) / len(events)) * 100, 2) if events else 0.0,
                average_mttr_seconds=round(mean(mttrs), 2) if mttrs else 0.0,
                calculated_at=datetime.now(timezone.utc),
            )
        )
    return summaries
