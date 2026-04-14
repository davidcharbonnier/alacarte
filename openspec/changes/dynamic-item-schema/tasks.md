## 1. Database & Models (API)

- [ ] 1.1 Create `ItemTypeSchema` model in `apps/api/models/schemaModel.go`
- [ ] 1.2 Create `ItemTypeField` model in `apps/api/models/schemaModel.go`
- [ ] 1.3 Create `SchemaVersion` model in `apps/api/models/schemaModel.go`
- [ ] 1.4 Create `Item` model in `apps/api/models/itemModel.go`
- [ ] 1.5 Create `ItemFieldValue` model in `apps/api/models/itemModel.go`
- [ ] 1.6 Add database migrations for new tables
- [ ] 1.7 Add GORM indexes for EAV query optimization

## 2. API Core Services

- [ ] 2.1 Create `SchemaRegistry` service in `apps/api/services/schema_registry.go`
- [ ] 2.2 Implement schema loading from database on startup
- [ ] 2.3 Implement schema cache with mutex for thread safety
- [ ] 2.4 Create `ValidationEngine` service in `apps/api/services/validation_engine.go`
- [ ] 2.5 Implement validation for required fields
- [ ] 2.6 Implement validation for string length (minLength, maxLength)
- [ ] 2.7 Implement validation for numeric range (min, max)
- [ ] 2.8 Implement validation for pattern matching
- [ ] 2.9 Implement validation for select/enum options
- [ ] 2.10 Implement validation for field type matching
- [ ] 2.11 Create `EAVQueryBuilder` service in `apps/api/services/query_builder.go`
- [ ] 2.12 Implement dynamic query building for list operations
- [ ] 2.13 Implement dynamic query building for filter operations
- [ ] 2.14 Implement dynamic query building for search operations

## 3. API Controllers & Routes

- [ ] 3.1 Create `SchemaController` in `apps/api/controllers/schemaController.go`
- [ ] 3.2 Implement `GET /api/schemas` endpoint (list all schemas)
- [ ] 3.3 Implement `GET /api/schemas/:type` endpoint (get schema details)
- [ ] 3.4 Implement `POST /admin/schemas` endpoint (create schema)
- [ ] 3.5 Implement `PUT /admin/schemas/:type` endpoint (update schema)
- [ ] 3.6 Implement `DELETE /admin/schemas/:type` endpoint (delete schema)
- [ ] 3.7 Implement `GET /admin/schemas/:type/versions/:version` endpoint (schema history)
- [ ] 3.8 Create `DynamicItemController` in `apps/api/controllers/dynamicItemController.go`
- [ ] 3.9 Implement `GET /api/items/:type` endpoint (list items)
- [ ] 3.10 Implement `GET /api/items/:type/:id` endpoint (get item)
- [ ] 3.11 Implement `POST /api/items/:type` endpoint (create item)
- [ ] 3.12 Implement `PUT /api/items/:type/:id` endpoint (update item)
- [ ] 3.13 Implement `DELETE /api/items/:type/:id` endpoint (delete item)
- [ ] 3.14 Implement `POST /api/items/:type/:id/image` endpoint (upload image)
- [ ] 3.15 Implement `DELETE /api/items/:type/:id/image` endpoint (delete image)
- [ ] 3.16 Implement `GET /admin/items/:type/:id/delete-impact` endpoint (admin)
- [ ] 3.17 Add ETag support for schema responses with caching headers
- [ ] 3.18 Update `main.go` to register new routes

## 4. Admin Panel - Schema Management

- [ ] 4.1 Create TypeScript types for schema in `apps/admin/lib/types/schema.ts`
- [ ] 4.2 Create `schemaApi` client in `apps/admin/lib/api/schema-api.ts`
- [ ] 4.3 Create schema list page at `apps/admin/app/admin/schemas/page.tsx`
- [ ] 4.4 Create schema editor page at `apps/admin/app/admin/schemas/[type]/page.tsx`
- [ ] 4.5 Create `FieldEditor` component for field configuration
- [ ] 4.6 Create `ValidationEditor` component for validation rules
- [ ] 4.7 Create `DisplayConfigurator` component for display hints
- [ ] 4.8 Create `SchemaBuilder` component with drag-and-drop field ordering
- [ ] 4.9 Implement field type selector (text, textarea, number, select, checkbox, enum)
- [ ] 4.10 Implement options editor for select/enum fields
- [ ] 4.11 Implement primary/secondary field designation
- [ ] 4.12 Implement schema activation/deactivation
- [ ] 4.13 Implement schema version history view

## 5. Admin Panel - Dynamic Item Management

