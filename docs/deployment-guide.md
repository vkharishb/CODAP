# CODAP Deployment Guide

## Step 1: Prepare AWS backend

Create S3 bucket and DynamoDB table before `terraform init`.

```bash
aws s3api create-bucket \
  --bucket codap-tfstate-ap-south-1 \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws dynamodb create-table \
  --table-name codap-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

## Step 2: Provision infrastructure

```bash
cd terraform/envs/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
```

## Step 3: Configure kubectl

```bash
aws eks update-kubeconfig --region ap-south-1 --name codap-dev
kubectl get nodes
```

## Step 4: Install ArgoCD

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deployment/argocd-server
kubectl apply -f gitops/projects/codap-project.yaml
kubectl apply -f gitops/argocd/root-app.yaml
```

## Step 5: Verify applications

```bash
kubectl -n argocd get applications
kubectl -n monitoring get pods
kubectl -n demo get pods,svc,hpa
kubectl -n dora-metrics get pods,svc
```

## Step 6: Access dashboards

```bash
kubectl -n monitoring port-forward svc/observability-grafana 3000:80
```

Open `http://localhost:3000` and import the dashboard JSON if sidecar provisioning is not enabled.
