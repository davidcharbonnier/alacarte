## 1. Database & Models (API)

- [x] 1.1 Create `ItemTypeSchema` model in `apps/api/models/schemaModel.go`
- [x] 1.2 Create `ItemTypeField` model in `apps/api/models/schemaModel.go`
- [x] 1.3 Create `SchemaVersion` model in `apps/api/models/schemaModel.go`
- [x] 1.4 Create `Item` model with `field_values JSON` column in `apps/api/models/itemModel.go`
- [x] 1.5 Create `ItemFieldValue` model in `apps/api/models/itemModel.go`
- [x] 1.6 Add database migrations for new tables
- [x] 1.7 Add GORM indexes for hybrid query optimization (EAV + JSON)

## 2. API Core Services

- [x] 2.1 Create `SchemaRegistry` service in `apps/api/services/schema_registry.go`
- [x] 2.2 Implement schema loading from database on startup
- [x] 2.3 Implement schema cache with mutex for thread safety
- [x] 2.4 Create `ValidationEngine` service in `apps/api/services/validation_engine.go`
- [x] 2.5 Implement validation for required fields
- [x] 2.6 Implement validation for string length (minLength, maxLength)
- [x] 2.7 Implement validation for numeric range (min, max)
- [x] 2.8 Implement validation for pattern matching
- [x] 2.9 Implement validation for select/enum options
- [x] 2.10 Implement validation for field type matching
- [x] 2.11 Create `EAVQueryBuilder` service in `apps/api/services/query_builder.go`
- [x] 2.12 Implement hybrid query building: JSON column for reads, EAV for filters
- [x] 2.13 Implement dynamic query building for filter operations using EAV indexes
- [x] 2.14 Implement dynamic query building for search operations
- [x] 2.15 Create `FieldValuesJSON` helper to build JSON from EAV rows

## 3. API Controllers & Routes

- [x] 3.1 Create `SchemaController` in `apps/api/controllers/schemaController.go`
- [x] 3.2 Implement `GET /api/schemas` endpoint (list all schemas)
- [x] 3.3 Implement `GET /api/schemas/:type` endpoint (get schema details)
- [x] 3.4 Implement `POST /admin/schemas` endpoint (create schema)
- [x] 3.5 Implement `PUT /admin/schemas/:type` endpoint (update schema)
- [x] 3.6 Implement `DELETE /admin/schemas/:type` endpoint (delete schema)
- [x] 3.7 Implement `GET /admin/schemas/:type/versions/:version` endpoint (schema history)
- [x] 3.8 Create `DynamicItemController` in `apps/api/controllers/dynamicItemController.go`
- [x] 3.9 Implement `GET /api/items/:type` endpoint (list items)
- [x] 3.10 Implement `GET /api/items/:type/:id` endpoint (get item)
- [x] 3.11 Implement `POST /api/items/:type` endpoint with dual-write (JSON + EAV in transaction)
- [x] 3.12 Implement `PUT /api/items/:type/:id` endpoint with dual-write
- [x] 3.13 Implement `DELETE /api/items/:type/:id` endpoint (delete item)
- [x] 3.14 Implement `POST /api/items/:type/:id/image` endpoint (upload image)
- [x] 3.15 Implement `DELETE /api/items/:type/:id/image` endpoint (delete image)
- [x] 3.16 Implement `GET /admin/items/:type/:id/delete-impact` endpoint (admin)
- [x] 3.17 Add ETag support for schema responses with caching headers
- [x] 3.18 Update `main.go` to register new routes

## 4. Admin Panel - Schema Management

- [x] 4.1 Create TypeScript types for schema in `apps/admin/lib/types/schema.ts`
- [x] 4.2 Create `schemaApi` client in `apps/admin/lib/api/schema-api.ts`
- [x] 4.3 Create schema list page at `apps/admin/app/admin/schemas/page.tsx`
- [x] 4.4 Create schema editor page at `apps/admin/app/admin/schemas/[type]/page.tsx`
- [x] 4.5 Create `FieldEditor` component for field configuration
- [x] 4.6 Create `ValidationEditor` component for validation rules
- [x] 4.7 Create `DisplayConfigurator` component for display hints
- [x] 4.8 Create `SchemaBuilder` component with drag-and-drop field ordering
- [x] 4.9 Implement field type selector (text, textarea, number, select, checkbox, enum)
- [x] 4.10 Implement options editor for select/enum fields
- [x] 4.11 Implement primary/secondary field designation
- [x] 4.12 Implement schema activation/deactivation
- [x] 4.13 Implement schema version history view