- [ ] 5.1 Update `GenericItemTable` to fetch schema dynamically
- [ ] 5.2 Update `GenericItemDetail` to render fields from schema
- [ ] 5.3 Update `GenericSeedForm` to work with dynamic schemas
- [ ] 5.4 Remove static `itemTypesConfig` from `apps/admin/lib/config/item-types.ts`
- [ ] 5.5 Update API client to use dynamic endpoints
- [ ] 5.6 Implement schema caching in admin panel

## 6. Flutter Client - Schema Discovery

- [ ] 6.1 Create `ItemSchema` model in `apps/client/lib/models/item_schema.dart`
- [ ] 6.2 Create `SchemaField` model in `apps/client/lib/models/schema_field.dart`
- [ ] 6.3 Create `ValidationRule` model in `apps/client/lib/models/validation_rule.dart`
- [ ] 6.4 Create `DisplayHint` model in `apps/client/lib/models/display_hint.dart`
- [ ] 6.5 Create `SchemaService` in `apps/client/lib/services/schema_service.dart`
- [ ] 6.6 Create `SchemaProvider` in `apps/client/lib/providers/schema_provider.dart`
- [ ] 6.7 Implement schema fetching on app startup
- [ ] 6.8 Implement schema caching with ETag revalidation
- [ ] 6.9 Implement schema refresh mechanism

## 7. Flutter Client - Dynamic Items

- [ ] 7.1 Create `DynamicItem` model in `apps/client/lib/models/dynamic_item.dart`
- [ ] 7.2 Implement `DynamicItem` as `RateableItem` interface
- [ ] 7.3 Create `DynamicItemService` in `apps/client/lib/services/dynamic_item_service.dart`
- [ ] 7.4 Create `DynamicItemProvider` in `apps/client/lib/providers/dynamic_item_provider.dart`
- [ ] 7.5 Create `DynamicForm` widget in `apps/client/lib/widgets/forms/dynamic_form.dart`
- [ ] 7.6 Create field renderer widgets (TextField, NumberField, SelectField, Checkbox)
- [ ] 7.7 Update `RatingCard` to work with `DynamicItem`
- [ ] 7.8 Update `ItemDetailScreen` to render dynamic fields
- [ ] 7.9 Update `ItemListScreen` to use schema for display
- [ ] 7.10 Remove individual item models (CheeseItem, GinItem, WineItem, CoffeeItem, ChiliSauceItem)
- [ ] 7.11 Remove individual form strategies
- [ ] 7.12 Update `ItemTypeHelper` to use discovered schemas

## 8. Data Migration

- [ ] 8.1 Create migration script in `apps/api/scripts/migrate_to_dynamic.go`
- [ ] 8.2 Implement cheese data migration
- [ ] 8.3 Implement gin data migration
- [ ] 8.4 Implement wine data migration
- [ ] 8.5 Implement coffee data migration
- [ ] 8.6 Implement chili-sauce data migration
- [ ] 8.7 Create schema definitions for existing item types
- [ ] 8.8 Create initial schema versions
- [ ] 8.9 Write migration verification tests
- [ ] 8.10 Create rollback script

## 9. Testing

- [ ] 9.1 Write unit tests for `SchemaRegistry`
- [ ] 9.2 Write unit tests for `ValidationEngine`
- [ ] 9.3 Write unit tests for `EAVQueryBuilder`
- [ ] 9.4 Write integration tests for schema CRUD endpoints
- [ ] 9.5 Write integration tests for dynamic item CRUD endpoints
- [ ] 9.6 Write integration tests for filtering and search
- [ ] 9.7 Write widget tests for admin schema builder
- [ ] 9.8 Write widget tests for Flutter dynamic form
- [ ] 9.9 Write E2E tests for schema creation workflow
- [ ] 9.10 Write E2E tests for item creation with dynamic schema

## 10. Documentation

- [ ] 10.1 Update API documentation for new endpoints
- [ ] 10.2 Create schema management guide for administrators
- [ ] 10.3 Update developer documentation for adding new item types
- [ ] 10.4 Document migration process for existing deployments
- [ ] 10.5 Update README with dynamic schema information

## 11. Deployment

- [ ] 11.1 Deploy database migrations to staging
- [ ] 11.2 Verify migration on staging with test data
- [ ] 11.3 Deploy API changes to staging
- [ ] 11.4 Deploy admin changes to staging
- [ ] 11.5 Deploy client changes to staging
- [ ] 11.6 Run full regression tests on staging
- [ ] 11.7 Deploy database migrations to production
- [ ] 11.8 Deploy API to production
- [ ] 11.9 Deploy admin to production
- [ ] 11.10 Deploy client to production
- [ ] 11.11 Monitor error rates and performance
- [ ] 11.12 Remove old item type tables after verification
- [ ] 11.13 Remove old model/controller code