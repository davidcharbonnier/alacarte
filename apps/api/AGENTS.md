# apps/api — Go REST API

## Purpose

Go backend for the À la carte rating platform. Serves all API endpoints for client apps and the admin panel. Manages authentication, items, ratings, schemas, and user administration.

## Ownership

- Code: `apps/api/`
- Docs: `docs/api/`
- Release tag: `api-v*`
- Docker image: `ghcr.io/{repo}-api`
- Module: `github.com/davidcharbonnier/alacarte-api`

## Local Contracts

- Framework: Gin (HTTP), GORM (ORM), Postgres 16+
- Auth: Google OAuth 2.0 → JWT (single access token, no refresh tokens)
- Storage: MinIO/S3 for images
- Schema system: Dynamic item schemas with validation engine, schema registry, hybrid JSON+EAV storage (JSON column for fast reads, EAV rows for filtering, written in the same transaction; in-memory registry cache is fine — writes are infrequent and it's a single Cloud Run instance (`max-instances: 1`, see `docs/api/deployment.md`; raising it needs a shared cache) — and invalidated on schema writes; planned future direction: drop EAV for jsonb + GIN indexes)
- Dynamic item endpoints: `/api/items/:type` adapts to any active schema
- DB migrations (GORM AutoMigrate) run automatically on startup; `RUN_CLEANUP_MIGRATION=true` runs the one-off post-migration cleanup job instead of the server
- Environment: `.env` file in `apps/api/`, single `DATABASE_URL` for database connection
- Tests: Go native testing (`go test`), files named `*_test.go`
- Code style: `gofmt`, Effective Go conventions
- CHANGELOG in `apps/api/CHANGELOG.md`

## Work Guidance

- Route registration: `main.go` groups routes by domain (auth, public, protected, admin)
- Controllers handle HTTP; models define GORM entities; utils provide DB, JWT, auth middleware
- Dynamic item operations route through `DynamicItemController`; schema validation via `ValidationEngine` + `SchemaRegistry`
- Schema `field_type` is `varchar(20)` + a `Valid()` check (unknown type → 400): GORM's Postgres driver doesn't understand MySQL's `enum(...)` tag syntax, and controllers blindly cast request input — dropping the check without another guard would let invalid field types in silently. Do not remove it.
- Middleware chain: `RequirePartialAuth()` for profile completion, `RequireAuth()` for protected routes, `RequireAdmin()` for admin endpoints
- `RUN_SEEDING=true` seeds the default schemas on startup; item data comes from `POST /admin/items/:type/seed` (`url` or `data`)
- Scripts in `scripts/`: `reset_database.go`, `seed.go`, `migrate_to_dynamic.go`, `migration_verify.go` (the first three currently do not compile: they call the missing `utils.MySQLConnect`; use `RUN_SEEDING=true` instead)

## Verification

- `go test ./...` — runs all tests
- Controller tests spin up a real Postgres via testcontainers — Docker must be running
- `SchemaRegistry` uses `sync.Once` for its in-memory cache; tests call `Reset()` to re-initialize between cases

## Child DOX Index

No children. Flat structure under `apps/api/`.