## 5. Admin Panel - Dynamic Item Management

- [x] 5.1 Update `GenericItemTable` to fetch schema dynamically
- [x] 5.2 Update `GenericItemDetail` to render fields from schema
- [x] 5.3 Update `GenericSeedForm` to work with dynamic schemas
- [x] 5.4 Remove static `itemTypesConfig` from `apps/admin/lib/config/item-types.ts`
- [x] 5.5 Update API client to use dynamic endpoints
- [x] 5.6 Implement schema caching in admin panel

## 6. Flutter Client - Schema Discovery

- [x] 6.1 Create `ItemSchema` model in `apps/client/lib/models/item_schema.dart`
- [x] 6.2 Create `SchemaField` model in `apps/client/lib/models/schema_field.dart`
- [x] 6.3 Create `ValidationRule` model in `apps/client/lib/models/validation_rule.dart`
- [x] 6.4 Create `DisplayHint` model in `apps/client/lib/models/display_hint.dart`
- [x] 6.5 Create `SchemaService` in `apps/client/lib/services/schema_service.dart`
- [x] 6.6 Create `SchemaProvider` in `apps/client/lib/providers/schema_provider.dart`
- [x] 6.7 Implement schema fetching on app startup
- [x] 6.8 Implement schema caching with ETag revalidation
- [x] 6.9 Implement schema refresh mechanism

## 7. Flutter Client - Dynamic Items

- [x] 7.1 Create `DynamicItem` model in `apps/client/lib/models/dynamic_item.dart`
- [x] 7.2 Implement `DynamicItem` as `RateableItem` interface
- [x] 7.3 Create `DynamicItemService` in `apps/client/lib/services/dynamic_item_service.dart`
- [x] 7.4 Create `DynamicItemProvider` in `apps/client/lib/providers/dynamic_item_provider.dart`
- [x] 7.5 Create `DynamicForm` widget in `apps/client/lib/widgets/forms/dynamic_form.dart`
- [x] 7.6 Create field renderer widgets (TextField, NumberField, SelectField, Checkbox)
- [x] 7.7 Update `RatingCard` to work with `DynamicItem` (existing widgets accept RateableItem)
- [x] 7.8 Update `ItemDetailScreen` to render dynamic fields (existing widgets use detailFields)
- [x] 7.9 Update `ItemListScreen` to use schema for display (uses RateableItem interface)
- [x] 7.10 Remove individual item models (CheeseItem, GinItem, WineItem, CoffeeItem, ChiliSauceItem)
- [x] 7.11 Remove individual form strategies
- [x] 7.12 Update `ItemTypeHelper` to use discovered schemas

## 8. Display Hint Refactor

- [x] 8.1 Refactor DisplayHint model from `{component, width, hideInList, hideInDetail, hideInForm, primary, secondary}` to `{badge, primary, secondary}`
- [x] 8.2 Add `badgeField`, `primaryField`, `secondaryField` getters to `ItemSchema`
- [x] 8.3 Implement `badgeValue` and `displaySubtitle` with primary/secondary fallback on `DynamicItem`
- [x] 8.4 Update `ItemDetailHeader` to use badge field for pill display instead of per-type switch
- [x] 8.5 Create `DynamicFieldRenderer` widget for field-type-based rendering
- [x] 8.6 Create `DynamicFieldEditRenderer` widget for edit-mode field rendering
- [x] 8.7 Create `SchemaIconUtils` utility for icon name → IconData and color parsing
- [x] 8.8 Update `DynamicItem.detailFields` to skip badge field in detail rows

## 9. Unique Fields Support

