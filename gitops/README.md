# CODAP GitOps

This folder implements the ArgoCD app-of-apps pattern for CODAP.

## Layout

```text
gitops/
├── argocd/root-app.yaml
├── projects/codap-project.yaml
├── apps/
│   ├── observability-app.yaml
│   ├── codap-dashboards-app.yaml
│   ├── demo-workloads-app.yaml
│   └── dora-metrics-app.yaml
└── manifests/
    ├── demo/
    ├── dora-metrics/
    └── observability-dashboards/
```

## Bootstrap

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deployment/argocd-server
kubectl apply -f gitops/projects/codap-project.yaml
kubectl apply -f gitops/argocd/root-app.yaml
```

## Sync waves

| Wave | Application | Purpose |
|---|---|---|
| 0 | observability | Installs kube-prometheus-stack |
| 1 | codap-dashboards | Adds CODAP Grafana dashboard ConfigMap |
| 1 | demo-workloads | Deploys the demo app to EKS |
| 2 | dora-metrics | Deploys the deployment analytics API/exporter |

## Required replacement

Before pushing to GitHub, replace this placeholder in all GitOps files:

```text
https://github.com/<your-github-username>/CODAP.git
```

with your real repository URL.

## Verify

```bash
kubectl -n argocd get applications
kubectl -n monitoring get pods,cm
kubectl -n demo get pods,svc,hpa
kubectl -n dora-metrics get pods,svc
```
