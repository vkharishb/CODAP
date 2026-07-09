# CODAP Runbook

## ArgoCD app not syncing

```bash
kubectl -n argocd get applications
kubectl -n argocd describe application <app-name>
```

Common fixes:

- Replace `<your-github-username>` in GitOps YAML files.
- Confirm repository is public or ArgoCD has repo credentials.
- Confirm AppProject allows the repo and namespace.

## Grafana dashboard not visible

```bash
kubectl -n monitoring get configmap | grep codap
kubectl -n monitoring logs deploy/observability-grafana
```

Manual import fallback:

1. Open Grafana.
2. Dashboards → New → Import.
3. Upload `observability/dashboards/codap-deployment-analytics-dashboard.json`.

## Demo app not scraped

Check annotations:

```bash
kubectl -n demo get pod -l app.kubernetes.io/name=demo-api -o yaml | grep prometheus.io
```

Check app metrics:

```bash
kubectl -n demo port-forward svc/demo-api 8081:80
curl http://localhost:8081/metrics
```

## DORA service not exposing metrics

```bash
kubectl -n dora-metrics logs deploy/dora-metrics-service
kubectl -n dora-metrics port-forward svc/dora-metrics-service 8080:80
curl http://localhost:8080/metrics
```

## Rollback demo app

Because ArgoCD is GitOps-driven, rollback by reverting the Git commit that changed `gitops/manifests/demo/02-demo-api.yaml`.

```bash
git revert <commit-sha>
git push
```
