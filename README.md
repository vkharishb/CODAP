# CODAP — Centralised Observability & Deployment Analytics Platform

Centralised observability and deployment analytics platform on AWS EKS. Combines a
GitOps-driven deployment pipeline with full-stack monitoring and a custom
DORA metrics service that turns raw CI/CD and deployment data into the four
key delivery metrics engineering teams actually get measured on.

![status](https://img.shields.io/badge/status-in%20progress-yellow)
![terraform](https://img.shields.io/badge/terraform-%3E%3D1.6-623CE4)
![kubernetes](https://img.shields.io/badge/kubernetes-1.30-326CE5)
![license](https://img.shields.io/badge/license-MIT-blue)

## Why this exists

Most "I deployed Prometheus" portfolio projects stop at infrastructure. CODAP
pairs infrastructure with the thing engineering leadership actually cares
about: **can you tell me how fast and how safely we're shipping?** It answers
that with a Python service that computes DORA metrics — deployment
frequency, lead time for changes, change failure rate, and MTTR — directly
from GitHub Actions and ArgoCD, and surfaces them next to the infra metrics
in the same Grafana instance.

## Architecture

```
GitHub repo → GitHub Actions (build, SonarQube, Trivy) → ECR
                                                             │
GitHub repo → ArgoCD (GitOps sync) ─────────────────────────┘
                    │
                    ▼
            AWS EKS cluster
        ┌───────────────────────┐
        │  App workloads         │  Prometheus, Loki,
        │  (RBAC-scoped)         │  Grafana dashboards
        └───────────────────────┘
                    │
     ┌──────────────┴──────────────┐
     ▼                              ▼
DORA analytics service         Postgres
(Python, pulls CI + ArgoCD   → deployment frequency,
 sync history)                 lead time, MTTR
                    │
                    ▼
              Grafana dashboard
```

A rendered version of this diagram is in [`docs/architecture.md`](docs/architecture.md).

## Tech stack

| Layer | Tools |
|---|---|
| Infra as Code | Terraform (VPC, EKS, IAM/IRSA, remote state in S3 + DynamoDB) |
| Orchestration | Amazon EKS (Kubernetes 1.30) |
| GitOps / CD | ArgoCD (app-of-apps pattern) |
| CI / DevSecOps | GitHub Actions, SonarQube, Trivy, Nexus |
| Observability | Prometheus, Grafana, Loki, kube-state-metrics |
| Deployment analytics | Python, Postgres, GitHub Actions API, ArgoCD API |
| Policy as code | OPA / Gatekeeper |

## Repo layout

```
codap/
├── infra/                  # Terraform: VPC, EKS, IAM/IRSA, remote state
│   ├── modules/{vpc,eks,irsa}
│   └── envs/{dev,prod}
├── gitops/                 # ArgoCD app-of-apps, per-environment Helm values
├── ci/                     # GitHub Actions workflows
├── observability/          # Prometheus/Grafana/Loki Helm values, alert rules
├── dora-metrics-service/   # Python service computing DORA metrics
│   ├── collectors/         # github_actions.py, argocd.py
│   ├── metrics.py
│   └── db/                 # Postgres schema + migrations
├── policies/                # OPA/Gatekeeper policies
├── docs/                     # architecture.md, runbook.md
└── README.md
```

## Getting started

### 1. Provision infrastructure
```bash
cd infra/envs/dev
terraform init
terraform plan
terraform apply
aws eks update-kubeconfig --region ap-south-1 --name codap-dev
```
Full prerequisites (S3 backend bootstrap, account ID substitution) are in
[`infra/README.md`](infra/README.md).

### 2. Bootstrap ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f gitops/argocd/install.yaml
kubectl apply -f gitops/apps/app-of-apps.yaml
```

### 3. Deploy the observability stack
Managed by ArgoCD from `observability/` — no manual `helm install` needed
once the app-of-apps is synced.

### 4. Run the DORA metrics service
```bash
cd dora-metrics-service
pip install -r requirements.txt
python metrics.py --since 30d
```

## DORA metrics

| Metric | What it measures | Source |
|---|---|---|
| Deployment frequency | How often we ship to production | ArgoCD sync history |
| Lead time for changes | Commit → production | GitHub Actions + ArgoCD timestamps |
| Change failure rate | % of deploys causing a rollback | ArgoCD sync status + rollback events |
| Time to restore | How fast we recover from a failed deploy | ArgoCD rollback timestamps |

## Status

- [x] Terraform: VPC, EKS, IRSA
- [ ] ArgoCD app-of-apps
- [ ] Observability stack (Prometheus/Grafana/Loki)
- [ ] GitHub Actions DevSecOps pipeline
- [ ] DORA metrics service
- [ ] OPA/Gatekeeper policies

## License
Harish Bodapati