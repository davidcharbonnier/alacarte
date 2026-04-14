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
│  DynamicFieldRenderer - Per-type field widgets              │
│  RatingCard           - Item card (existing, adapted)       │
│  ItemDetailScreen     - Detail view (existing, adapted)     │
└─────────────────────────────────────────────────────────────┘
```

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
