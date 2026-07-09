const express = require('express');
const client = require('prom-client');

const app = express();
const port = process.env.PORT || 8080;
const version = process.env.APP_VERSION || 'local';
const environment = process.env.APP_ENV || 'dev';

client.collectDefaultMetrics({ prefix: 'codap_demo_' });

const httpRequests = new client.Counter({
  name: 'codap_demo_http_requests_total',
  help: 'Total HTTP requests handled by demo-api',
  labelNames: ['method', 'route', 'status_code', 'environment', 'version']
});

app.use((req, res, next) => {
  res.on('finish', () => {
    httpRequests.inc({
      method: req.method,
      route: req.route ? req.route.path : req.path,
      status_code: String(res.statusCode),
      environment,
      version
    });
  });
  next();
});

app.get('/', (req, res) => {
  res.json({
    message: 'CODAP demo API is running on EKS',
    application: 'demo-api',
    environment,
    version,
    dashboard: 'codap-deployment-analytics'
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', application: 'demo-api', environment, version });
});

app.get('/ready', (req, res) => {
  res.json({ ready: true });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

app.listen(port, () => {
  console.log(`CODAP demo-api listening on port ${port}`);
});
