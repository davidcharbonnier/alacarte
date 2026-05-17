# Migration Process for Existing Deployments

**Last Updated:** May 2026
**Applies To:** Deployments with existing hardcoded item types (cheese, gin, wine, coffee, chili-sauce)

This guide covers migrating existing À la carte deployments from hardcoded item types to the dynamic schema system.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Pre-Migration Checklist](#pre-migration-checklist)
- [Migration Steps](#migration-steps)
- [Rollback Procedure](#rollback-procedure)
- [Post-Migration Cleanup](#post-migration-cleanup)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

---

## Overview

### What Changes

The migration converts:
- **Old:** Separate tables per item type (`cheeses`, `gins`, `wines`, `coffees`, `chili_sauces`)
- **New:** Unified `items` table with dynamic schema references

**Data preserved:**
- ✅ All item records
- ✅ All ratings and sharing relationships
- ✅ All images and image URLs
- ✅ User accounts and profiles

**Data transformed:**
- Item fields moved to JSON `field_values` column + EAV rows
- Item types become schema records in `item_type_schemas`
- Schema versions created for each item type

### Downtime

**Expected downtime:** 5-15 minutes depending on data volume.

The migration script runs offline. The API should be stopped during migration.

---

## Pre-Migration Checklist

### 1. Backup Database

**Critical:** Create a full database backup before starting.

```bash
# Using mysqldump
mysqldump -u root -p alacarte > alacarte-pre-migration-$(date +%Y%m%d).sql

# Or using Docker
docker exec mysql-container mysqldump -u root -p alacarte > backup.sql
```

### 2. Verify Application Versions

Ensure all applications are on compatible versions:
- **API:** Must include dynamic schema controllers and services
- **Admin:** Must include schema management UI
- **Client:** Must support schema discovery

### 3. Check Disk Space

The migration creates new tables but keeps old tables. Ensure sufficient disk space:
- New tables: ~same size as old tables
- Old tables: retained until cleanup
- **Recommendation:** Ensure 2x current database size available

### 4. Notify Users

Schedule migration during low-traffic period. The platform will be unavailable during migration.

### 5. Prepare Rollback Plan

Document current deployment versions (Docker image tags, Git commits) for quick rollback if needed.

---

## Migration Steps

### Step 1: Stop Applications

Stop all running application instances to prevent data changes during migration:

```bash
# Docker Compose
docker-compose down

# Or stop individual services
docker stop alacarte-api
docker stop alacarte-admin
```

### Step 2: Run Database Backup

```bash
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > \
  alacarte-backup-$(date +%Y%m%d-%H%M%S).sql
```

### Step 3: Deploy New API Version

Deploy the API version that includes dynamic schema support. Do not start it yet.

```bash
# Pull latest image
docker pull ghcr.io/username/alacarte-api:latest

# Or build locally
cd apps/api
docker build -t alacarte-api:migration .
```

### Step 4: Run Migration Script

The migration script automatically creates required tables on startup (via `RunMigrations()`). Run it from the API directory:

```bash
cd apps/api

# Full migration (schemas + versions + data + verification)
go run scripts/migrate_to_dynamic.go

# Or run steps individually:
# Step 1: Create schema definitions
go run scripts/migrate_to_dynamic.go schemas

# Step 2: Create schema versions
go run scripts/migrate_to_dynamic.go versions

# Step 3: Migrate item data
go run scripts/migrate_to_dynamic.go data

# Step 4: Verify migration
go run scripts/migrate_to_dynamic.go verify
```

**What the script does:**
1. Creates schema records for each existing item type
2. Creates field records for each model field
3. Migrates items to the new `items` table
4. Creates EAV rows for filterable fields
5. Creates initial schema versions
6. **Migrates ratings:** Copies existing ratings to reference the new unified `items` table (ratings get `item_type = "Item"` and updated `item_id`)
7. Preserves user accounts and sharing relationships

### Step 5: Verify Migration

The script includes automatic verification. Check the output:

```
✅ Migration completed successfully!
   Items migrated: 1,247
   Ratings migrated: 3,892
   Items with errors: 0
```

If errors occurred, review the error log and fix issues before proceeding.

### Step 6: Manual Verification

Run additional verification queries:

```bash
# Check schema count
mysql -u root -p alacarte -e "SELECT COUNT(*) FROM item_type_schemas;"
# Expected: 5 (cheese, gin, wine, coffee, chili-sauce)

# Check item count
mysql -u root -p alacarte -e "SELECT COUNT(*) FROM items;"
# Expected: Same as sum of all old item tables

# Check EAV rows
mysql -u root -p alacarte -e "SELECT COUNT(*) FROM item_field_values;"
# Expected: Non-zero (all filterable fields have EAV rows)

# Check ratings were migrated to new item structure
mysql -u root -p alacarte -e "
  SELECT COUNT(*) FROM ratings WHERE item_type = 'Item';
"
# Expected: Same count as total ratings before migration

# Verify old ratings no longer reference legacy item types
mysql -u root -p alacarte -e "
  SELECT COUNT(*) FROM ratings 
  WHERE item_type IN ('cheese', 'gin', 'wine', 'coffee', 'chili_sauce');
"
# Expected: 0 (all migrated to 'Item')
```

### Step 7: Start Applications

Start the new API and admin panel:

```bash
docker-compose up -d api admin
```

### Step 8: Verify API Endpoints

```bash
# Test schema discovery
curl http://localhost:8080/api/schemas

# Test dynamic item endpoints
curl http://localhost:8080/api/items/cheese
curl http://localhost:8080/api/items/gin

# Test item details
curl http://localhost:8080/api/items/cheese/1

# Test admin schema endpoints
curl http://localhost:8080/admin/schemas \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Step 9: Verify Client App

1. Open the Flutter client
2. Confirm all existing item types appear
3. Verify items display correctly with fields
4. Test creating a new item
5. Test rating an item
6. Test sharing a rating

---

## Rollback Procedure

If issues are discovered, rollback to the previous state:

### Option 1: Database Restore (Full Rollback)

```bash
# Stop applications
docker-compose down

# Restore from backup
mysql -u root -p alacarte < alacarte-backup-YYYYMMDD.sql

# Deploy previous API version
docker pull ghcr.io/username/alacarte-api:previous-tag

# Start applications
docker-compose up -d
```

### Option 2: Migration Script Rollback

The migration script includes a rollback mode:

```bash
cd apps/api
go run scripts/migrate_to_dynamic.go rollback
```

**What rollback does:**
- Removes all items from `items` table
- Removes all schema records and versions
- Removes all EAV rows
- **⚠️ WARNING:** Removes ALL ratings (both migrated and new)
- **Does NOT delete:** Old tables (cheeses, gins, wines, coffees, chili_sauces) or user data

**Important:** The script rollback deletes all ratings because the migration copies ratings to the new structure with `item_type = "Item"`. After rollback, you must restore from backup to recover ratings.

### Option 3: Keep Old Tables (Partial Rollback)

Old tables are preserved during migration. You can:
1. Stop the new API
2. Deploy the old API version
3. Old API continues using old tables
4. New data in dynamic tables is ignored

---

## Post-Migration Cleanup

**Wait 1-2 weeks** after successful migration before cleanup to ensure stability.

### Step 1: Remove Old Tables

```sql
-- After confirming migration is stable
DROP TABLE IF EXISTS cheeses;
DROP TABLE IF EXISTS gins;
DROP TABLE IF EXISTS wines;
DROP TABLE IF EXISTS coffees;
DROP TABLE IF EXISTS chili_sauces;
```

### Step 2: Remove Old Code

Remove deprecated code from the API:

1. **Old models:**
   - `apps/api/models/cheeseModel.go`
   - `apps/api/models/ginModel.go`
   - `apps/api/models/wineModel.go`
   - `apps/api/models/coffeeModel.go`
   - `apps/api/models/chiliSauceModel.go`
   - `apps/api/models/coffeeEnums.go`
   - `apps/api/models/wineColor.go`

2. **Old controllers:**
   - `apps/api/controllers/cheeseController.go`
   - `apps/api/controllers/ginController.go`
   - `apps/api/controllers/wineController.go`
   - `apps/api/controllers/coffeeController.go`
   - `apps/api/controllers/chiliSauceController.go`

3. **Old routes from `main.go`:**
   - `/api/cheese/*`
   - `/api/gin/*`
   - `/api/wine/*`
   - `/api/coffee/*`
   - `/api/chili-sauce/*`

4. **Old AutoMigrate entries from `database.go`**

5. **Old seeding from `seed.go`**

6. **Old table drops from `reset_database.go`**

7. **Old item type switch-case from `item_helper.go`**

8. **Legacy JSON key mapping from `dynamicItemController.go`** (seed/validate functions)

### Step 3: Remove Old Admin Config

Remove hardcoded item type config from admin panel:
- `apps/admin/lib/config/item-types.ts` (old static config)

### Step 4: Update Documentation

- Update API endpoint documentation to reference dynamic endpoints
- Update admin guides to reference schema management UI
- Update developer guides for adding new item types

---

## Verification

### Automated Verification

The migration script includes built-in verification:

```bash
go run scripts/migrate_to_dynamic.go verify
```

Checks:
- Schema count matches item type count
- Item count matches sum of old tables
- All items have field_values JSON
- All filterable fields have EAV rows
- Ratings reference correct items
- Images URLs preserved

### Manual Verification Checklist

**Database:**
- [ ] `item_type_schemas` has 5 records
- [ ] `items` count equals sum of old tables
- [ ] `item_field_values` has rows for all filterable fields
- [ ] Ratings migrated (all have `item_type = 'Item'` and reference new `items` table)
- [ ] Users table unchanged

**API:**
- [ ] `GET /api/schemas` returns all 5 schemas
- [ ] `GET /api/items/cheese` returns items
- [ ] `GET /api/items/gin` returns items
- [ ] `GET /api/items/wine` returns items
- [ ] `GET /api/items/coffee` returns items
- [ ] `GET /api/items/chili-sauce` returns items
- [ ] `GET /api/items/:type/:id` returns correct item with field_values
- [ ] `POST /api/items/:type` creates item with validation
- [ ] `PUT /api/items/:type/:id` updates item
- [ ] `DELETE /api/items/:type/:id` deletes item

**Admin:**
- [ ] Schema list shows all schemas
- [ ] Schema editor shows correct fields
- [ ] Item table shows items with correct columns
- [ ] Delete impact works
- [ ] Seed works with deduplication

**Client:**
- [ ] All item types appear on home screen
- [ ] Items display with correct fields
- [ ] Create form shows correct fields
- [ ] Rating system works
- [ ] Sharing works
- [ ] Images display correctly

---

## Troubleshooting

### "Failed to create schema"

**Cause:** Schema name conflict or database error.

**Solution:**
```bash
# Check existing schemas
mysql -u root -p alacarte -e "SELECT name FROM item_type_schemas;"

# If partial migration occurred, rollback and retry
go run scripts/migrate_to_dynamic.go rollback
go run scripts/migrate_to_dynamic.go
```

### "Items migrated: 0"

**Cause:** Old tables empty or connection issue.

**Solution:**
```bash
# Verify old tables have data
mysql -u root -p alacarte -e "SELECT COUNT(*) FROM cheeses;"
mysql -u root -p alacarte -e "SELECT COUNT(*) FROM gins;"

# Check database connection in script
# Verify .env file has correct credentials
```

### "Ratings not linking to items"

**Cause:** Ratings were not migrated to the new unified item structure.

**Solution:**
```sql
-- Verify ratings reference the new unified item type
SELECT DISTINCT item_type FROM ratings;

-- After migration, should show: 'Item' (and possibly legacy types if migration was partial)
-- All ratings should have item_type = 'Item'

-- Check if any ratings still have legacy item types
SELECT item_type, COUNT(*) FROM ratings 
WHERE item_type IN ('cheese', 'gin', 'wine', 'coffee', 'chili_sauce') 
GROUP BY item_type;

-- If legacy ratings exist, re-run the full migration:
cd apps/api && go run scripts/migrate_to_dynamic.go
```

### "Field values missing in API response"

**Cause:** EAV rows not created or JSON column not populated.

**Solution:**
```sql
-- Check JSON column
SELECT id, name, field_values FROM items LIMIT 5;

-- Check EAV rows
SELECT item_id, field_id, value FROM item_field_values LIMIT 10;

-- If missing, re-run data migration step
go run scripts/migrate_to_dynamic.go data
```

### "Client not showing migrated items"

**Cause:** Schema cache stale or schema inactive.

**Solution:**
```bash
# Verify schema is active
curl http://localhost:8080/api/schemas/cheese | jq '.is_active'

# Should be: true
# If false, activate via admin panel or API:
curl -X PUT http://localhost:8080/admin/schemas/cheese \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_active": true}'

# Client caches schemas for 5 minutes. Force restart app.
```

### "Images not displaying"

**Cause:** Image URLs not migrated correctly.

**Solution:**
```sql
-- Check image URLs in new items
SELECT id, name, image_url FROM items WHERE image_url IS NOT NULL LIMIT 5;

-- Compare with old table
SELECT id, name, image_url FROM cheeses WHERE image_url IS NOT NULL LIMIT 5;

-- If missing, check migration logs for image URL errors
```

### Rollback Fails

**Cause:** Partial state or foreign key constraints.

**Solution:**
```bash
# Full database restore from backup
mysql -u root -p alacarte < alacarte-backup-YYYYMMDD.sql

# Then deploy previous API version
```

---

## Related Documentation

- [Schema Management Guide](/docs/admin/schema-management.md) - Admin UI guide
- [Adding New Item Types](/docs/guides/adding-new-item-types.md) - Post-migration guide
- [API Endpoints Reference](/docs/api/endpoints.md) - Dynamic endpoint documentation
- [Dynamic Schema Design](/openspec/changes/dynamic-item-schema/design.md) - Technical architecture

---

**Migration is a one-time process. After completion, adding new item types requires no code changes.** 🚀
