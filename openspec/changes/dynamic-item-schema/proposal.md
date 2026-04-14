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

**Database**:
- New tables: `item_type_schemas`, `item_type_fields`, `items`, `item_field_values`, `schema_versions`
- Migration: Convert existing item data to EAV format
- Remove: Individual item tables (cheeses, gins, wines, coffees, chili_sauces) after migration

**Rating System**:
- Polymorphic `ItemType` field in ratings remains compatible (now references schema name instead of table name)