- [x] 9.1 Add `UniqueFields` JSON column to `ItemTypeSchema` model
- [x] 9.2 Implement `checkUniqueness()` in `EAVQueryBuilder` with composite uniqueness check
- [x] 9.3 Special-case `name` field in uniqueness query (queries `items.name` column directly)
- [x] 9.4 Parse `unique_fields` on schema load/refresh in `SchemaRegistry`
- [x] 9.5 Return `unique_fields` in schema API responses
- [x] 9.6 Add `unique_fields` to admin `ItemTypeSchema` type and form models
- [x] 9.7 Implement unique fields selector in SchemaSettings admin form
- [x] 9.8 Use `unique_fields` as table column selector in `GenericItemTable`
- [x] 9.9 Use `unique_fields` for seed deduplication in `DynamicItemSeed`
- [x] 9.10 Validate `unique_fields` presence in seed data batches

## 10. Name Field as First-Class Column

- [x] 10.1 Add `Name` as top-level column on `items` table (varchar 255, indexed)
- [x] 10.2 Populate `name` from request body in `DynamicItemCreate` and `DynamicItemUpdate`
- [x] 10.3 Update `DynamicItem.fromJson` to parse `name` from API response
- [x] 10.4 Add `name` to `RateableItem` interface and `DynamicItem` model

## 11. Data Migration

- [x] 11.1 Create migration script in `apps/api/scripts/migrate_to_dynamic.go`
- [x] 11.2 Implement cheese data migration
- [x] 11.3 Implement gin data migration
- [x] 11.4 Implement wine data migration
- [x] 11.5 Implement coffee data migration
- [x] 11.6 Implement chili-sauce data migration
- [x] 11.7 Create schema definitions for existing item types
- [x] 11.8 Create initial schema versions
- [x] 11.9 Write migration verification tests
- [x] 11.10 Create rollback script

## 12. Known Issues

