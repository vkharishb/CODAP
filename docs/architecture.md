# CODAP Architecture

CODAP has four layers.

## 1. Infrastructure layer

Terraform provisions:

- VPC
- Public subnets for internet-facing load balancers and NAT
- Private subnets for EKS worker nodes
- EKS cluster
- Managed node group
- OIDC provider for IRSA
- IAM role for the DORA metrics service

## 2. Deployment layer

ArgoCD uses the app-of-apps pattern.

- `gitops/argocd/root-app.yaml` is the only app applied manually.
- `gitops/apps/` contains child applications.
- Demo workload, DORA service, and observability stack are managed from Git.

## 3. Observability layer

`kube-prometheus-stack` deploys:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter

CODAP adds:

- Dashboard JSON
- Prometheus alert rules
- Pod scrape annotations
- Standard app labels

## 4. Deployment analytics layer

The DORA service receives deployment events from CI/CD and exposes Prometheus metrics.

```text
GitHub Actions -> POST /api/v1/deployments -> DORA service -> /metrics -> Prometheus -> Grafana
```

## Data flow

```text
Demo app metrics -----------> Prometheus -----> Grafana dashboard
Kubernetes metrics ---------> Prometheus -----> Grafana dashboard
GitHub Actions deployment --> DORA service ---> Prometheus -----> Grafana dashboard
ArgoCD sync status ---------> DORA service ---> Prometheus -----> Grafana dashboard
```
