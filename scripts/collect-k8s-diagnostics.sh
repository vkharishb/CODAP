#!/usr/bin/env bash
set -uo pipefail

OUTPUT_DIR="${1:-artifacts/deployment-diagnostics}"
mkdir -p "$OUTPUT_DIR"

capture() {
  local name="$1"
  shift
  {
    echo "# Command: $*"
    echo "# UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    "$@"
  } >"$OUTPUT_DIR/$name.log" 2>&1 || true
}

capture cluster-nodes kubectl get nodes -o wide
capture cluster-storageclasses kubectl get storageclass -o wide
capture kube-system-pods kubectl -n kube-system get pods -o wide
capture ebs-csi-controller kubectl -n kube-system describe deployment ebs-csi-controller
capture monitoring-resources kubectl -n monitoring get all,pvc,configmap -o wide
capture monitoring-events kubectl -n monitoring get events --sort-by=.lastTimestamp
capture grafana-deployment kubectl -n monitoring describe deployment observability-grafana
capture grafana-pods kubectl -n monitoring get pods -l app.kubernetes.io/name=grafana -o wide
capture helm-status helm -n monitoring status observability
capture helm-values helm -n monitoring get values observability --all
capture helm-manifest helm -n monitoring get manifest observability

while IFS= read -r pod; do
  [ -n "$pod" ] || continue
  safe_name="${pod//\//-}"
  capture "${safe_name}-describe" kubectl -n monitoring describe "$pod"
  capture "${safe_name}-logs" kubectl -n monitoring logs "$pod" --all-containers=true --tail=500
  capture "${safe_name}-previous-logs" kubectl -n monitoring logs "$pod" --all-containers=true --previous --tail=500
done < <(kubectl -n monitoring get pods -l app.kubernetes.io/name=grafana -o name 2>/dev/null || true)

tar -czf "${OUTPUT_DIR}.tar.gz" -C "$(dirname "$OUTPUT_DIR")" "$(basename "$OUTPUT_DIR")" 2>/dev/null || true

echo "Diagnostics written to $OUTPUT_DIR"
