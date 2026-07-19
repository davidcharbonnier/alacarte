## Why

Cloud SQL (MySQL) is the dominant infrastructure cost of the platform. The API already runs on scale-to-zero Cloud Run, so moving the database to a serverless Postgres free tier (Neon) brings total infra cost to ~$0 while keeping the current hosting model. Postgres is also a better long-term fit for the dynamic schema system's JSON-heavy storage (native `jsonb`, GIN indexing).

## What Changes

- **BREAKING**: Replace MySQL 8 with Postgres 16+ as the only supported database. No dual-driver support — the project controls all deployments.
- **BREAKING**: Replace the five `MYSQL_*` environment variables with a single `DATABASE_URL` connection string (as provided by Neon/Supabase). Commit carries a `BREAKING CHANGE:` footer → major version bump.
- Swap GORM driver `gorm.io/driver/mysql` → `gorm.io/driver/postgres`; connection code reads `DATABASE_URL`.
- Change `ItemTypeField.FieldType` GORM tag from MySQL-native `type:enum(...)` to `varchar(20)`; add `FieldType.Valid()` and enforce it in the schema create/update paths (previously enforced by the DB enum).
- Change `type:json` column tags to `type:jsonb` (`Item.FieldValues`, `ItemTypeSchema.UniqueFields`, `ItemTypeField.Validation`).
- Replace MySQL-only `SET FOREIGN_KEY_CHECKS = 0/1` statements in migration/cleanup code with the Postgres equivalent (or remove where the legacy-schema workaround is no longer needed).
- Swap the testcontainer in `utils/testdb.go` from the MySQL module to the Postgres module.
- Update `docker-compose.yaml` / `docker-compose.prod.yml`: replace the `mysql` service with `postgres`, drop `mysql/my.cnf`.
- One-off data migration: rehearse then execute a pgloader `--data-only` load from the Cloud SQL MySQL export into the GORM-created Postgres schema, with row-count verification. Documented as a runbook, no repo code.
- Update docs (`docs/api/deployment.md`, `docs/getting-started/local-development.md`, `docs/guides/migration-process.md`) for the new database and cutover process.

## Capabilities

### New Capabilities
- `postgres-database`: Postgres as the API's sole database — connection via `DATABASE_URL`, GORM postgres driver, portable column types (no MySQL-only enum/JSON handling), Postgres testcontainers for tests, and the one-off pgloader data-migration runbook with verification.

### Modified Capabilities
- None. No spec-level behavior changes in existing capabilities; item/rating/schema behavior is unchanged.

## Impact

- **Code**: `apps/api/utils/database.go`, `utils/testdb.go`, `models/schemaModel.go`, `models/itemModel.go`, `controllers/schemaController.go`, `internal/cleanup/cleanup.go`, `go.mod` (driver swap).
- **Infra**: Cloud SQL MySQL instance decommissioned after cutover; new Neon (serverless Postgres) project; Cloud Run env config updated to `DATABASE_URL`.
- **Config**: `MYSQL_HOST/PORT/USERNAME/PASSWORD/DATABASE` removed; `DATABASE_URL` added. Deployment config change is breaking for operators.
- **Local dev**: docker-compose runs Postgres instead of MySQL; existing MySQL volumes are discarded.
- **Tests**: integration tests now spin Postgres containers; no workflow changes needed (testcontainers self-contained).
- **Cost**: eliminates the always-on Cloud SQL instance, the largest infra expense.
- **Out of scope**: dropping the EAV `item_field_values` table in favor of jsonb+GIN queries — captured as a future change after this migration is stable.
