# Tasks: Postgres Migration

## 1. Backend: Driver & Connection

- [x] 1.1 Add `gorm.io/driver/postgres` to go.mod, remove `gorm.io/driver/mysql`
- [x] 1.2 Rewrite `utils/database.go`: rename `MySQLConnect()` to `Connect()`, read single `DATABASE_URL`, fail fast when undefined, open via `postgres.Open(...)`, keep ping check
- [x] 1.3 Update `main.go` call site for renamed connect function
- [x] 1.4 Remove or replace `SET FOREIGN_KEY_CHECKS` in `utils/database.go` `RunMigrations()` (delete if legacy-schema workaround is dead, else use GORM migrator constraint drop/re-add)
- [x] 1.5 Remove or replace `SET FOREIGN_KEY_CHECKS` in `internal/cleanup/cleanup.go` (×2), same rule as 1.4

## 2. Backend: Models & Validation

- [x] 2.1 Change `ItemTypeField.FieldType` tag to `gorm:"type:varchar(20);not null"` in `models/schemaModel.go`
- [x] 2.2 Add `FieldType.Valid()` method on `models/schemaModel.go` covering the six constants
- [x] 2.3 Enforce `FieldType.Valid()` with HTTP 400 in `SchemaCreate` (schemaController.go:334 area)
- [x] 2.4 Enforce `FieldType.Valid()` with HTTP 400 in `processSchemaUpdate` (schemaController.go:561 area)
- [x] 2.5 Change `type:json` → `type:jsonb` on `Item.FieldValues`, `ItemTypeSchema.UniqueFields`, `ItemTypeField.Validation`
- [x] 2.6 Update the `strings.Contains(err.Error(), "Duplicate")` error check in schemaController.go for Postgres error wording if needed

## 3. Backend: Tests

- [x] 3.1 Swap `utils/testdb.go` to the testcontainers postgres module (`postgres.Run`, `postgres://` connection string)
- [x] 3.2 Add tests for `FieldType.Valid()` and both 400 rejection paths (create + update)
- [x] 3.3 Run `go test ./...` — full suite green against Postgres containers

## 4. DevOps: Local & Compose

- [x] 4.1 Replace `mysql` service with `postgres:16` in `docker-compose.yaml` (POSTGRES_* bootstrap vars, volume rename)
- [x] 4.2 Update `apps/api/.env` example and any env templates to `DATABASE_URL`
- [x] 4.3 Verify seeding works on Postgres: `RUN_SEEDING=true` against fresh compose stack

## 5. Docs

- [x] 5.1 Write data-migration runbook (pgloader data-only + reset sequences + verification queries) in `docs/guides/` 
- [x] 5.2 Write new `docs/api/deployment.md`: Cloud Run + Neon + `DATABASE_URL` (previous compose-based guide deleted)
- [x] 5.3 Update `docs/getting-started/local-development.md` (compose Postgres, new env var)
- [x] 5.4 Update `apps/api/AGENTS.md` Local Contracts (Gin + GORM + Postgres, DATABASE_URL)
- [x] 5.5 Update `openspec/config.yaml` project context (MySQL/Cloud SQL → Postgres/Neon) after cutover

## 6. Data Migration & Cutover **[manual]**

- [x] 6.1 Create Neon project + scratch database **[manual]**
- [x] 6.2 Deploy new API image pointed at scratch Neon DB; confirm AutoMigrate schema **[manual]**
- [x] 6.3 Rehearse: pgloader `--data-only --reset-sequences` from Cloud SQL export into scratch DB **[manual]**
- [x] 6.4 Verify rehearsal: per-table row counts, JSON/enum spot-checks, insert one item + one rating **[manual]**
- [x] 6.5 Cutover: final pgloader run into production Neon DB, verify **[manual]**
- [x] 6.6 Update Cloud Run `DATABASE_URL` to production Neon, confirm API health **[manual]**
- [x] 6.7 Stop Cloud SQL instance; start one-week safety window **[manual]**
- [x] 6.8 Delete Cloud SQL instance after safety window **[manual]**

## 7. Release

- [x] 7.1 Commit with `BREAKING CHANGE:` footer documenting the `MYSQL_*` → `DATABASE_URL` rename → major version bump
