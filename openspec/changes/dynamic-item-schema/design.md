## Context

The À la carte platform currently supports 5 hardcoded consumable types (cheese, gin, wine, coffee, chili-sauce), each requiring coordinated changes across three codebases to add or modify. This design introduces a dynamic schema system using Entity-Attribute-Value (EAV) storage, enabling administrators to define new item types through the admin panel without code changes.

**Current State:**
- API: Individual Go models and controllers per item type
- Admin: Static TypeScript configuration registry (`itemTypesConfig`)
- Client: Individual Dart models, services, providers, and form strategies
- Database: Separate tables per item type

**Constraints:**
- Must maintain backward compatibility with existing ratings (polymorphic `item_type` field)
- Must support schema versioning for safe field migrations
- Must work across Flutter Web, Android, and Desktop
- Must maintain acceptable query performance with EAV pattern

## Goals / Non-Goals

**Goals:**
- Enable schema creation/management through admin UI
- Provide dynamic API endpoints that adapt to schema definitions
- Support client-side schema discovery for dynamic rendering
- Maintain data integrity through server-side validation
- Support schema versioning for safe evolution

**Non-Goals:**
- Real-time schema sync (clients cache schemas with 5-minute TTL)
- Complex field types (only text, textarea, number, select, checkbox, enum)
- Field-level permissions (all fields visible to all users)
- Automatic data migration between schema versions

## Decisions

### Decision 1: Hybrid JSON + EAV Storage Pattern

**Choice:** Hybrid approach with `items` table containing a `field_values` JSON column for fast reads, plus `item_field_values` EAV table for filter queries.

**Alternatives Considered:**
| Approach | Pros | Cons |
|----------|------|------|
| **JSON column only** | Simple, single table, fast reads | Poor queryability on individual fields, no indexing |
| **EAV pattern only** | Queryable, indexable | Joins required for reads, slower display queries |
| **Hybrid JSON + EAV** | Fast reads via JSON, efficient filtering via EAV indexes | Dual-write complexity |

**Rationale:** Hybrid approach chosen because:
1. **Fast reads**: `field_values` JSON column enables single-row fetch for display (no joins)
2. **Efficient filtering**: EAV table with `(field_id, value)` index powers WHERE/EXISTS queries
3. **Transactional integrity**: Both JSON and EAV writes happen in same database transaction
4. **Schema versioning**: EAV records reference field IDs that are stable across versions

**Implementation note:** The `name` field is stored as a first-class column on the `items` table (`varchar(255), indexed`), not in the `field_values` JSON or EAV table. This enables direct SQL WHERE clauses on name without JSON extraction or EAV subqueries. The `checkUniqueness()` method has a special-case branch for `name` that queries `items.name` directly rather than doing an EAV subquery.

### Decision 2: Schema Registry with In-Memory Cache

**Choice:** API maintains an in-memory `SchemaRegistry` that caches schemas from the database, with automatic refresh on schema changes.

**Alternatives Considered:**
| Approach | Pros | Cons |
|----------|------|------|
| **DB lookup per request** | Always fresh | Performance impact, DB load |
| **In-memory cache + DB** | Fast, consistent | Cache invalidation complexity |
| **Redis cache** | Distributed, shared | Additional infrastructure |

**Rationale:** In-memory cache with DB persistence because:
1. Schemas change infrequently (admin operation)
2. Single API instance (Cloud Run) makes in-memory viable
3. Cache invalidation triggered by schema write operations
4. Startup loads all schemas into memory

### Decision 3: Schema Versioning Strategy

**Choice:** Immutable schema versions stored as JSON snapshots. Each version is a complete snapshot, not a diff.

**Alternatives Considered:**
| Approach | Pros | Cons |
|----------|------|------|
| **Immutable snapshots** | Simple, auditable | Storage overhead |
| **Diff-based versions** | Minimal storage | Complex reconstruction |
| **No versioning** | Simple | No rollback, migration issues |

**Rationale:** Immutable snapshots because:
1. Simplicity - no complex diff logic
2. Auditability - complete history preserved
3. Items reference their creation schema version
4. Storage overhead is minimal (schemas are small)

### Decision 4: Client-Side Schema Discovery

**Choice:** Flutter client fetches schemas at startup and caches them with ETag-based revalidation.

