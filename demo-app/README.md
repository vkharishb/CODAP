# CODAP Demo API

This application is deployed to EKS and linked to CODAP through Prometheus metrics, Kubernetes labels, and GitHub Actions deployment metadata.

## Local run

```bash
npm install
npm start
curl http://localhost:8080/health
curl http://localhost:8080/metrics
```

## Docker

```bash
docker build -t codap-demo-api:local .
docker run -p 8080:8080 codap-demo-api:local
```
