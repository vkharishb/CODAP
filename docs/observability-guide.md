# Observability Guide

## Metrics sources

| Source | Metrics |
|---|---|
| Kubernetes nodes | CPU, memory, filesystem, network |
| kube-state-metrics | Deployment, Pod, ReplicaSet, HPA state |
| demo-api | Request rate and Node.js runtime metrics |
| dora-metrics-service | Deployment frequency, lead time, failure rate, MTTR |

## Grafana dashboard

Dashboard path:

```text
observability/dashboards/codap-deployment-analytics-dashboard.json
```

Dashboard UID:

```text
codap-deployment-analytics
```

## Verify Prometheus scraping

```bash
kubectl -n monitoring port-forward svc/observability-kube-prometheus-prometheus 9090:9090
```

Open Prometheus and run:

```promql
up
codap_deployments_total
codap_demo_http_requests_total
kube_pod_container_status_restarts_total{namespace="demo"}
```

## Demo traffic

```bash
kubectl -n demo port-forward svc/demo-api 8081:80
for i in {1..20}; do curl -s http://localhost:8081/health; done
```
