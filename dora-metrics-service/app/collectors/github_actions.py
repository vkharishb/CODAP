"""GitHub Actions collector placeholder.

The API service can run without this collector. In production, use this file to
pull workflow runs through the GitHub API and convert them into DeploymentEvent
records. Keeping this separated avoids mixing external API code with the main
FastAPI application.
"""

from app.models import DeploymentEvent


async def collect_deployments() -> list[DeploymentEvent]:
    return []
