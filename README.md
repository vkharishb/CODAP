# CODAP — Centralised Observability & Deployment Analytics Platform

CODAP is a production-style platform that combines **EKS deployment automation**, **GitOps**, **Prometheus/Grafana observability**, and **DORA deployment analytics** in one portfolio-ready project.

It is designed to answer two important questions:

1. **Is the platform healthy?** — cluster, pod, node, request, CPU, memory, restart, and availability metrics.
2. **Are deployments healthy?** — deployment frequency, lead time, change failure rate, and MTTR.

---

## What is included

| Area | Included assets |
|---|---|
| CODAP source code | `dora-metrics-service/`, `demo-app/`, GitOps manifests, Terraform modules, CI/CD workflow |
| Grafana JSON | `observability/dashboards/codap-deployment-analytics-dashboard.json` |
| Demo app deployment from EKS | `demo-app/` source and `gitops/manifests/demo/` Kubernetes manifests |
| Link between demo app and CODAP | Prometheus scrape annotations, dashboard UID annotations, app labels, DORA deployment endpoint, GitHub Actions deployment metadata |
| Documentation | `docs/architecture.md`, `docs/deployment-guide.md`, `docs/observability-guide.md`, `docs/runbook.md`, `docs/templates.md` |
| Folder structure | Clean GitHub-ready structure documented below |
| GitHub README | This file |
| Templates | `templates/`, `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md` |

---

## Architecture

```text
Developer Push
     |
     v
GitHub Actions CI/CD
  - lint/test
  - docker build
  - image scan placeholder
  - push image to ECR
  - update GitOps image tag
     |
     v
Git repository desired state
     |
     v
ArgoCD app-of-apps
     |
     v
AWS EKS
  - demo-api workload
  - dora-metrics-service
  - kube-prometheus-stack
     |
     v
Prometheus + Grafana
  - infra metrics
  - application metrics
  - DORA metrics dashboard
```

---

## Folder structure

```text
CODAP/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── workflows/ci-cd.yml
│   └── pull_request_template.md
├── demo-app/                         # Demo application source code
│   ├── src/server.js
│   ├── package.json
│   └── Dockerfile
├── dora-metrics-service/             # CODAP analytics service
│   ├── app/
│   │   ├── main.py
│   │   ├── metrics.py
│   │   ├── models.py
│   │   ├── settings.py
│   │   └── collectors/
│   ├── chart/                        # Helm chart for EKS deployment
│   ├── db/schema.sql
│   ├── Dockerfile
│   └── requirements.txt
├── docs/
├── gitops/
│   ├── argocd/root-app.yaml
│   ├── apps/
│   ├── manifests/demo/
│   └── manifests/dora-metrics/
├── observability/
│   ├── alerts/
│   ├── dashboards/
│   └── values-dev.yaml
├── policies/
├── templates/
└── terraform/
    ├── envs/dev/
    └── modules/{vpc,eks,irsa}/
```

---

## Prerequisites

Install these tools on your laptop or build machine:

- AWS CLI configured for the target account
- Terraform `>= 1.6`
- kubectl
- Helm
- Docker
- ArgoCD CLI, optional but useful
- GitHub repository secrets for CI/CD

Required GitHub secrets for the pipeline:

| Secret | Purpose |
|---|---|
| `AWS_ROLE_TO_ASSUME` | GitHub Actions OIDC role for AWS deployment |
| `AWS_REGION` | Example: `ap-south-1` |
| `ECR_REPOSITORY` | Example: `codap-demo-api` |
| `GITOPS_PAT` | Fine-grained token to commit image tag updates, if default token is restricted |

---

## 1. Provision EKS infrastructure

```bash
cd terraform/envs/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
```

Configure kubectl:

```bash
aws eks update-kubeconfig --region ap-south-1 --name codap-dev
kubectl get nodes
```

Important EKS subnet tags are already included in `terraform/modules/vpc/main.tf`:

```text
kubernetes.io/cluster/<cluster-name> = shared
kubernetes.io/role/elb              = 1
kubernetes.io/role/internal-elb     = 1
```

---

## 2. Install ArgoCD and bootstrap CODAP

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deployment/argocd-server
kubectl apply -f gitops/projects/codap-project.yaml
kubectl apply -f gitops/argocd/root-app.yaml
```

Open ArgoCD locally:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Then open:

```text
https://localhost:8080
```

---

## 3. Deploy observability stack

The observability stack is deployed by ArgoCD through:

```text
gitops/apps/observability-app.yaml
```

Grafana access:

```bash
kubectl -n monitoring port-forward svc/observability-grafana 3000:80
```

Open:

```text
http://localhost:3000
```

The dashboard JSON is located at:

```text
observability/dashboards/codap-deployment-analytics-dashboard.json
```

---

## 4. Deploy demo app from EKS

Demo app source:

```text
demo-app/
```

Kubernetes deployment:

```text
gitops/manifests/demo/02-demo-api.yaml
```

Check from EKS:

```bash
kubectl -n demo get pods,svc,hpa
kubectl -n demo port-forward svc/demo-api 8081:80
curl http://localhost:8081/health
curl http://localhost:8081/metrics
```

The demo app is linked to CODAP using:

- Prometheus scrape annotations
- Standard Kubernetes labels
- `codap.io/dashboard-uid: codap-deployment-analytics`
- GitHub Actions deployment metadata sent to the DORA service

---

## 5. Deploy DORA metrics service

The DORA service exposes Prometheus metrics and REST APIs.

Run locally:

```bash
cd dora-metrics-service
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

Check:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/dora/summary
curl http://localhost:8080/metrics
```

Deploy to EKS through ArgoCD:

```bash
kubectl apply -f gitops/apps/dora-metrics-app.yaml
kubectl -n dora-metrics get pods,svc
```

---

## 6. CI/CD deployment flow

The included workflow is:

```text
.github/workflows/ci-cd.yml
```

It performs:

1. Node.js test for the demo app.
2. Docker image build.
3. ECR login and push.
4. GitOps image tag update.
5. Deployment event submission to CODAP DORA service.

---

## DORA metrics exposed

| Metric | Prometheus name | Meaning |
|---|---|---|
| Deployment frequency | `codap_deployments_total` | Number of deployments by app/environment/status |
| Lead time | `codap_lead_time_seconds` | Commit-to-deployment duration |
| Change failure rate | `codap_change_failures_total / codap_deployments_total` | Failed or rolled-back deployments |
| MTTR | `codap_mttr_seconds` | Time from incident start to recovery |

---

## Interview explanation

> CODAP is a centralized observability and deployment analytics platform built on EKS. It uses Terraform to provision the AWS foundation, ArgoCD for GitOps deployments, Prometheus and Grafana for metrics, and a custom DORA metrics service to track deployment frequency, lead time, failure rate, and MTTR. The demo app is deployed to EKS and connected to CODAP through Prometheus metrics, Kubernetes labels, dashboard annotations, and CI/CD deployment events.

---

## Current status

| Component | Status |
|---|---|
| Terraform VPC/EKS | Ready |
| EKS subnet tags | Added |
| ArgoCD app-of-apps | Ready |
| Observability stack | Ready |
| Grafana dashboard JSON | Ready |
| Demo app source | Ready |
| Demo app Kubernetes manifests | Ready |
| DORA metrics service | Ready |
| Helm chart | Ready |
| GitHub Actions workflow | Ready |
| Documentation/templates | Ready |

---

## Author

VK Harish Bodapati
