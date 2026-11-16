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
- Auth: Google OAuth 2.0 → JWT (access + refresh tokens)
- Storage: MinIO/S3 for images
- Schema system: Dynamic item schemas with validation engine, schema registry, hybrid JSON+EAV storage (JSON column for fast reads, EAV rows for filtering, written in the same transaction; in-memory registry cache is fine — writes are infrequent and it's a single Cloud Run instance — and invalidated on schema writes; planned future direction: drop EAV for jsonb + GIN indexes)
- Dynamic item endpoints: `/api/items/:type` adapts to any active schema
- Legacy item endpoints: `/api/cheese`, `/api/wine`, `/api/gin`, `/api/coffee`, `/api/chili-sauce` coexist with dynamic items
- DB migrations run automatically on startup; self-healing migration mode via `RUN_SELF_HEALING_MIGRATION=true`
- Environment: `.env` file in `apps/api/`, single `DATABASE_URL` for database connection
- Tests: Go native testing (`go test`), files named `*_test.go`
- Code style: `gofmt`, Effective Go conventions
- CHANGELOG in `apps/api/CHANGELOG.md`

## Work Guidance

- Route registration: `main.go` groups routes by domain (auth, public, protected, admin)
- Controllers handle HTTP; models define GORM entities; utils provide DB, JWT, auth middleware
- New legacy item types patterned after existing: controller + model + routes in main.go (being superseded by dynamic schema system)
- Dynamic item operations route through `DynamicItemController`; schema validation via `ValidationEngine` + `SchemaRegistry`
- Schema `field_type` is `varchar(20)` + a `Valid()` check (unknown type → 400): GORM's Postgres driver doesn't understand MySQL's `enum(...)` tag syntax, and controllers blindly cast request input — dropping the check without another guard would let invalid field types in silently. Do not remove it.
- Middleware chain: `RequirePartialAuth()` for profile completion, `RequireAuth()` for protected routes, `RequireAdmin()` for admin endpoints
- Seed data via `RUN_SEEDING=true` env + source file path vars
- Scripts in `scripts/`: `reset_database.go`, `seed.go`, `migrate_to_dynamic.go`, `migration_verify.go`

## Verification

- `go test ./...` — runs all tests
- Controller tests spin up a real Postgres via testcontainers — Docker must be running
- `SchemaRegistry` uses `sync.Once` for its in-memory cache; tests call `Reset()` to re-initialize between cases

## Child DOX Index

No children. Flat structure under `apps/api/`.