**Alternatives Considered:**
| Approach | Pros | Cons |
|----------|------|------|
| **Runtime discovery** | No code changes for new types | Initial load time |
| **Build-time codegen** | Type safety, performance | Requires rebuild for changes |
| **Hybrid** | Balance | Complexity |

**Rationale:** Runtime discovery because:
1. Core goal: add types without code changes
2. 5-minute cache TTL balances freshness with performance
3. ETag support enables efficient revalidation
4. Schema payload is small (~2-5KB per schema)

### Decision 5: Semi-Dynamic Client UI

**Choice:** Predefined widget components (RatingCard, DetailScreen) that render dynamically based on schema field configurations.

**Alternatives Considered:**
| Approach | Pros | Cons |
|----------|------|------|
| **Fully dynamic** | Maximum flexibility | Complex, harder to polish |
| **Semi-dynamic** | Polished UX, flexible | Limited to predefined layouts |
| **Static per type** | Best UX per type | Requires code changes |

**Rationale:** Semi-dynamic because:
1. Maintains polished, consistent UX across item types
2. Field display hints control layout within components
3. Reduces client complexity significantly
4. Predefined widgets are already well-tested

**Implementation note:** The display hints model was simplified during implementation:
- Spec: `{component, width, hideInList, hideInDetail, hideInForm, primary, secondary}`
- Implemented: `{badge, primary, secondary}`

The badge field renders as a pill on item cards and is excluded from detail rows. Primary and secondary drive the `displaySubtitle` fallback chain. Hide/show visibility controls and component/width hints were not implemented in the initial version.

### Decision 6: Validation Engine Architecture

**Choice:** Server-side validation engine that interprets validation rules from schema definitions. Client validates for UX but server is authoritative.

**Rationale:**
1. Single source of truth for validation logic
2. Validation rules stored with field definitions
3. Client can validate early for better UX
4. Server validation ensures data integrity

## Architecture

### API Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Gin Router                           │
├─────────────────────────────────────────────────────────────┤
│  /api/schemas          → SchemaController                   │
│  /api/schemas/:type    → SchemaController                   │
│  /api/items/:type      → DynamicItemController              │
│  /api/items/:type/:id  → DynamicItemController              │
│  /admin/schemas        → SchemaController (admin)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Services Layer                          │
├─────────────────────────────────────────────────────────────┤
│  SchemaRegistry    - In-memory schema cache                 │
│  ValidationEngine  - Rule-based validation                  │
│  EAVQueryBuilder   - Dynamic SQL generation                 │
│  ItemService       - CRUD operations                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer (GORM)                       │
├─────────────────────────────────────────────────────────────┤
│  ItemTypeSchema    - Schema definitions                     │
│  ItemTypeField     - Field configurations                   │
│  SchemaVersion     - Version snapshots                      │
│  Item              - Item records                           │
│  ItemFieldValue    - EAV field values                       │
└─────────────────────────────────────────────────────────────┘
```

### Database Schema

```sql
CREATE TABLE item_type_schemas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    plural_name VARCHAR(100) NOT NULL,
    icon VARCHAR(50) NOT NULL,
    color VARCHAR(7) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_name (name),
    INDEX idx_active (is_active)
);

CREATE TABLE item_type_fields (
    id INT AUTO_INCREMENT PRIMARY KEY,
    schema_id INT NOT NULL,
    key VARCHAR(50) NOT NULL,
    label VARCHAR(100) NOT NULL,
    field_type ENUM('text', 'textarea', 'number', 'select', 'checkbox', 'enum') NOT NULL,
    required BOOLEAN DEFAULT FALSE,
    `order` INT NOT NULL DEFAULT 0,
    `group` VARCHAR(50),
    validation JSON,
    display JSON,
    options JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (schema_id) REFERENCES item_type_schemas(id) ON DELETE CASCADE,
    UNIQUE KEY uk_schema_key (schema_id, key),
    INDEX idx_order (schema_id, `order`)
);

CREATE TABLE schema_versions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    schema_id INT NOT NULL,
    version INT NOT NULL,
    fields JSON NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    migrated_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (schema_id) REFERENCES item_type_schemas(id) ON DELETE CASCADE,
    UNIQUE KEY uk_schema_version (schema_id, version)
);

CREATE TABLE items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    schema_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    field_values JSON,  -- Denormalized for fast reads: {"brewery": "Mountain Brew Co", "style": "IPA"}
    user_id INT NOT NULL,
    schema_version_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (schema_id) REFERENCES item_type_schemas(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (schema_version_id) REFERENCES schema_versions(id),
    INDEX idx_schema_name (schema_id, name),
    INDEX idx_user (user_id),
    INDEX idx_deleted (deleted_at)
);

