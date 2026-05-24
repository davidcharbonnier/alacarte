## Why

Adding a new item type currently requires coordinated changes across three codebases: API (model + controller + routes), Admin (config + UI), and Client (model + service + provider + strategy). This is slow, error-prone, and creates a high barrier to expanding the platform. A dynamic schema system would allow item types to be defined once through the admin panel, with automatic API endpoints and client discovery.

## What Changes

- **BREAKING**: Replace hardcoded item type models (Cheese, Gin, Wine, Coffee, ChiliSauce) with a dynamic EAV-based storage system
- **BREAKING**: Replace static `itemTypesConfig` in Admin with database-driven schema management
- **BREAKING**: Replace hardcoded item models in Client with dynamic schema discovery and rendering
- New admin UI for creating and managing item type schemas with field definitions
- New API endpoints for schema CRUD and dynamic item operations
- Schema versioning to support safe field migrations
- Server-driven validation rules stored in schema definitions
- Client discovers supported item types at runtime via schema API
- New `rated` query parameter on `GET /api/items/:type` for server-side filtering of items the authenticated user has rated or been shared (secured via JWT)

## Capabilities

### New Capabilities

- `schema-management`: Define, edit, version, and delete item type schemas through admin panel with field definitions, validation rules, and display hints
- `dynamic-item-storage`: EAV-based storage system that stores items of any schema type with field values as attribute-value pairs
- `schema-discovery`: API endpoints for clients to discover available schemas, their fields, validation rules, and UI hints
- `dynamic-validation`: Server-side validation engine that enforces rules defined in schema definitions

### Modified Capabilities

- `item-management`: Filter by picture presence requirement extends to dynamically-typed items (same behavior, broader scope)

## Impact

**API (apps/api)**:
- New models: `ItemTypeSchema`, `ItemTypeField`, `Item`, `ItemFieldValue`, `SchemaVersion`
- New services: `SchemaRegistry`, `ValidationEngine`, `EAVQueryBuilder`
- New controllers: `SchemaController`, `DynamicItemController`
- Remove: Individual item type models and controllers (Cheese, Gin, Wine, Coffee, ChiliSauce)

**Admin (apps/admin)**:
- New pages: Schema list, schema builder, field editor
- New components: Drag-and-drop field configuration, validation editor, display hint configurator
- Remove: Static `itemTypesConfig` registry
- Update: `GenericItemTable`, `GenericItemDetail` to fetch schemas dynamically

**Client (apps/client)**:
- New models: `ItemSchema`, `SchemaField`, `DynamicItem`
- New providers: `SchemaProvider` for caching discovered schemas
- New widgets: `DynamicForm`, dynamic field renderers
- Remove: Individual item models (CheeseItem, GinItem, WineItem, CoffeeItem, ChiliSauceItem)
- Remove: Individual form strategies
- Updated: `DynamicItemNotifier` gains separate state tracking for user-rated items vs all items, enabling the My List tab to have its own paginated data source

**Database**:
- New tables: `item_type_schemas`, `item_type_fields`, `items`, `item_field_values`, `schema_versions`
- Migration: Convert existing item data to EAV format
- Remove: Individual item tables (cheeses, gins, wines, coffees, chili_sauces) after migration
- Remove: `item_type` column and composite index from `ratings` table after verification
- Add: FK constraint `ratings.item_id → items.id` with CASCADE delete

**Rating System**:
- `apps/api/models/ratingModel.go`: Replace `ItemType string` with `Item Item` FK, keep field as `gorm:"-"` in Phase 1
- `apps/api/models/itemModel.go`: Change `polymorphic:Item` to `foreignKey:ItemID`
- `apps/api/controllers/ratingController.go`: Remove `item_type` from all request bodies, WHERE clauses, and URL params
- `apps/api/services/query_builder.go`: Remove `item_type = ?` from rating count queries
- `apps/api/main.go`: Update rating and stats route definitions
- `apps/client/lib/models/rating.dart`: Remove `itemType` field and extensions
- `apps/client/lib/config/api_config.dart`: Update rating and stats URL patterns
- `apps/client/lib/services/rating_service.dart`: Update method signatures
- `apps/client/lib/providers/community_stats_provider.dart`: Remove `itemType` from params
- Database: Add FK constraint, drop `item_type` column and composite index in Phase 3
