# CODAP — Centralised Observability & Deployment Analytics Platform

[![CODAP CI](https://github.com/vkharishb/CODAP/actions/workflows/01-ci.yml/badge.svg)](https://github.com/vkharishb/CODAP/actions/workflows/01-ci.yml)
[![Build Security Push](https://github.com/vkharishb/CODAP/actions/workflows/04-build-security-push.yml/badge.svg)](https://github.com/vkharishb/CODAP/actions/workflows/04-build-security-push.yml)
[![Deploy Application](https://github.com/vkharishb/CODAP/actions/workflows/05-deploy-application.yml/badge.svg)](https://github.com/vkharishb/CODAP/actions/workflows/05-deploy-application.yml)

CODAP is a production-style AWS platform that combines **EKS infrastructure automation**, **secure CI/CD**, **Kubernetes application deployment**, **Prometheus/Grafana observability**, and **DORA engineering metrics** in one portfolio project.

The platform answers two operational questions:

1. **Is the platform healthy?**  
   Monitor EKS nodes, Kubernetes workloads, CPU, memory, restarts, HTTP traffic, storage, and availability.

2. **Are software deliveries healthy?**  
   Measure deployment frequency, lead time, change failure rate, and mean time to restore service.

---

## Platform capabilities

| Area | Implementation |
|---|---|
| Infrastructure as Code | Terraform modules for VPC, EKS, IAM, IRSA, KMS, EBS CSI, networking, and EKS access management |
| Application workloads | Node.js demo API and Python FastAPI DORA metrics service |
| Container platform | Amazon EKS with managed node groups running in private subnets |
| Container registry | Amazon ECR repositories created and populated by GitHub Actions |
| Observability | kube-prometheus-stack, Prometheus, Grafana, kube-state-metrics, and node exporter |
| DORA analytics | Deployment and incident APIs, Prometheus metrics, and a Grafana dashboard |
| Security checks | SonarQube, OWASP Dependency-Check, Trivy filesystem/IaC scanning, and Trivy image scanning |
| Storage | Amazon EBS CSI managed add-on and a Terraform-managed `gp3` StorageClass |
| Deployment automation | Ordered GitHub Actions workflow chain from AWS authentication through live Grafana proof |
| GitOps option | ArgoCD App-of-Apps definitions retained as an optional deployment model |
| Operational diagnostics | Automatic Kubernetes, Helm, Grafana, storage, and event collection after deployment failures |

---

## Architecture

```text
Developer push to main or devops
              |
              v
00 - AWS Role Test
  GitHub OIDC -> AWS STS identity validation
              |
              v
01 - CODAP CI
  Node.js validation
  Python/FastAPI validation
  Docker builds
  Terraform fmt/init/validate
  Helm lint/template
  Kubernetes schema validation
              |
              v
02 - Terraform Plan
  S3 backend preparation
  Terraform plan artifact
              |
              v
03 - Terraform Apply
  VPC + EKS + IAM + KMS
  Managed node group
  EBS CSI add-on + gp3 StorageClass
              |
              v
04 - Build Security Push
  Tests and coverage
  SonarQube
  OWASP Dependency-Check
  Trivy filesystem, IaC, and image scans
  Docker build and push to ECR
              |
              v
05 - Deploy Application
  kube-prometheus-stack
  Grafana dashboard ConfigMap
  DORA metrics Helm release
  Demo API Kubernetes manifests
  Failure diagnostics artifact
              |
              v
06 - Grafana Live
  Public Grafana endpoint
  Dashboard link and proof artifact
```

A separate manual workflow, **99 - Terraform Destroy**, validates the request, creates a reviewed destroy plan, applies the exact saved plan, and adds additional protection for production destruction.

---

## Repository structure

```text
CODAP/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── workflows/
│   │   ├── 00-aws-role-test.yml
│   │   ├── 01-ci.yml
│   │   ├── 02-terraform-plan.yml
│   │   ├── 03-terraform-apply.yml
│   │   ├── 04-build-security-push.yml
│   │   ├── 05-deploy-application.yml
│   │   ├── 06-grafana-live.yml
│   │   └── 99-terraform-destroy.yml
│   └── pull_request_template.md
├── demo-app/
│   ├── src/
│   │   └── server.js
│   ├── package.json
│   ├── package-lock.json
│   └── Dockerfile
├── dora-metrics-service/
│   ├── app/
│   │   ├── main.py
│   │   ├── metrics.py
│   │   ├── models.py
│   │   └── settings.py
│   ├── chart/
│   │   ├── templates/
│   │   ├── Chart.yaml
│   │   └── values.yaml
│   ├── db/
│   │   └── schema.sql
│   ├── requirements.txt
│   └── Dockerfile
├── gitops/
│   ├── argocd/
│   │   └── root-app.yaml
│   ├── apps/
│   │   ├── dora-metrics-app.yaml
│   │   └── observability-app.yaml
│   ├── projects/
│   │   └── codap-project.yaml
│   └── manifests/
│       ├── demo/
│       │   ├── namespace-rbac.yaml
│       │   └── demo-api.yaml
│       ├── dora-metrics/
│       └── observability-dashboards/
├── observability/
│   ├── alerts/
│   ├── dashboards/
│   │   └── codap-deployment-analytics-dashboard.json
│   └── values-dev.yaml
├── policies/
├── scripts/
│   └── collect-k8s-diagnostics.sh
├── templates/
├── terraform/
│   ├── envs/
│   │   ├── dev/
│   │   │   ├── backend.tf
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── storageclass.tf
│   │   │   └── variables.tf
│   │   └── prod/
│   │       ├── backend.tf
│   │       ├── main.tf
│   │       ├── outputs.tf
│   │       └── variables.tf
│   └── modules/
│       ├── eks/
│       ├── irsa/
│       └── vpc/
├── .gitignore
└── README.md
```

The tree above focuses on the principal project assets and omits generated files, local Terraform state, downloaded dependencies, vulnerability reports, and workflow artifacts.

---

## Application components

### Demo API

`demo-app/` is an Express application used to generate real application metrics inside EKS.

| Endpoint | Purpose |
|---|---|
| `GET /` | Application, environment, version, and dashboard information |
| `GET /health` | Liveness health response |
| `GET /ready` | Readiness response |
| `GET /metrics` | Prometheus metrics |

Important metrics include:

- `codap_demo_http_requests_total`
- Node.js process metrics with the `codap_demo_` prefix

Run locally:

```bash
cd demo-app
npm ci
npm test
APP_ENV=local APP_VERSION=dev npm start
```

Verify:

```bash
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/ready
curl http://localhost:8080/metrics
```

### DORA metrics service

`dora-metrics-service/` is a FastAPI service that records deployment and incident events and exposes DORA summaries and Prometheus metrics.

| Endpoint | Purpose |
|---|---|
| `GET /health` | Service health |
| `GET /api/v1/deployments` | List deployment events |
| `POST /api/v1/deployments` | Record a deployment event |
| `POST /api/v1/incidents` | Record an incident |
| `GET /api/v1/dora/summary` | Return calculated DORA metrics |
| `GET /metrics` | Prometheus exposition endpoint |

Run locally:

```bash
cd dora-metrics-service
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
PYTHONPATH=. CODAP_ENVIRONMENT=local \
  uvicorn app.main:app --host 0.0.0.0 --port 9000
```

Verify:

```bash
curl http://localhost:9000/health
curl http://localhost:9000/api/v1/deployments
curl http://localhost:9000/api/v1/dora/summary
curl http://localhost:9000/metrics
```

The current service uses in-memory storage and seeded demonstration data. `dora-metrics-service/db/schema.sql` provides a starting point for a future persistent database implementation.

---

## DORA metrics

| Engineering metric | Prometheus metric | Meaning |
|---|---|---|
| Deployment frequency | `codap_deployments_total` | Total deployments by application, environment, and status |
| Change failure count | `codap_change_failures_total` | Failed or rolled-back deployments |
| Lead time | `codap_lead_time_seconds` | Duration from deployment start to completion |
| Mean time to restore | `codap_mttr_seconds` | Incident start-to-resolution duration |
| Latest deployment | `codap_latest_deployment_timestamp` | Timestamp of the latest deployed version |

The DORA summary API also calculates:

- Deployments per day
- Successful and failed deployment totals
- Average lead time
- Change failure rate percentage
- Average MTTR

---

## Terraform environments

### Development

The automated workflow chain currently provisions the `dev` environment.

| Setting | Development configuration |
|---|---|
| VPC CIDR | `10.0.0.0/16` |
| Availability Zones | `ap-south-1a`, `ap-south-1b` |
| Public subnets | 2 |
| Private subnets | 2 |
| NAT gateways | 1 shared NAT gateway |
| Worker type | `t3.medium` |
| Desired nodes | 2 |
| EKS API | Private endpoint enabled; public endpoint enabled |
| EKS version | `1.35` |

> The development variable currently permits `0.0.0.0/0` for the public EKS API endpoint. Replace it with a trusted `/32` administrator IP before using the environment outside a temporary demonstration.

### Production

A separate production Terraform configuration is included.

| Setting | Production configuration |
|---|---|
| VPC CIDR | `10.20.0.0/16` |
| Availability Zones | `ap-south-1a`, `ap-south-1b`, `ap-south-1c` |
| Public subnets | 3 |
| Private subnets | 3 |
| NAT gateways | One NAT gateway per public subnet |
| Worker type | `t3.large` |
| Desired nodes | 3 |
| EKS API | Private endpoint enabled; public endpoint disabled |
| EKS version | `1.35` |

Both environments reuse the Terraform modules under `terraform/modules/`.

### Infrastructure features

The Terraform implementation includes:

- VPC, public and private subnets, route tables, Internet Gateway, NAT Gateway, and EIP resources
- EKS control plane and managed node groups
- Worker nodes restricted to private subnets
- EKS secrets envelope encryption with AWS KMS
- EKS API and audit logging
- EKS access entries and cluster-admin policy association
- OIDC provider and IRSA support
- Amazon EBS CSI managed add-on
- Terraform-managed `gp3` StorageClass
- Kubernetes subnet discovery tags for external and internal load balancers
- S3 remote state with native lockfiles through `use_lockfile=true`

---

## GitHub Actions workflow chain

| Step | Workflow | Trigger | Main responsibility |
|---:|---|---|---|
| 00 | `00-aws-role-test.yml` | Push to selected project paths or manual | Validate GitHub OIDC authentication to AWS |
| 01 | `01-ci.yml` | Successful Workflow 00 or manual | Validate applications, Dockerfiles, Terraform, Helm, and Kubernetes manifests |
| 02 | `02-terraform-plan.yml` | Successful Workflow 01 or manual | Prepare backend and create the Terraform plan |
| 03 | `03-terraform-apply.yml` | Successful Workflow 02 or manual | Apply the development infrastructure |
| 04 | `04-build-security-push.yml` | Dispatched by Workflow 03 or manual | Test, scan, build, and push both images to ECR |
| 05 | `05-deploy-application.yml` | Dispatched by Workflow 04 or manual | Deploy monitoring, DORA service, and demo API to EKS |
| 06 | `06-grafana-live.yml` | Dispatched by Workflow 05 or manual | Expose Grafana and publish dashboard proof |
| 99 | `99-terraform-destroy.yml` | Manual only | Validate, plan, approve, and apply infrastructure destruction |

Workflow 04 uses immutable image tags in this format:

```text
run-<workflow-run-id>-<12-character-source-sha>
```

The same source SHA and build run ID are passed to Workflow 05 so that deployment uses exactly the images produced by Workflow 04.

---

## Security and quality controls

The pipeline includes the following checks:

- GitHub OIDC authentication instead of committed AWS access keys
- Node.js application tests and runtime smoke tests
- Python dependency installation, tests when present, and runtime smoke tests
- SonarQube code quality and coverage scanning when configured
- OWASP Dependency-Check for open-source dependency vulnerabilities
- Trivy filesystem and Infrastructure-as-Code scanning
- Trivy scanning of both Docker images
- Terraform formatting and validation
- Helm linting and template rendering
- Kubernetes manifest validation with kubeconform
- KMS encryption for EKS Kubernetes secrets
- Private EKS worker-node placement
- EBS CSI permissions through IRSA
- Generated scan, coverage, image metadata, deployment diagnostics, and Grafana proof artifacts

The current vulnerability steps generate reports without failing the pipeline on discovered HIGH or CRITICAL findings. Change the configured scan exit codes when enforcement is required.

---

## Prerequisites

Install or configure:

- AWS CLI v2
- Terraform `>= 1.6`
- Docker
- Node.js 20
- Python 3.11
- kubectl
- Helm
- `jq`
- An AWS account with permissions for VPC, EKS, IAM, KMS, EC2, EBS, ECR, S3, ELB, and CloudWatch
- A GitHub OIDC IAM role trusted by this repository

ArgoCD is optional because the current automated deployment path uses GitHub Actions, Helm, and kubectl directly.

---

## GitHub configuration

### Repository secrets

| Secret | Required | Purpose |
|---|---:|---|
| `AWS_ROLE_TO_ASSUME` | Yes | IAM role assumed by GitHub Actions through OIDC |
| `AWS_REGION` | Yes | AWS deployment region, currently designed for `ap-south-1` |
| `EKS_CLUSTER_NAME` | Yes for Workflows 05–06 | EKS cluster targeted by kubectl and Helm |
| `TF_BACKEND_BUCKET` | Recommended | S3 backend bucket used by plan, apply, and destroy |
| `SONAR_TOKEN` | Optional | SonarQube authentication |
| `SONAR_HOST_URL` | Optional | SonarQube server or SonarCloud URL |
| `SONAR_ORGANIZATION` | Optional | SonarCloud organization |
| `SONAR_PROJECT_KEY` | Optional | SonarQube project key |
| `NVD_API_KEY` | Optional | Faster authenticated NVD access for OWASP Dependency-Check |

`GITHUB_TOKEN` is provided automatically by GitHub Actions and is used to dispatch the downstream workflows.

### GitHub environments

Create at least:

- `dev` — used by Terraform Apply and Deploy Application
- `prod` — used by the destroy workflow when production is selected

Configure required reviewers for `prod` so production destruction cannot continue without approval.

---

## Automated deployment

1. Add the required repository secrets.
2. Configure the `dev` GitHub environment.
3. Push a project change to `main` or `devops`.
4. Follow the workflow chain from **00 - AWS Role Test** through **06 - Grafana Live**.
5. Download security, coverage, diagnostics, image metadata, and proof artifacts from the relevant workflow runs.

Workflow 00 starts automatically only when the push changes one of these areas:

```text
demo-app/**
dora-metrics-service/**
terraform/**
gitops/**
observability/**
.github/workflows/**
```

Use `workflow_dispatch` to run an individual workflow manually.

---

## Manual Terraform deployment

Authenticate to AWS first, then run:

```bash
terraform -chdir=terraform/envs/dev init
terraform -chdir=terraform/envs/dev fmt -check
terraform -chdir=terraform/envs/dev validate
terraform -chdir=terraform/envs/dev plan
terraform -chdir=terraform/envs/dev apply
```

The configured S3 backend bucket must already exist, or backend values must be supplied during `terraform init`.

Configure kubectl:

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name codap-dev

kubectl get nodes -o wide
kubectl get storageclass gp3
kubectl -n kube-system get pods \
  -l app.kubernetes.io/name=aws-ebs-csi-driver
```

---

## Verify the EKS deployment

```bash
kubectl -n monitoring get pods,svc,pvc
kubectl -n demo get deployment,pods,svc,hpa
kubectl -n dora-metrics get deployment,pods,svc
```

### Demo API

```bash
kubectl -n demo port-forward svc/demo-api 8081:80
```

In another terminal:

```bash
curl http://localhost:8081/
curl http://localhost:8081/health
curl http://localhost:8081/metrics
```

### DORA metrics service

```bash
kubectl -n dora-metrics \
  port-forward svc/dora-metrics-service 9000:80
```

In another terminal:

```bash
curl http://localhost:9000/health
curl http://localhost:9000/api/v1/dora/summary
curl http://localhost:9000/metrics
```

### Grafana

Workflow 06 patches `observability-grafana` to `LoadBalancer` and writes the public endpoint to the workflow summary and proof artifact.

Check the endpoint:

```bash
kubectl -n monitoring get svc observability-grafana -o wide
```

For local-only access:

```bash
kubectl -n monitoring \
  port-forward svc/observability-grafana 3000:80
```

Open:

```text
http://localhost:3000
```

Retrieve the generated Grafana admin password:

```bash
kubectl -n monitoring get secret observability-grafana \
  -o jsonpath='{.data.admin-password}' |
  base64 --decode

echo
```

The primary dashboard is:

```text
codap-deployment-analytics
```

Source JSON:

```text
observability/dashboards/codap-deployment-analytics-dashboard.json
```

---

## Optional ArgoCD deployment model

The repository retains an ArgoCD App-of-Apps structure:

```text
gitops/projects/codap-project.yaml
gitops/argocd/root-app.yaml
gitops/apps/
```

Install ArgoCD before applying these definitions:

```bash
kubectl create namespace argocd \
  --dry-run=client \
  -o yaml |
  kubectl apply -f -

kubectl apply \
  -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl -n argocd \
  rollout status deployment/argocd-server

kubectl apply -f gitops/projects/codap-project.yaml
kubectl apply -f gitops/argocd/root-app.yaml
```

The GitHub Actions deployment workflow does not require ArgoCD. Choose one primary reconciliation model for a shared environment to avoid GitHub Actions and ArgoCD competing over the same Kubernetes resources.

---

## Deployment diagnostics

If Workflow 05 fails, `scripts/collect-k8s-diagnostics.sh` captures:

- Cluster nodes and StorageClasses
- kube-system pods
- EBS CSI controller details
- Monitoring resources, PVCs, ConfigMaps, and events
- Grafana Deployment and pod descriptions
- Current and previous Grafana logs
- Helm status, values, and rendered manifest

The workflow uploads these files as:

```text
codap-deployment-diagnostics-<workflow-run-id>
```

---

## Safe Terraform destroy

Run **99 - Terraform Destroy** manually from GitHub Actions.

Inputs:

| Input | Requirement |
|---|---|
| `destroy_action` | Select `DESTROY` |
| `target_environment` | Select the Terraform environment |
| `prod_username` | Required for production and must match the triggering GitHub username |

The workflow:

1. Validates the action and environment.
2. Validates the production username when applicable.
3. Creates a Terraform destroy plan.
4. Lists every resource marked for deletion.
5. Uploads the exact reviewed plan.
6. Uses the selected GitHub environment for approval.
7. Applies the saved plan.

### Clean Kubernetes-created load balancers first

Kubernetes `LoadBalancer` Services create AWS resources outside Terraform state. Delete them before destroying EKS and the VPC:

```bash
kubectl get svc --all-namespaces \
  --field-selector spec.type=LoadBalancer

kubectl -n monitoring \
  delete svc observability-grafana \
  --ignore-not-found
```

Wait until the corresponding AWS load balancer and requester-managed network interfaces have been removed before running Terraform destroy. Otherwise, AWS may reject subnet or Internet Gateway deletion with `DependencyViolation`.

Do not manually delete requester-managed ELB network interfaces. Delete the owning Kubernetes Service or AWS load balancer and allow AWS to remove its interfaces.

> The destroy workflow currently offers `qa` and `stage`, but matching Terraform environment directories are not currently included. Use `dev` or `prod` unless the missing environment configurations are added.

---

## Cost awareness

CODAP can create billable AWS resources, including:

- EKS control plane
- EC2 worker nodes
- NAT Gateway
- Elastic Load Balancer
- EBS volumes
- ECR image storage
- CloudWatch logs
- S3 Terraform state storage
- KMS key

Destroy temporary environments after testing and verify that Kubernetes-created load balancers, retained EBS volumes, snapshots, ECR images, CloudWatch log groups, and S3 data are handled according to your retention requirements.

---

## Portfolio explanation

> CODAP is a centralised observability and deployment analytics platform built on Amazon EKS. Terraform provisions separate development and production network and cluster configurations, including private managed nodes, KMS encryption, EKS access management, the EBS CSI add-on, and gp3 storage. An ordered GitHub Actions pipeline validates AWS OIDC access, tests both applications, plans and applies infrastructure, performs SonarQube, OWASP, and Trivy checks, pushes immutable images to ECR, deploys Prometheus, Grafana, the demo API, and a custom DORA metrics service, and finally publishes a live Grafana dashboard proof. The repository also retains optional ArgoCD App-of-Apps definitions and automated deployment diagnostics.

---

## Author

**VK Harish Bodapati**