CREATE TABLE item_field_values (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    field_id INT NOT NULL,
    value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
    FOREIGN KEY (field_id) REFERENCES item_type_fields(id) ON DELETE CASCADE,
    UNIQUE KEY uk_item_field (item_id, field_id),
    INDEX idx_field_value (field_id, value(100))
);
```

### Admin Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Pages (App Router)                      │
├─────────────────────────────────────────────────────────────┤
│  /admin/schemas              - Schema list                  │
│  /admin/schemas/[type]       - Schema editor                │
│  /admin/schemas/[type]/history - Version history            │
│  /[type]                     - Item list (dynamic)          │
│  /[type]/[id]                - Item detail (dynamic)        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Components Layer                          │
├─────────────────────────────────────────────────────────────┤
│  SchemaBuilder        - Drag-drop field editor              │
│  FieldEditor          - Field configuration form            │
│  ValidationEditor     - Validation rule editor              │
│  DisplayConfigurator  - Display hint editor                │
│  GenericItemTable     - Dynamic item table (existing)       │
│  GenericItemDetail    - Dynamic item detail (existing)      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Layer                               │
├─────────────────────────────────────────────────────────────┤
│  schemaApi            - Schema CRUD                         │
│  dynamicItemApi       - Dynamic item operations             │
└─────────────────────────────────────────────────────────────┘
```

### Client Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Providers (Riverpod)                      │
├─────────────────────────────────────────────────────────────┤
│  schemaProvider       - Schema cache and discovery          │
│  dynamicItemProvider  - Item state management               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Models                                  │
├─────────────────────────────────────────────────────────────┤
│  ItemSchema           - Schema definition                   │
│  SchemaField          - Field configuration                 │
│  DynamicItem          - Item with field values              │
│  ValidationRule       - Validation rules                    │
│  DisplayHint          - Display configuration               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Widgets                                 │
├─────────────────────────────────────────────────────────────┤
│  DynamicForm          - Schema-driven form builder          │
│  DynamicFieldRenderer - Per-type field rendering (unused)   │
│  RatingCard           - Item card (built in item_type_screen)│
│  ItemDetailScreen     - Detail view (existing, adapted)     │
├─────────────────────────────────────────────────────────────┤
│                      Utilities                               │
├─────────────────────────────────────────────────────────────┤
│  SchemaIconUtils      - Icon/color parsing (unused)         │
├─────────────────────────────────────────────────────────────┤
│                      Models                                  │
├─────────────────────────────────────────────────────────────┤
│  ItemSchema           - Schema definition                   │
│  SchemaField          - Field configuration                 │
│  DynamicItem          - Item with field values              │
│  ValidationRule       - Validation rules                    │
│  DisplayHint          - Display configuration (badge/primary/secondary) │
└─────────────────────────────────────────────────────────────┘
```

### Decision 7: Composite Uniqueness at Schema Level

**Choice:** Schemas may define a `unique_fields` array of field keys whose combined values must be unique. The backend enforces this via `checkUniqueness()` in `EAVQueryBuilder`.

**Alternatives Considered:**
| Approach | Pros | Cons |
|----------|------|------|
| **No uniqueness enforcement** | Simple | Allows duplicates |
| **Per-field uniqueness only** | Predictable | Can't express (name+producer) uniqueness |
| **Composite uniqueness at schema level** | Flexible, admin-configurable | Requires EAV subqueries for non-name fields |

**Rationale:** Composite uniqueness because:
1. Some item types require uniqueness across field combinations (e.g., gin: name+producer)
2. Stored as JSON array on the schema, fully admin-configurable
3. The admin item table uses `unique_fields` as display columns when configured (shows what makes items distinct)
4. Seed operation uses `unique_fields` for deduplication checks
5. The `name` field gets a fast-path check against `items.name` column; other fields use EAV subqueries

### Decision 8: Test Infrastructure with Testcontainers

**Choice:** Use `testcontainers-go` with the MySQL module for all database-dependent tests. Controller integration tests use `httptest` + testcontainers.

**Alternatives Considered:**
| Approach | Pros | Cons |
|----------|------|------|
| **Real MySQL (current)** | Simple setup | Requires running DB, no isolation, CI unfriendly |
| **SQLite in-memory** | Fast, no Docker | Different DB engine, no EAV index testing, no JSON column parity |
| **Mocks/stubs** | Fast, no infra | Can't test real EAV queries, fragile, no integration coverage |
| **testcontainers-go** | Self-contained, prod-identical | Requires Docker |

**Rationale:** Testcontainers because:
1. Same MySQL 8.4 as production — EAV indexes, JSON columns, transactions behave identically
2. Self-contained — `go test ./...` works anywhere Docker is available
3. CI-ready — GitHub Actions `ubuntu-latest` runners have Docker pre-installed (already used by `build-api` job)
4. Isolated — each test run gets a fresh ephemeral database
5. No env vars needed — container DSN is generated at runtime

**Architecture:**

```
┌──────────────────────────────────────────────────────────────┐
│  utils/testdb.go                                             │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  SetupTestDB(ctx) → (cleanup func, error)              │    │
│  │    • mysql.Run(ctx, "mysql:8.4")                     │    │
│  │    • sets utils.DB via container DSN                  │    │
│  │    • calls RunMigrations()                            │    │
│  │    • returns cleanup (terminate container)            │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                              │
│  utils/test_seed.go                                          │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  SeedDefaultSchemas(db) → creates 5 type schemas   │    │
│  │    • Extracted from scripts/migration.go              │    │
│  │    • Reusable by any test package                     │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

