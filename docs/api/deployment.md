# Deployment

The API runs on Google Cloud Run backed by a serverless Postgres database (Neon).

## Infrastructure

| Component | Service | Notes |
|-----------|---------|-------|
| Compute | Cloud Run | Scale-to-zero, `min-instances: 0`. Keep `max-instances: 1`: the schema registry cache is in-memory and only the instance that handled a schema write is invalidated |
| Database | Neon | Serverless Postgres 16, free tier; ~1s cold-start on first request after idle (always-on is a paid toggle) |
| Storage | MinIO / S3-compatible | Image uploads |
| Registry | GitHub Container Registry (ghcr.io) | Docker images |

## Environment Variables

### Required

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Postgres connection string (from Neon dashboard) |
| `JWT_SECRET_KEY` | HMAC-SHA256 signing key (≥64 chars) |
| `GOOGLE_CLIENT_ID` | Google OAuth 2.0 client ID |
| `INITIAL_ADMIN_EMAIL` | Email of the initial admin user |

### Image Storage (required: the API exits at startup if the bucket is not configured and reachable)

| Variable | Description |
|----------|-------------|
| `STORAGE_BUCKET_NAME` | S3/MinIO bucket name |
| `STORAGE_ENDPOINT` | S3 endpoint as `host[:port]`, no scheme (e.g. `minio:9000`) |
| `STORAGE_REGION` | S3 region |
| `STORAGE_ACCESS_KEY` / `STORAGE_SECRET_KEY` | S3 credentials (optional on Cloud Run with an IAM role; the client falls back to it) |

### Optional

| Variable | Description |
|----------|-------------|
| `GIN_MODE` | `release` (default) or `debug` |
| `TRUSTED_PROXIES` | Comma-separated proxy CIDRs |
| `ALLOWED_ORIGINS` | Comma-separated CORS origins. Must include the admin SPA's static-host origin and any Flutter web origin. If unset, defaults to `http://localhost:3000,http://localhost:8080`; if set, the default no longer applies |
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
2. Deploy to Cloud Run (Console or `gcloud run deploy`). Cloud Run does not pull from ghcr.io directly (verify against current Google docs): use an Artifact Registry remote repository for ghcr.io, or copy the image into Artifact Registry first
3. Set `DATABASE_URL` to your Neon database connection string
4. On startup, GORM `AutoMigrate` creates the full Postgres schema (runs before the server starts accepting requests)
5. Verify: `curl https://api.example.com/health`

## Local Development

See [Local Development Setup](../getting-started/local-development.md).
