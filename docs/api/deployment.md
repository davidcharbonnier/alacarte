# Deployment

The API runs on Google Cloud Run backed by a serverless Postgres database (Neon).

## Infrastructure

| Component | Service | Notes |
|-----------|---------|-------|
| Compute | Cloud Run | Scale-to-zero, `min-instances: 0` |
| Database | Neon | Serverless Postgres 16, free tier |
| Storage | MinIO / S3-compatible | Image uploads |
| Registry | GitHub Container Registry (ghcr.io) | Docker images |

## Environment Variables

### Required

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Postgres connection string (from Neon dashboard) |
| `JWT_SECRET_KEY` | HMAC-SHA256 signing key (≥64 chars) |
| `GOOGLE_CLIENT_ID` | Google OAuth 2.0 client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth 2.0 client secret |
| `INITIAL_ADMIN_EMAIL` | Email of the initial admin user |

### Optional

| Variable | Description |
|----------|-------------|
| `GIN_MODE` | `release` (default) or `debug` |
| `TRUSTED_PROXIES` | Comma-separated proxy CIDRs |
| `ALLOWED_ORIGINS` | Comma-separated CORS origins |
| `RUN_SEEDING` | Set to `true` to seed default schemas on startup |
| `RUN_CLEANUP_MIGRATION` | Set to `true` for post-migration cleanup job mode |

## Database Connection

`DATABASE_URL` format:

```
postgres://user:password@host:5432/database?sslmode=require
```

Neon provides this string directly from the dashboard. For local development, use `sslmode=disable`.

## Deploy

### Prerequisites

- Docker image pushed to ghcr.io
- Cloud Run service configured
- Neon project and database created
- `DATABASE_URL` set as Cloud Run environment variable

### First Deploy

1. Push image: `docker push ghcr.io/org/alacarte-api:latest`
2. Deploy to Cloud Run (Console or `gcloud run deploy`)
3. Set `DATABASE_URL` to Neon scratch database connection string
4. On first request, GORM `AutoMigrate` creates the full Postgres schema
5. Verify: `curl https://api.example.com/health`

### Production Cutover

See [Postgres Migration Runbook](../guides/postgres-migration-runbook.md) for the data migration procedure.

## Local Development

See [Local Development Setup](../getting-started/local-development.md).
