## Context

The API (`apps/api`, Go + Gin + GORM) runs on Cloud Run (scale-to-zero) backed by an always-on Cloud SQL MySQL 8 instance — the largest infrastructure cost. Deployment is manual via Google Cloud Console. The MySQL-specific surface area is small and well-contained:

- `utils/database.go` — `MySQLConnect()`, `MYSQL_*` env vars, MySQL DSN, `SET FOREIGN_KEY_CHECKS` in `RunMigrations`
- `utils/testdb.go` — testcontainers MySQL module
- `internal/cleanup/cleanup.go` — `SET FOREIGN_KEY_CHECKS` (×2, legacy-schema workarounds)
- `models/schemaModel.go` — `type:enum(...)` tag on `FieldType`
- Infra: `docker-compose.yaml`, docs

All data access otherwise goes through GORM; there are no raw queries against business data, no stored procedures, triggers, or views. Live production data exists and must be preserved (one-off manual migration is acceptable).

## Goals / Non-Goals

**Goals:**
- Postgres 16+ (Neon serverless free tier) as the only supported database
- Single `DATABASE_URL` connection configuration
- Schema fully derived from GORM models via existing `AutoMigrate` on startup
- Lossless one-off migration of production data from MySQL
- Integration tests run against Postgres testcontainers
- Honest versioning: breaking config change → major version bump

**Non-Goals:**
- Dual MySQL+Postgres support (project controls all deployments; dual support doubles validation cost forever for unused optionality)
- Dropping the EAV `item_field_values` table in favor of jsonb+GIN queries (follow-up change)
- Changing the hosting model (Cloud Run stays; admin SPA hosting unchanged)
- Rewriting the in-progress `refactor-ci-cd-pipeline` change (being redone separately; zero code overlap with this change)

## Decisions

### D1: Full migration over dual-driver support

Swap the GORM driver outright instead of abstracting dialect selection behind `DB_DRIVER`.

- **Why**: every deployment is operator-controlled; no external MySQL users exist. Dual support would permanently double schema-change validation, CI test time, and docs for optionality nobody uses.
- **Alternative considered**: env-selected dialect (`mysql|postgres`) — rejected as speculative abstraction (YAGNI).

### D2: `DATABASE_URL` over five discrete env vars

Replace `MYSQL_HOST/PORT/USERNAME/PASSWORD/DATABASE` with one `DATABASE_URL` string passed directly to `postgres.Open(...)`.

- **Why**: Neon/Supabase provide exactly this string; one Cloud Run secret instead of five; GORM's postgres driver accepts it as-is. Docker-compose services keep their own internal `POSTGRES_*` vars for container bootstrap only.
- **Alternative considered**: `POSTGRES_*` var parity — more config surface for zero gain.

### D3: Replace the enum column with `varchar(20)` + application validation

`ItemTypeField.FieldType` tag changes from `type:enum('text','textarea','number','select','checkbox','enum')` to `type:varchar(20)`. New `FieldType.Valid()` method checks the six constants; called in `SchemaCreate` and `processSchemaUpdate`, returning 400 on unknown values.

- **Why**: GORM's postgres driver does not understand the MySQL `enum(...)` tag syntax. Today the DB enum is the only guard — the controllers blindly cast request input (`models.FieldType(getStringField(...))`), so dropping the enum without adding the check would let invalid field types in silently (the validation engine's `switch` would skip them).
- **Alternative considered**: native Postgres enum types — more migration machinery (named type creation) for a value set that never changes; CHECK constraint — same guarantee but splits the source of truth between Go constants and DDL.

### D4: `type:json` tags become `type:jsonb`

Applies to `Item.FieldValues`, `ItemTypeSchema.UniqueFields`, `ItemTypeField.Validation`.

- **Why**: jsonb is Postgres's native binary JSON: same storage semantics for current code, but indexable/queryable later (enables the future EAV-removal change). One-word tag change; pgloader casts MySQL JSON → jsonb automatically.
- **Alternative considered**: keep `json` — strictly worse on Postgres.

### D5: Schema from GORM, data from pgloader — never dump DDL

The new Postgres schema is created exclusively by the app's existing `AutoMigrate` on first boot. Production data is loaded with **pgloader** (`--with "data only"`, `--with "reset sequences"`) from the Cloud SQL MySQL source (export file or live connection).

- **Why**: GORM models stay the single source of truth for schema (no translated DDL drift). pgloader handles MySQL→Postgres type conversion (enum→text, json→jsonb, tinyint→boolean) that hand-editing a mysqldump would fumble. Data volume is small; downtime is minutes.
- **Alternative considered**: mysqldump + manual SQL edit — MySQL dump syntax (backticks, `ENGINE=`, `AUTO_INCREMENT`) does not execute on Postgres; error-prone.
- **Sequence caveat**: sequences must be reset post-load or new inserts collide with migrated IDs; verified by inserting one row during verification.

### D6: Rehearse the migration on a throwaway database

Run the full pgloader flow into a scratch Neon database (free) and verify before the real cutover.

- **Why**: the migration is one command — rehearsing until boring costs nothing and converts cutover into a re-run of a proven step.

### D7: Replace `SET FOREIGN_KEY_CHECKS` with Postgres equivalents

`RunMigrations` and `internal/cleanup` disable FK checks using MySQL-only syntax. On Postgres the equivalent is dropping/re-adding the constraint via the GORM migrator, or `SET session_replication_role = replica` where a session-wide toggle is truly needed. Where the workaround exists only for legacy schemas already migrated in production, remove it instead.

- **Why**: these statements are legacy-schema workarounds (already marked TODO-removable); the smallest correct change is deletion where dead, dialect-correct replacement where still needed.

## Risks / Trade-offs

- [pgloader type-conversion edge case (enum values, JSON, tinyint→bool) corrupts or drops rows silently] → D6 rehearsal + per-table row-count verification + spot-checks of JSON/enum columns before cutover; keep Cloud SQL instance until verification passes.
- [Postgres sequences left at 1 after data load → insert PK collisions in production] → pgloader `reset sequences` option + verification step inserts one item and one rating.
- [Cold-start stacking: Cloud Run scale-to-zero + Neon scale-to-zero adds ~1s first-request latency] → acceptable for current traffic; Neon always-on is a paid toggle if it ever matters.
- [Breaking env-var rename strands a deployment on old config] → `BREAKING CHANGE:` footer, major version bump, docs updated; deployment is manual so the operator updates Cloud Run env at cutover by definition.
- [Local/dev databases (docker-compose MySQL volumes) are discarded] → documented; dev data is re-seedable via `RUN_SEEDING=true`.

## Migration Plan

1. **Code changes land first** (driver, tags, `Valid()`, testdb, compose, docs) and deploy against a fresh empty Neon database → `AutoMigrate` creates the Postgres schema.
2. **Rehearse**: pgloader data-only from Cloud SQL into a scratch Neon DB; verify row counts + spot-checks + one insert.
3. **Cutover**: final pgloader run into the production Neon DB; verify; update Cloud Run `DATABASE_URL` to production Neon; confirm API health.
4. **Decommission**: keep Cloud SQL stopped-but-present for a short safety window (e.g., one week), then delete.
5. **Rollback**: if verification fails at any point before Cloud SQL deletion, point `DATABASE_URL`-equivalent config back to MySQL — the MySQL data is untouched by the read-only pgloader source connection.

## Open Questions

- None blocking. (Neon vs Supabase: Neon chosen for no-pause free tier and zero bundled extras; revisitable if realtime/auth extras are ever wanted.)
