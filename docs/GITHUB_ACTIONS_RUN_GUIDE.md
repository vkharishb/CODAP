# CODAP GitHub Actions Run Guide

This project is configured to run CODAP using GitHub Actions for CI, CD, Terraform plan, and Terraform apply.

## Required GitHub Secrets

Add these under:

`GitHub Repo -> Settings -> Secrets and variables -> Actions -> Repository secrets`

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
AWS_ROLE_TO_ASSUME
EKS_CLUSTER_NAME
```

The workflows in this package use the OIDC role secret first:

```yaml
role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
```

Your access key and secret key can remain as fallback credentials, but the recommended method is OIDC role assumption.

Recommended values:

```text
AWS_REGION=ap-south-1
EKS_CLUSTER_NAME=codap-dev
AWS_ROLE_TO_ASSUME=arn:aws:iam::<ACCOUNT_ID>:role/<YOUR_GITHUB_ACTIONS_ROLE_NAME>
```

## Workflow Files

```text
.github/workflows/aws-role-test.yml
.github/workflows/ci.yml
.github/workflows/cd.yml
.github/workflows/terraform-plan.yml
.github/workflows/terraform-apply.yml
.github/workflows/deploy-eks.yml
```

## 1. Run AWS Role Test

Use this first.

Path:

```text
GitHub -> Actions -> AWS Role Test -> Run workflow
```

Expected result:

```text
arn:aws:sts::<ACCOUNT_ID>:assumed-role/<ROLE_NAME>/codap-aws-role-test
```

If this fails, do not run Terraform yet. Fix the IAM role trust policy and GitHub secrets first.

## 2. Run CODAP CI

Path:

```text
GitHub -> Actions -> CODAP CI -> Run workflow
```

This validates:

```text
Node.js demo app
Python DORA metrics service
Docker build for both apps
Terraform fmt/init/validate
Helm chart lint/template
Kubernetes manifest dry-run
```

This workflow does not create AWS resources.

## 3. Run Terraform Plan

Path:

```text
GitHub -> Actions -> Terraform Plan -> Run workflow
```

This workflow:

```text
Assumes the AWS role
Creates the S3 Terraform backend bucket if missing
Enables versioning, encryption and public access block
Runs terraform init
Runs terraform validate
Runs terraform plan
Uploads tfplan as an artifact
```

Backend bucket format:

```text
codap-tfstate-<AWS_REGION>-<ACCOUNT_ID>
```

Example:

```text
codap-tfstate-ap-south-1-123456789012
```

## 4. Run Terraform Apply

Path:

```text
GitHub -> Actions -> Terraform Apply -> Run workflow
```

Choose action:

```text
plan
apply
destroy
```

Recommended order:

```text
1. plan
2. apply
3. verify EKS
```

Only use `destroy` when you want to remove the EKS cluster and AWS resources.

## 5. Run CD Build and Push

Path:

```text
GitHub -> Actions -> CODAP CD - Build and Push Images -> Run workflow
```

This workflow:

```text
Builds demo-app Docker image
Builds dora-metrics-service Docker image
Creates ECR repositories if missing
Pushes images to ECR
Updates GitOps image references
Commits the updated image tags back to GitHub
```

ECR repositories created:

```text
codap-demo-api
codap-dora-metrics-service
```


## 6. Deploy CODAP to EKS

Path:

```text
GitHub -> Actions -> CODAP Deploy to EKS -> Run workflow
```

This workflow:

```text
Connects to EKS using aws eks update-kubeconfig
Verifies kubectl access
Installs or upgrades ArgoCD
Replaces the placeholder Git repo URL with the current GitHub repository URL
Applies the CODAP ArgoCD project
Applies the root app-of-apps
Prints workload proof commands
```

Run this after:

```text
Terraform Apply -> action = apply
CODAP CD - Build and Push Images
```

## Recommended Execution Order

Use this order for your first proof run:

```text
1. AWS Role Test
2. CODAP CI
3. Terraform Plan
4. Terraform Apply -> action = plan
5. Terraform Apply -> action = apply
6. CODAP CD - Build and Push Images
7. CODAP Deploy to EKS
```

## Important Notes

### Do not expose secrets

Never paste these values into README, screenshots, or GitHub issues:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ROLE_TO_ASSUME full account ID if you do not want to expose it
```

Mask sensitive details in screenshots.

### GitHub Environment Approval

For safer Terraform apply/destroy:

```text
GitHub Repo -> Settings -> Environments -> New environment -> dev
```

Enable required reviewers. The Terraform apply workflow uses:

```yaml
environment: dev
```

So GitHub can request approval before apply or destroy.

### Backend Locking

The backend uses S3 native locking:

```hcl
use_lockfile = true
```

DynamoDB locking was removed because the earlier `codap-tf-locks` table caused lock errors when it did not exist.


## Grafana dashboard endpoint proof

After `CODAP Deploy to EKS` succeeds, open the workflow run summary. The final step prints two clickable links:

```text
Grafana
CODAP Dashboard
```

Click `CODAP Dashboard` to open the dashboard in your browser. The same endpoint is uploaded as a GitHub Actions artifact named:

```text
codap-grafana-endpoint-proof
```

Use this for project proof screenshots:

```text
proofs/screenshots/11-grafana-dashboard-endpoint.png
```

Important: Grafana is exposed through a public AWS LoadBalancer for demo proof. After taking screenshots, restrict it or change it back to ClusterIP if you do not need public access.
