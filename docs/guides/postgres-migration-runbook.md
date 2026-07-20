# Postgres Migration Runbook

One-off procedure to migrate production data from Cloud SQL (MySQL 8) to Neon (Postgres 16).

## Prerequisites

- [pgloader](https://pgloader.readthedocs.io/) installed (`brew install pgloader` / `apt install pgloader`)
- Cloud SQL instance accessible (direct connection or Cloud SQL Proxy)
- Neon project created with a scratch database (see [deployment guide](../api/deployment.md))
- New API image deployed against the scratch Neon DB (AutoMigrate must run first)
- Cloud SQL credentials (read-only is sufficient)

## Step 1: Export Schema

Do NOT export DDL. The Postgres schema is created by GORM `AutoMigrate` on first boot.

## Step 2: pgloader Data-Only Load

Create a pgloader command file `migration.load`:

```lisp
LOAD DATABASE
  FROM mysql://MYSQL_USER:MYSQL_PASSWORD@MYSQL_HOST:MYSQL_PORT/MYSQL_DB
  INTO postgresql://NEON_USER:NEON_PASSWORD@NEON_HOST:5432/NEON_DB?sslmode=require

WITH data only,
     reset sequences,
     disable triggers,
     create no tables,
     drop indexes

CAST
  type tinyint to boolean drop typemod,
  type datetime to timestamptz drop not null using zero-dates-to-null;

ALTER SCHEMA 'rest_api' RENAME TO 'public';
```

Run:

```bash
pgloader migration.load
```

## Step 3: Reset Sequences

pgloader's `reset sequences` handles this. Verify:

```sql
SELECT setval('items_id_seq', (SELECT COALESCE(MAX(id), 0) FROM items));
SELECT setval('ratings_id_seq', (SELECT COALESCE(MAX(id), 0) FROM ratings));
SELECT setval('users_id_seq', (SELECT COALESCE(MAX(id), 0) FROM users));
SELECT setval('item_type_schemas_id_seq', (SELECT COALESCE(MAX(id), 0) FROM item_type_schemas));
SELECT setval('item_type_fields_id_seq', (SELECT COALESCE(MAX(id), 0) FROM item_type_fields));
SELECT setval('schema_versions_id_seq', (SELECT COALESCE(MAX(id), 0) FROM schema_versions));
SELECT setval('item_field_values_id_seq', (SELECT COALESCE(MAX(id), 0) FROM item_field_values));
```

## Step 4: Verification

### Row counts

```sql
-- Compare against MySQL SHOW TABLE STATUS output
SELECT 'items' AS tbl, count(*) FROM items
UNION ALL SELECT 'ratings', count(*) FROM ratings
UNION ALL SELECT 'users', count(*) FROM users
UNION ALL SELECT 'item_type_schemas', count(*) FROM item_type_schemas
UNION ALL SELECT 'item_type_fields', count(*) FROM item_type_fields
UNION ALL SELECT 'schema_versions', count(*) FROM schema_versions
UNION ALL SELECT 'item_field_values', count(*) FROM item_field_values;
```

### JSON spot-checks

```sql
SELECT id, name, field_values FROM items LIMIT 5;
SELECT id, fields FROM schema_versions LIMIT 5;
SELECT id, unique_fields FROM item_type_schemas LIMIT 5;
```

### Enum column spot-check

```sql
SELECT DISTINCT field_type FROM item_type_fields;
-- Must return only: text, textarea, number, select, checkbox, enum
```

### Insert test

```sql
-- Must succeed without PK collision
INSERT INTO items (name, schema_id, user_id, field_values, created_at, updated_at)
VALUES ('MIGRATION_TEST', 1, 1, '{}', NOW(), NOW());
INSERT INTO ratings (user_id, item_id, score, created_at, updated_at)
VALUES (1, 1, 5, NOW(), NOW());

-- Clean up test data
DELETE FROM ratings WHERE item_id = (SELECT id FROM items WHERE name = 'MIGRATION_TEST');
DELETE FROM items WHERE name = 'MIGRATION_TEST';
```

## Step 5: Cutover

1. Verify all Step 4 checks pass
2. If this was a rehearsal: repeat Steps 2-4 against the production Neon DB
3. Update Cloud Run `DATABASE_URL` environment variable to production Neon connection string
4. Confirm API health: `curl https://api.example.com/health`
5. Keep Cloud SQL instance stopped (not deleted) for one week

## Rollback

If any verification fails before Cloud SQL deletion:
1. Revert Cloud Run `DATABASE_URL` to MySQL-equivalent config
2. API immediately back on MySQL (source data untouched by pgloader's read-only connection)
