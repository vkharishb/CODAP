# Grafana Endpoint Proof

After `CODAP Deploy to EKS` completes, the workflow prints a clickable Grafana endpoint in the GitHub Actions job summary and uploads a proof artifact.

## Why this was added

Earlier, Grafana was accessible only through `kubectl port-forward`, which is good for local testing but not suitable as a one-click GitHub Actions proof link. The observability Helm values now expose Grafana with a Kubernetes `LoadBalancer` service so AWS creates a public load balancer endpoint.

## Where to find the endpoint

1. Open GitHub repo.
2. Go to **Actions**.
3. Open **CODAP Deploy to EKS** successful run.
4. Open the job summary.
5. Click **CODAP Dashboard**.

The workflow also uploads an artifact named:

```text
codap-grafana-endpoint-proof
```

## Login

Username:

```text
admin
```

Get password:

```bash
kubectl -n monitoring get secret observability-grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

## Important security note

A public Grafana LoadBalancer is useful for proof and demos, but it should not be left public permanently. After taking screenshots, either restrict access, change the password, or switch the service back to `ClusterIP` and use port-forward.