- [x] 12.1 Fix React Query stale-data bug: schema editor shows stale data after mutation (see TODO in `schemas/[type]/page.tsx:112`)
- [x] 12.2 Integrate or remove unused `DynamicFieldRenderer` widget (280 lines, never imported)
- [x] 12.3 Integrate or remove unused `SchemaIconUtils` utility (100 lines, never imported)
- [x] 12.4 Wire `filter[has_image]` into admin `GenericItemTable` and Flutter client (API supports it, UI doesn't)
- [x] 12.5 Wire pagination into admin `GenericItemTable` (API client supports it, UI loads all items)
- [x] 12.6 Wire server-side search into admin table (currently uses client-side filtering only)
- [x] 12.7 Add sort controls to admin item table and API client
- [x] 12.8 Add `unique_fields` to admin `SchemaDetailResponse` TypeScript type
- [x] 12.9 Add client-side kebab-case validation to schema create form (currently only server-enforced)

## 13. Testing

- [x] 13.1 Add `testcontainers-go` and `testcontainers-go/modules/mysql` dependencies
- [x] 13.2 Create `utils/testdb.go` with `SetupTestDB()` using testcontainers MySQL 8.4
- [x] 13.3 Extract seed schema helpers from `scripts/migration.go` into `utils/test_seed.go`
- [x] 13.4 Add `Reset()` method to `SchemaRegistry` for test isolation
- [x] 13.5 Update CI `test-api` job to ensure Docker is available
- [x] 13.6 Write `ValidationEngine` unit tests (required, length, range, pattern, select/enum, checkbox, unknown schema/field, create vs update)
- [x] 13.7 Write `SchemaRegistry` unit tests (load from DB, get, ordering, refresh, invalidate, exists, field lookup, unique fields parsing, reset)
- [x] 13.8 Write `EAVQueryBuilder` unit tests (pagination, search, EAV filters, has_image, sorting, get item, dual-write create, duplicate rejection, update, unauthorized, delete cascade, impact, field values JSON coercion)
- [x] 13.9 Write schema CRUD integration tests (create, duplicate rejection, kebab-case validation, update, delete empty, reject with items, list, get details, version history)
- [x] 13.10 Write dynamic item CRUD integration tests (create, duplicate rejection, list pagination, get details, update, unauthorized, delete, impact report)
- [x] 13.11 Write filtering and search integration tests (EAV field filter, has_image, search, EAV sort, combined filter+search+sort)

## 14. Documentation

- [x] 14.1 Update API documentation for new endpoints
- [x] 14.2 Create schema management guide for administrators
- [x] 14.3 Update developer documentation for adding new item types
- [x] 14.4 Document migration process for existing deployments
- [x] 14.5 Update README with dynamic schema information

## 15. Deployment

- [x] 15.1 Deploy database migrations to staging
- [x] 15.2 Verify migration on staging with test data
- [x] 15.3 Deploy API changes to staging
- [x] 15.4 Deploy admin changes to staging
- [x] 15.5 Deploy client changes to staging
- [x] 15.6 Run full regression tests on staging
- [x] 15.7 Deploy database migrations to production
- [x] 15.8 Deploy API to production
- [x] 15.9 Deploy admin to production
- [x] 15.10 Deploy client to production
- [x] 15.11 Monitor error rates and performance
- [ ] 15.12 Remove old item type tables after verification
- [ ] 15.13 Remove old API route registrations from `main.go` (old `/api/cheese/*`, `/api/gin/*`, etc.)
- [ ] 15.14 Remove old API models (`cheeseModel.go`, `ginModel.go`, `wineModel.go`, `coffeeModel.go`, `chiliSauceModel.go`, `coffeeEnums.go`, `wineColor.go`)
- [ ] 15.15 Remove old API controllers (`cheeseController.go`, `ginController.go`, `wineController.go`, `coffeeController.go`, `chiliSauceController.go`)
- [ ] 15.16 Remove old model AutoMigrate entries from `database.go`
- [ ] 15.17 Remove old item type switch-case from `item_helper.go`
- [ ] 15.18 Remove old seeding from `seed.go`
- [ ] 15.19 Remove old table drops from `reset_database.go`
- [ ] 15.20 Remove legacy JSON key mapping from `dynamicItemController.go` seed/validate
- [ ] 15.21 Remove old item type hardcoded config from admin `item-types.ts`

## 16. Rating item_type Removal

- [x] 16.1 Change `Rating.ItemType string` to `Rating.Item Item` with FK + CASCADE in `ratingModel.go`
- [x] 16.2 Keep `ItemType` as `gorm:"-"` on Rating struct (prevents AutoMigrate from dropping column prematurely)
- [x] 16.3 Change `Item.Ratings` from `polymorphic:Item` to `foreignKey:ItemID` in `itemModel.go`
- [x] 16.4 Remove `ItemType` from `RatingCreate` request body and rating struct assignment
- [x] 16.5 Remove `itemType` query param and WHERE clause from `RatingByAuthor`
- [x] 16.6 Remove `itemType` query param and WHERE clause from `RatingByViewer`
- [x] 16.7 Change `RatingByItem` route from `/:type/:id` to `/:id`, remove `itemType` from WHERE
- [x] 16.8 Remove `ItemType` from `RatingEdit` request body and `Updates()` call
- [x] 16.9 Change `GetCommunityStats` route from `/community/:type/:id` to `/community/:id`, remove `item_type` from WHERE and response
- [x] 16.10 Remove `item_type = ?` from rating count queries in `query_builder.go:488-492`
- [x] 16.11 Update route registrations in `main.go` for rating and stats endpoints
- [x] 16.12 Remove `item_type` from legacy controller delete operations (cheese, gin, wine, coffee, chili-sauce) — these controllers are deleted in task 15.15 anyway
- [x] 16.13 Remove `itemType` field from `Rating` model in `rating.dart` (fromJson, toJson, toCreateJson, toUpdateJson)
- [x] 16.14 Remove `isCheeseRating` and `displayTitle` extensions that depend on `itemType`
- [x] 16.15 Update `api_config.dart`: `ratingByItem(type, id)` → `ratingByItem(id)`, `communityStats(type, id)` → `communityStats(id)`
- [x] 16.16 Update `rating_service.dart`: remove `itemType` param from `getRatingsByItem()`, `getItemRatingStats()`, `getCheeseRatings()`, `getCheeseRatingStats()`; remove `itemType` validation in `validateRating()`
- [x] 16.17 Update `community_stats_provider.dart`: remove `itemType` from `CommunityStatsParams` and `CommunityStatsMapExtension.itemType` getter
- [x] 16.18 Update `rating_create_screen.dart`: stop passing `itemType` to `createRating()`
- [x] 16.19 Update `rating_provider.dart`: stop passing `itemType` in `createRating()` and `updateRating()`; derive item type from item lookup for cache invalidation in `updateRating()` (line 327) and `deleteRating()` (line 372)
- [x] 16.20 Update `item_type_screen.dart`: replace all `r.itemType == widget.itemType` filters (~20 occurrences) with item ID set membership checks (`cheeseItemIds.contains(r.itemId)`)
- [x] 16.21 Update `api_service.dart`: remove `itemType` param from `getCommunityStats()` and `clearCommunityStatsCache()`
- [x] 16.22 Audit `privacy_settings_screen.dart`, `my_rating_section.dart`, `rateable_item.dart` for `Rating.itemType` references (note: `item.itemType` from RateableItem interface is unaffected)
- [x] 16.23 Verify FK constraint exists: `ratings.item_id → items.id ON DELETE CASCADE`
- [x] 16.24 Verify no orphaned ratings (all `item_id` values exist in `items` table)
- [x] 16.25 Run full test suite: `go test ./...` in API, `flutter test` in client
- [x] 16.26 Manual smoke test: create rating, edit rating, delete item (verify cascade), view community stats
- [ ] 16.27 Drop composite index: `DROP INDEX idx_ratings_item ON ratings`
- [ ] 16.28 Drop column: `ALTER TABLE ratings DROP COLUMN item_type`
- [ ] 16.29 Remove `ItemType` `gorm:"-"` field from Rating struct
- [ ] 16.30 Verify new indexes are in place: `idx_ratings_user_item (user_id, item_id)`, `idx_ratings_item (item_id)`

## 17. Client Pagination & Server-Side Filtering

- [x] 17.1 Create `GetTypeStats` handler in `controllers/dynamicItemController.go` returning `{ total_items, user_rated_count }` for a schema type
- [x] 17.2 Register `GET /api/stats/type/:type` route in `main.go` (stats group, auth-required)
- [x] 17.3 Write controller integration test for `GetTypeStats` (httptest + testcontainers)
- [x] 17.4 Create `PaginatedResponse<T>` model in `models/paginated_response.dart` with fields `items`, `total`, `page`, `perPage`, `totalPages` and `hasMore` getter
- [x] 17.5 Add `page`, `perPage`, `search`, `filters` params to `getItemsByType()` in `DynamicItemService`, build query string, parse full response envelope, return `ApiResponse<PaginatedResponse<DynamicItem>>`
- [x] 17.6 Remove 5-minute TTL cache (`_itemCache`, `_cacheTimestamp`, `_isCacheValid`) from `DynamicItemService` — pagination state is now the source of truth
- [x] 17.7 Add `getTypeStats(String type)` method to `DynamicItemService` calling `GET /api/stats/type/{type}`
- [x] 17.8 Add pagination state fields to `DynamicItemState`: `totalByType`, `currentPageByType`, `totalPagesByType`, `isLoadingMoreByType`, `typeStatsByType`
- [x] 17.9 Add accessor methods to `DynamicItemState`: `totalForType`, `hasMore`, `isLoadingMore`, `typeStats`
- [x] 17.10 Modify `loadItems()` in `DynamicItemNotifier`: fetch page 1, replace items in `itemsByType`, store pagination meta
- [x] 17.11 Add `loadMoreItems(String type)` to `DynamicItemNotifier`: fetch currentPage+1, append items, guard against double-load or no-more
- [x] 17.12 Modify `updateSearchQuery()` in `DynamicItemNotifier`: reset to page 1, trigger API fetch with search + active filters
- [x] 17.13 Modify `setCategoryFilter()` in `DynamicItemNotifier`: reset to page 1, trigger API fetch with all active filters + search
- [x] 17.14 Modify `clearFilters()` in `DynamicItemNotifier`: reset to page 1, fetch page 1 with no filters
- [x] 17.15 Add `loadTypeStats(String type)` to `DynamicItemNotifier`: fetch and store stats
- [x] 17.16 Remove `_refreshFilterOptions()` from `DynamicItemNotifier` — filter options now derived from schema
- [x] 17.17 Remove `getFilteredItems()` from `DynamicItemState` — filtering moves to server
- [x] 17.18 Update `invalidateItem()` / `addItem()` / `updateItemInCache()` in `DynamicItemNotifier` to reset pagination to page 1
- [x] 17.19 Add `hasMore` passthrough to `ItemProviderHelper`
- [x] 17.20 Add `isLoadingMore` passthrough to `ItemProviderHelper`
- [x] 17.21 Add `totalItems` passthrough to `ItemProviderHelper`
- [x] 17.22 Add `loadMoreItems` passthrough to `ItemProviderHelper`
- [x] 17.23 Add `typeStats` passthrough to `ItemProviderHelper`
- [x] 17.24 Add `loadTypeStats` passthrough to `ItemProviderHelper`
- [x] 17.25 Remove `getFilteredItems` passthrough from `ItemProviderHelper`
- [x] 17.26 Add `totalItemsProvider`, `hasMoreProvider`, `isLoadingMoreProvider` family providers
- [x] 17.27 Rewrite `getAvailableFilters()` in `ItemFilterHelper` to accept `ItemSchema` instead of item list, returning select/enum field options
- [x] 17.28 Update callers in `ItemTypeScreen` to pass schema to `ItemFilterHelper.getAvailableFilters()`
- [x] 17.29 Add `ScrollController` to `_ItemTypeScreenState`, dispose in `dispose()`
- [x] 17.30 Attach scroll listener in `ItemTypeScreen`: trigger `loadMoreItems` when within 200px of bottom
- [x] 17.31 Show `CircularProgressIndicator` at bottom of list when `isLoadingMore == true`
- [x] 17.32 Show "All items loaded" text when `!hasMore && items.isNotEmpty`
- [x] 17.33 Apply same `ScrollController` and load-more pattern to `_buildMyListTab()` in `ItemTypeScreen`
- [x] 17.34 Keep `RefreshIndicator` in `ItemTypeScreen`: call `loadItems(type, forceRefresh: true)` to clear and reload page 1
- [x] 17.35 Add `Timer? _searchDebounce` to `ItemTypeScreen` widget state, cancel in `dispose()`
- [x] 17.36 Modify `onSearchChanged` in `ItemTypeScreen`: cancel prior timer, set new 300ms debounce timer calling `updateSearchQuery`
- [x] 17.37 Pass `search` param through to `getItemsByType()` in service layer from `ItemTypeScreen`
- [x] 17.38 Retrieve `ItemSchema` for current type from `schemaForTypeProvider` in `ItemTypeScreen`
- [x] 17.39 Pass active filters through to `getItemsByType()` as `filter[key]=value` query params from `ItemTypeScreen`
- [x] 17.40 Call `dynamicItemProvider.notifier.loadTypeStats(schema.name)` for each active schema on home screen initial load
- [x] 17.41 Replace `dynamicItemState.getItems(schema.name).length` with `typeStats?.totalItems ?? 0` in `home_screen.dart`
- [x] 17.42 Replace `_getUniqueItemCount(ratings, itemType)` with `typeStats?.userRatedCount ?? 0` in `home_screen.dart`
- [x] 17.43 Remove `_getUniqueItemCount()` method entirely from `home_screen.dart`
- [x] 17.44 Remove eager `loadItems()` trigger from `home_screen.dart` `build()` — home screen no longer needs the full item list
- [x] 17.45 Test pagination: verify `hasMore`, `loadMoreItems` appends correctly, pull-to-refresh resets
- [x] 17.46 Test debounced search: rapid typing fires single request after 300ms
- [x] 17.47 Test filter + pagination interplay: applying filter resets to page 1, filter options come from schema
- [x] 17.48 Test home screen: stats load once, item counts display correctly, pull-to-refresh refreshes stats
- [x] 17.49 Test error handling: network error during `loadMoreItems` preserves existing items and state
- [x] 17.50 Test empty states: search/filter with no results shows empty state, `hasMore` is false
- [x] 17.51 Test inventory update: creating/deleting an item resets pagination to page 1

## 18. Schema Refresh on Item List Pull-to-Refresh

- [ ] 18.1 Add `ref.read(schemaProvider.notifier).refreshSchema(widget.itemType)` to all pull-to-refresh callbacks in `item_type_screen.dart`:
  - _buildAllItemsTab
  - _buildMyListTab — personal rating_source
  - _buildMyListTab — recommendations rating_source
  - _buildMyListTab — no rating_source filter
- [ ] 18.2 Manual test: modify schema in admin, pull-to-refresh on item list, verify schema updates without returning to home screen

## 19. Personal Items Data Source

### Backend (API)

- [ ] 19.1 Add `Rated bool` field to `QueryParams` struct in `services/query_builder.go`
- [ ] 19.2 Add `RatedByUserID int` field to `QueryParams` struct (set by controller from JWT when `Rated` is true)
- [ ] 19.3 Implement `rated` subquery filter in `BuildListQuery`: when `Rated` is true, filter items to those where user has a rating (author OR viewer via rating_viewers join), excluding soft-deleted ratings
- [ ] 19.4 Parse `?rated=true` in `DynamicItemList` controller, extract user ID from JWT, set `params.Rated = true` and `params.RatedByUserID = <jwt_user_id>` — silently ignore if unauthenticated
- [ ] 19.5 Write `TestEAVQueryBuilder_RatedBy` in `services/query_builder_test.go`: create items with/without ratings, verify `Rated=true` returns only rated, verify viewer-shared items included, verify pagination within subset
- [ ] 19.6 Write `TestDynamicItemList_RatedBy` in `controllers/dynamic_item_controller_test.go`: integration test via httptest, verify auth required, verify correct items returned

### Client Service

- [ ] 19.7 Add optional `bool rated = false` parameter to `DynamicItemService.getItemsByType()`, append `rated=true` to query params when set

### Client Provider

- [ ] 19.8 Add user-rated state fields to `DynamicItemState`: `userRatedItemsByType`, `userRatedLoadingByType`, `userRatedCurrentPageByType`, `userRatedTotalPagesByType`, `userRatedTotalByType`, `userRatedIsLoadingMoreByType` with defaults, copyWith, and accessors
- [ ] 19.9 Add `loadUserRatedItems(String type)` to `DynamicItemNotifier`: call `getItemsByType(type, rated: true, page: 1)`, store in user-rated maps
- [ ] 19.10 Add `loadMoreUserRatedItems(String type)` to `DynamicItemNotifier`: fetch next page, append, guard against double-load/no-more
- [ ] 19.11 Add `refreshUserRatedItems(String type)` to `DynamicItemNotifier`: force-refresh user-rated items from page 1
- [ ] 19.12 Add user-rated convenience methods to `ItemProviderHelper`: `getUserRatedItems`, `userRatedHasMore`, `userRatedIsLoadingMore`, `userRatedTotalItems`, `loadUserRatedItems`, `loadMoreUserRatedItems`, `refreshUserRatedItems`
- [ ] 19.13 Add user-rated family providers: `userRatedItemsForTypeProvider`, `userRatedHasMoreProvider`, `userRatedIsLoadingMoreProvider`

### Client UI

- [ ] 19.14 Add separate `ScrollController _myListScrollController` to `_ItemTypeScreenState`, attach scroll listener in initState, dispose in dispose
- [ ] 19.15 Add `_onMyListScroll()` listener triggering `ItemProviderHelper.loadMoreUserRatedItems(ref, widget.itemType)` at 200px threshold
- [ ] 19.16 Update `_buildMyListTab` to read from `userRatedItems` instead of `itemsByType`
- [ ] 19.17 Replace plain `ListView` in My List with `ListView.builder` using `_myListScrollController` and load-more indicator
- [ ] 19.18 Trigger `loadUserRatedItems` on My List tab activation (tab change listener or initState)
- [ ] 19.19 Add loading, empty, and error states to My List user-rated data path
- [ ] 19.20 Update My List pull-to-refresh handlers to call `refreshUserRatedItems` alongside ratings refresh and schema refresh
- [ ] 19.21 Manual smoke test: rate items A, B, Z in 100-item catalog, verify all 3 visible in My List on first load