**SchemaRegistry change:** Add `Reset()` method to clear in-memory cache. Needed because `sync.Once` prevents re-initialization between tests that modify schemas.

**Test file organization:** One `_test.go` per source file:
- `services/validation_engine_test.go` — pure unit tests, no DB needed
- `services/schema_registry_test.go` — DB-dependent via testcontainers
- `services/query_builder_test.go` — DB-dependent via testcontainers
- `controllers/schema_controller_test.go` — `httptest` + testcontainers
- `controllers/dynamic_item_controller_test.go` — `httptest` + testcontainers

**Controller test pattern:**
```go
func TestSchemaCreate(t *testing.T) {
    cleanup, _ := utils.SetupTestDB()
    defer cleanup()
    utils.SeedDefaultSchemas(utils.DB)
    services.GetSchemaRegistry().LoadSchemas()

    router := setupTestRouter()
    w := httptest.NewRecorder()
    req, _ := http.NewRequest("POST", "/admin/schemas", body)
    router.ServeHTTP(w, req)

    assert.Equal(t, 201, w.Code)
    // Verify DB state...
}
```

### Decision 9: Rating Foreign Key Migration

**Choice:** Replace the polymorphic `item_type`/`item_id` pair on ratings with a direct foreign key to `items.id` with `ON DELETE CASCADE`.

**Alternatives Considered:**
| Approach | Pros | Cons |
|----------|------|------|
| **Keep polymorphic** | No migration needed | Redundant column, GORM preload broken |
| **FK + CASCADE** | Data integrity, simpler queries, auto-cleanup | Requires migration, ratings deleted with item |
| **FK + RESTRICT** | Prevents accidental item deletion | Manual cleanup required, more complex |

**Rationale:** FK with CASCADE because:
1. `item_type` is redundant — `item_id` alone uniquely identifies an item in the unified `items` table
2. GORM's polymorphic preload (`Item.Ratings`) is already broken (generates `WHERE item_type = 'items'` but data has `'cheese'`, `'gin'`, etc.) — the codebase never uses it
3. Item deletion is an admin action with a deletion impact screen before confirmation — CASCADE is safe
4. All rating queries currently filter by both `item_type` AND `item_id` — removing `item_type` simplifies to `WHERE item_id = ?`

**Migration Strategy (3-phase):**

```
Phase 1: Code + Model (zero-downtime)
  • Change Rating.ItemType → Rating.Item (FK to items)
  • Keep ItemType as gorm:"-" to prevent AutoMigrate from dropping column
  • Remove item_type from all queries, request bodies, URL params
  • Add FK constraint via AutoMigrate

Phase 2: Soak (N days)
  • Verify all rating queries resolve correctly
  • Monitor for orphaned ratings (none expected)
  • Confirm FK CASCADE behaves as expected on item delete

Phase 3: DB Cleanup (with legacy table removal)
  • DROP INDEX idx_ratings_item ON ratings
  • ALTER TABLE ratings DROP COLUMN item_type
  • Remove ItemType gorm:"-" field from Rating struct
```

