"""ArgoCD collector placeholder.

Use this module to query ArgoCD Application history and sync status. The Helm
chart passes CODAP_ARGOCD_URL and CODAP_ARGOCD_TOKEN as environment variables
when you are ready to enable live collection.
"""

from app.models import DeploymentEvent


async def collect_deployments() -> list[DeploymentEvent]:
    return []
