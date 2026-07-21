# postgres-database Specification

## Purpose

Postgres 16+ as the API's sole database, using the GORM postgres driver with a single `DATABASE_URL` connection string. Replaces MySQL 8 / Cloud SQL entirely.

## Requirements

### Requirement: Postgres as sole database
The API SHALL support Postgres 16+ as its only database, using the GORM postgres driver. MySQL SHALL NOT be supported.

#### Scenario: Application connects to Postgres
- **WHEN** the API starts with a valid `DATABASE_URL` pointing to a Postgres instance
- **THEN** the API SHALL establish a connection and verify it with a ping

#### Scenario: Application rejects missing configuration
- **WHEN** the API starts without `DATABASE_URL` defined
- **THEN** the API SHALL exit with a fatal error naming the missing variable

### Requirement: Single connection string configuration
Database configuration SHALL be provided through one `DATABASE_URL` environment variable in Postgres connection-string form (including SSL parameters when required by the provider). The legacy `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USERNAME`, `MYSQL_PASSWORD`, and `MYSQL_DATABASE` variables SHALL be removed.

#### Scenario: SSL-required provider
- **WHEN** `DATABASE_URL` contains `sslmode=require` (as provided by serverless Postgres providers)
- **THEN** the API SHALL connect using TLS without additional configuration

### Requirement: Portable column types
GORM models SHALL use only column types portable to Postgres. MySQL-native constructs SHALL NOT appear in model tags.

#### Scenario: Field type stored as varchar
- **WHEN** migrations create the `item_type_fields` table
- **THEN** the `field_type` column SHALL be `varchar(20)`, not a native enum

#### Scenario: JSON columns stored as jsonb
- **WHEN** migrations create tables with JSON columns (`items.field_values`, `item_type_schemas.unique_fields`, `item_type_fields.validation`)
- **THEN** those columns SHALL use the `jsonb` type

### Requirement: Field type validation in application code
Since the database no longer enforces field-type values, the API SHALL validate `field_type` on schema create and update operations against the defined set (`text`, `textarea`, `number`, `select`, `checkbox`, `enum`).

#### Scenario: Reject invalid field type on create
- **WHEN** a schema creation request contains a field with an unknown `field_type` (e.g. `"banana"`)
- **THEN** the API SHALL respond with HTTP 400 and SHALL NOT persist the schema or field

#### Scenario: Reject invalid field type on update
- **WHEN** a schema update request contains a field with an unknown `field_type`
- **THEN** the API SHALL respond with HTTP 400 and SHALL NOT persist the change

#### Scenario: Accept valid field type
- **WHEN** a request contains a field with one of the six defined `field_type` values
- **THEN** the API SHALL process the request normally

### Requirement: Dialect-portable migrations
Startup migrations and maintenance scripts SHALL NOT execute MySQL-only SQL statements (e.g. `SET FOREIGN_KEY_CHECKS`).

#### Scenario: Migrations run on Postgres
- **WHEN** the API starts against an empty Postgres database
- **THEN** `AutoMigrate` SHALL create the full schema without executing dialect-specific statements

### Requirement: Postgres integration tests
Integration tests SHALL run against ephemeral Postgres containers via testcontainers.

#### Scenario: Test database lifecycle
- **WHEN** a test calls `SetupTestDB()`
- **THEN** a Postgres container SHALL start, migrations SHALL run, and cleanup SHALL terminate the container

### Requirement: One-off production data migration
Production data SHALL be migrated from the MySQL source to Postgres using pgloader in data-only mode against the GORM-created schema, with sequence reset. The migration procedure SHALL be documented as a runbook in `docs/` and SHALL NOT add one-off migration code to the repository.

#### Scenario: Rehearsed migration
- **WHEN** the migration procedure is executed against a scratch Postgres database before cutover
- **THEN** per-table row counts SHALL match the MySQL source and spot-checks of JSON and former-enum columns SHALL pass

#### Scenario: Sequence integrity after load
- **WHEN** the data load completes
- **THEN** inserting a new item and a new rating SHALL succeed without primary-key collisions

#### Scenario: Source preservation
- **WHEN** the migration executes
- **THEN** the MySQL source SHALL remain unmodified, allowing rollback until the source is decommissioned