**Index changes:**
```
Before:  idx_ratings_user_item (user_id, item_type, item_id)
         idx_ratings_item       (item_type, item_id)

After:   idx_ratings_user_item (user_id, item_id)
         idx_ratings_item       (item_id)
```

**API endpoint changes:**
```
Before:  GET  /api/rating/:type/:id          → RatingByItem
         GET  /api/stats/community/:type/:id  → GetCommunityStats

After:   GET  /api/rating/:id                → RatingByItem
         GET  /api/stats/community/:id       → GetCommunityStats
```

**Client impact:**
- `Rating` model drops `itemType` field — item type derived from item's schema when needed
- `RatingByAuthor`/`RatingByViewer` `?type=` filter removed (client never used it)
- `RatingByItem` and `GetCommunityStats` URL patterns simplified

## Risks / Trade-offs

### Risk 1: EAV Query Performance
**Risk:** EAV queries require joins and may be slower than single-table queries.

**Mitigation:**
- Index `(field_id, value)` for filtered searches
- Cache schemas in memory to avoid joins for schema data
- Consider materialized views for frequently-accessed item lists
- Benchmark with realistic data volumes before deployment

### Risk 2: Schema Migration Complexity
**Risk:** Adding required fields to existing schemas may leave items in invalid state.

**Mitigation:**
- New required fields only apply to new items
- Existing items validated against their creation schema version
- Admin can view items missing required fields
- Migration tools for bulk updates if needed

### Risk 3: Client Cache Staleness
**Risk:** Client may use stale schema if admin changes schema during session.

**Mitigation:**
- 5-minute cache TTL with ETag revalidation
- Schema version included in API responses
- Client can force refresh schemas
- Validation errors include current schema version

### Risk 4: Breaking Changes for Existing Users
**Risk:** Migration removes existing item type models, breaking existing workflows.

**Mitigation:**
- Comprehensive migration script with rollback capability
- Deploy during low-traffic window
- Verify all 5 existing types migrate correctly
- Keep old tables temporarily for rollback

### Risk 5: Admin UI Complexity
**Risk:** Schema builder UI may be confusing for non-technical administrators.

**Mitigation:**
- Clear field type descriptions with examples
- Preview mode showing how items will appear
- Validation before saving schema changes
- Undo capability for recent changes

### Risk 6: Dual-Write Synchronization
**Risk:** JSON column and EAV rows could get out of sync if writes fail partially.

**Mitigation:**
- All writes use database transactions (atomic: both JSON and EAV succeed or both fail)
- Application code writes JSON first, then EAV rows
- On failure, transaction rolls back automatically
- Periodic consistency check can verify JSON matches EAV data

### Risk 7: Orphaned Client Widgets
**Risk:** `DynamicFieldRenderer` (280 lines) and `SchemaIconUtils` (100 lines) exist in the Flutter client but are never imported by any other file. They duplicate rendering logic done inline in `ItemDetailHeader` and icon parsing in `ItemTypeHelper`.

**Mitigation:** Either integrate them into the active rendering pipeline or remove them to avoid maintenance burden and confusion about which pattern to follow.

## Migration Plan

### Phase 1: Database Setup (Deploy First)
1. Create new tables: `item_type_schemas`, `item_type_fields`, `schema_versions`, `items`, `item_field_values`
2. Run migration script to convert existing data:
   - For each existing item type, create schema record
   - For each field in model, create field record
   - For each item, create Item and ItemFieldValue records
   - Create initial schema versions
3. Verify data integrity with automated checks
4. Keep old tables for rollback

### Phase 2: API Deployment
1. Deploy new API with dynamic endpoints
2. Old endpoints return 410 Gone with migration message
3. Monitor error rates and performance
4. Verify schema registry loads correctly

### Phase 3: Admin Deployment
1. Deploy schema management UI
2. Remove static `itemTypesConfig`
3. Update GenericItemTable/Detail to use dynamic schemas
4. Verify all existing item types work correctly

### Phase 4: Client Deployment
1. Deploy Flutter client with schema discovery
2. Remove individual item models
3. Verify all platforms (Web, Android, Desktop)
4. Monitor schema cache hit rates

### Phase 5: Cleanup
1. Remove old item type tables after verification
2. Remove old model/controller code
3. Update documentation

