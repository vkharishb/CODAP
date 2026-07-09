CREATE TABLE IF NOT EXISTS deployment_events (
    id BIGSERIAL PRIMARY KEY,
    application TEXT NOT NULL,
    environment TEXT NOT NULL,
    version TEXT NOT NULL,
    commit_sha TEXT NOT NULL,
    pipeline_url TEXT,
    started_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('success', 'failed', 'rollback')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS incident_events (
    id BIGSERIAL PRIMARY KEY,
    application TEXT NOT NULL,
    environment TEXT NOT NULL,
    incident_id TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_deployment_events_app_env_time
ON deployment_events(application, environment, finished_at DESC);
