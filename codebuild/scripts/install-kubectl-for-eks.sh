#!/usr/bin/env bash
set -euo pipefail

: "${EKS_CLUSTER_NAME:?EKS_CLUSTER_NAME is required}"
: "${AWS_REGION:?AWS_REGION is required}"

cluster_minor="$(aws eks describe-cluster \
  --name "$EKS_CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query 'cluster.version' \
  --output text)"

kubectl_version="$(curl -fsSL "https://dl.k8s.io/release/stable-${cluster_minor}.txt")"
curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl"
curl -fsSLo /tmp/kubectl.sha256 "https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl.sha256"
echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum --check
install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
kubectl version --client