### Rollback Strategy
1. **Database:** Old tables retained, can restore from backup
2. **API:** Previous version can be redeployed
3. **Admin:** Previous version can be redeployed
4. **Client:** Previous version can be redeployed from app stores

## Open Questions

1. **Should we support field dependencies?** (e.g., show field B only when field A has specific value)
   - Not in initial implementation
   - Can be added later if needed

2. **How to handle large option lists?** (e.g., 100+ grape varieties for wine)
   - Current design stores options in JSON field
   - May need separate table for large option sets
   - Consider autocomplete component for large lists

3. **Should schemas support localization?**
   - Current design uses single language
   - Could add `label_i18n` JSON field later
   - Not required for initial implementation

4. **Rate limiting for schema discovery endpoint?**
    - Implement standard rate limiting
    - Consider higher limits for authenticated users
    - Monitor usage patterns

### Decision 10: Client-Side Pagination Architecture

**Problem:** The Flutter client calls `GET /api/items/:type` with no query parameters, receiving a default 20-item page. Search and category filters run locally on those 20 items. Filter options are derived by scanning loaded items, which only sees the first page. The home screen loads full item lists just to count them. With datasets exceeding 20 items, the current approach is broken.

**Choice:** Server-side pagination with infinite scroll, server-side search/filter, schema-based filter discovery, and a dedicated stats endpoint for home screen counts.

**Alternatives Considered:**
| Approach | Pros | Cons |
|----------|------|------|
| **Client-side pagination** | Works offline, faster page flips | Still loads everything, defeats purpose |
| **Cursor-based pagination** | Stable under concurrent inserts | More complex, no "page N" semantics |
| **Offset/page-based (chosen)** | Simple, API already supports it, matches common patterns | Items can shift between pages during concurrent edits |

**Rationale:**

1. **API already supports it.** The backend returns `{ items, total, page, per_page, total_pages }` — the client just ignores this envelope. Minimal backend changes needed.

2. **Infinite scroll** over a manual "Load More" button because:
   - Natural mobile UX pattern (swipe to browse)
   - Already used in the ratings/community feed
   - 200px pre-fetch threshold for smooth scrolling

3. **Server-side search and filters** because:
   - Client-side filtering on 20 items is fundamentally broken
   - API already supports `?search=` and `?filter[key]=value` query params
   - Enables large datasets without loading everything

4. **Schema-based filter option discovery** instead of scanning loaded items because:
   - Scanning only sees values in current page (max 20)
   - Schema already defines select/enum options server-side
   - More correct: shows all possible filter values, not just those present in first 20 items
   - `ItemFilterHelper.getAvailableFilters()` changes from `(List<T> items, String itemType)` to `(ItemSchema schema)`

5. **Dedicated stats endpoint** (`GET /api/stats/type/:type`) because:
   - Returns `{ total_items, user_rated_count }` in one request
   - Home screen needs both counts per type
   - Decouples item counting from item loading
   - `user_rated_count` requires auth context (distinct user-rated items per type)
   - Note: `total_items` overlaps with `GET /api/schemas?include_counts=true` (already implemented), but bundling with `user_rated_count` avoids home screen making two requests per type

6. **Debounce in the widget layer** (not provider) because:
   - Provider stays stateless (no Timer management)
   - 300ms debounce prevents API calls on every keystroke
   - Widget already has lifecycle hooks (`dispose`) for cleanup

**Cache Strategy:**
- The 5-minute TTL cache in `DynamicItemService` is **removed entirely**. The provider's `DynamicItemState` becomes the single source of truth.
- `forceRefresh: true` clears accumulated items and fetches from page 1.

**Filter + Pagination Interplay:**
```
Applying any filter (search or category) → resets to page 1 with filtered results
Removing all filters → resets to page 1 with unfiltered results
User scrolls → appends next page within current filter context
Pull-to-refresh → page 1, maintains current filters
```

**State machine:**
```
Initial:    items=[], page=0, total=0, totalPages=0, loading=true
loadItems() → page 1:  items=[1..20], page=1, total=150, totalPages=8
loadMoreItems() → page 2: items=[1..40], page=2, total=150, totalPages=8
search("brie") → page 1: items=[matching 1..N], page=1, total=N, totalPages=ceil(N/20)
setFilter(type=Soft) → page 1: items=[filtered 1..M], page=1, total=M
refreshItems() → same as loadItems, clears accumulated first
```
