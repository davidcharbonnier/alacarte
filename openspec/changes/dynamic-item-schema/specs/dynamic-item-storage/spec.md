# dynamic-item-storage Specification

## Purpose

Provide an Entity-Attribute-Value (EAV) based storage system that can store items of any schema type. Each item's field values are stored as separate records, enabling flexible schema evolution without database migrations.

## ADDED Requirements

### Requirement: Create Dynamic Item

The system SHALL allow authenticated users to create items of any active schema type with field values matching the schema definition.

#### Scenario: User creates an item with valid fields

- **GIVEN** a user is authenticated
- **AND** a schema "beer" exists with fields: name (required), brewery (required), style (select), abv (number)
- **WHEN** the user creates an item with:
  - name: "Hoppy Heaven IPA"
  - brewery: "Mountain Brew Co"
  - style: "IPA"
  - abv: 7.5
- **THEN** the system SHALL create the item record
- **AND** the system SHALL create field value records for each field
- **AND** the item SHALL be retrievable with all field values

#### Scenario: System rejects item with missing required fields

- **GIVEN** a user is authenticated
- **AND** a schema "beer" exists with required field "name"
- **WHEN** the user creates an item without providing "name"
- **THEN** the system SHALL reject the creation
- **AND** the system SHALL return a validation error for the "name" field

#### Scenario: System rejects item for inactive schema

- **GIVEN** a user is authenticated
- **AND** a schema "seasonal" is inactive
- **WHEN** the user attempts to create an item of type "seasonal"
- **THEN** the system SHALL reject the creation
- **AND** the system SHALL return an error indicating the schema is not available

### Requirement: Retrieve Dynamic Item

The system SHALL allow users to retrieve items by ID with all field values hydrated into a structured format.

#### Scenario: User retrieves an item

- **GIVEN** an item with ID 42 exists for schema "wine"
- **WHEN** the user requests GET /api/items/wine/42
- **THEN** the system SHALL return the item with:
  - id: 42
  - schema_type: "wine"
  - name: "Château Margaux"
  - All field values keyed by field key
  - image_url (if present)
  - created_at, updated_at timestamps

#### Scenario: User retrieves non-existent item

- **GIVEN** no item with ID 999 exists
- **WHEN** the user requests GET /api/items/wine/999
- **THEN** the system SHALL return a 404 error

### Requirement: List Dynamic Items

The system SHALL allow users to list items of a specific schema type with pagination and sorting.

#### Scenario: User lists items with default pagination

- **GIVEN** schema "coffee" has 150 items
- **WHEN** the user requests GET /api/items/coffee
- **THEN** the system SHALL return the first 20 items
- **AND** the response SHALL include pagination metadata (total, page, per_page)
- **AND** items SHALL be sorted by primary field ascending by default

#### Scenario: User lists items with custom pagination

- **GIVEN** schema "coffee" has 150 items
- **WHEN** the user requests GET /api/items/coffee?page=3&per_page=50
- **THEN** the system SHALL return items 101-150
- **AND** the response SHALL indicate page=3, per_page=50, total=150

#### Scenario: User lists items with sorting

- **GIVEN** schema "gin" has multiple items
- **WHEN** the user requests GET /api/items/gin?sort=-created_at
- **THEN** the system SHALL return items sorted by created_at descending

### Requirement: Search Dynamic Items

The system SHALL allow users to search items by field values.

#### Scenario: User searches by name

- **GIVEN** schema "wine" has items with names "Château Margaux", "Opus One", "Penfolds"
- **WHEN** the user requests GET /api/items/wine?search=margaux
- **THEN** the system SHALL return items where name contains "margaux" (case-insensitive)
- **AND** the search SHALL apply to all searchable fields defined in the schema

#### Scenario: User searches across multiple fields

- **GIVEN** schema "gin" has searchable fields: name, producer
- **AND** items exist with:
  - name: "Hendrick's", producer: "William Grant"
  - name: "Tanqueray", producer: "Diageo"
- **WHEN** the user requests GET /api/items/gin?search=grant
- **THEN** the system SHALL return the Hendrick's item (producer matches)

### Requirement: Filter Dynamic Items

The system SHALL allow users to filter items by specific field values.

#### Scenario: User filters by select field

- **GIVEN** schema "beer" has field "style" with options ["IPA", "Stout", "Pilsner"]
- **AND** items exist with various styles
- **WHEN** the user requests GET /api/items/beer?filter[style]=IPA
- **THEN** the system SHALL return only items where style equals "IPA"

#### Scenario: User filters by multiple fields

- **GIVEN** schema "coffee" has fields "roast_level" and "origin"
- **WHEN** the user requests GET /api/items/coffee?filter[roast_level]=dark&filter[origin]=Ethiopia
- **THEN** the system SHALL return items matching both filters

#### Scenario: User filters by picture presence

- **GIVEN** schema "cheese" has items with and without images
- **WHEN** the user requests GET /api/items/cheese?filter[has_image]=true
- **THEN** the system SHALL return only items where image_url is not null

### Requirement: Update Dynamic Item

The system SHALL allow users to update items they created.

#### Scenario: User updates field values

- **GIVEN** a user created an item with ID 42
- **AND** the item has field values: name="Old Name", description="Old description"
- **WHEN** the user updates the item with: name="New Name"
- **THEN** the system SHALL update the name field value
- **AND** the description field value SHALL remain unchanged
- **AND** the updated_at timestamp SHALL be updated

#### Scenario: User cannot update another user's item

- **GIVEN** user A created item with ID 42
- **AND** user B is authenticated
- **WHEN** user B attempts to update item 42
- **THEN** the system SHALL reject the update
- **AND** the system SHALL return a 403 Forbidden error

### Requirement: Delete Dynamic Item

The system SHALL allow users to delete items they created.

#### Scenario: User deletes their item

- **GIVEN** a user created an item with ID 42
- **WHEN** the user requests DELETE /api/items/beer/42
- **THEN** the system SHALL soft-delete the item
- **AND** the item SHALL no longer appear in listings
- **AND** associated ratings SHALL be cascade deleted

#### Scenario: Delete cascade removes field values

- **GIVEN** an item with ID 42 has 10 field value records
- **WHEN** the item is deleted
- **THEN** all associated field value records SHALL be deleted

### Requirement: Upload Item Image

The system SHALL allow users to upload and associate images with items.

#### Scenario: User uploads an image

- **GIVEN** a user created an item with ID 42
- **WHEN** the user uploads an image file
- **THEN** the system SHALL process and store the image
- **AND** the item's image_url SHALL be updated
- **AND** the image SHALL be displayed in item detail views

#### Scenario: User replaces existing image

- **GIVEN** an item has an existing image
- **WHEN** the user uploads a new image
- **THEN** the system SHALL replace the existing image
- **AND** the old image SHALL be deleted from storage

### Requirement: Admin Bulk Delete

The system SHALL allow administrators to delete items with impact assessment.

#### Scenario: Admin views delete impact

- **GIVEN** an administrator is authenticated
- **AND** an item with ID 42 has 25 ratings
- **WHEN** the administrator requests GET /admin/items/wine/42/delete-impact
- **THEN** the system SHALL return:
  - Number of ratings to be deleted: 25
  - Number of unique users affected: 18

#### Scenario: Admin force deletes item

- **GIVEN** an administrator is authenticated
- **WHEN** the administrator deletes an item with force=true
- **THEN** the system SHALL delete the item regardless of ownership
- **AND** all associated data SHALL be cascade deleted

## Data Model

### Item Entity

```
Item {
  id: integer (auto-generated)
  schema_id: integer (foreign key to ItemTypeSchema)
  name: string (max 255, indexed)
  description: text (optional)
  image_url: string (optional, nullable)
  user_id: integer (foreign key to User)
  created_at: timestamp
  updated_at: timestamp
  deleted_at: timestamp (soft delete)
}

Index: (schema_id, name)
Index: (user_id)
```

### Item Field Value Entity

```
ItemFieldValue {
  id: integer (auto-generated)
  item_id: integer (foreign key to Item, cascade delete)
  field_id: integer (foreign key to ItemTypeField)
  value: text (stored as string, cast by type)
  created_at: timestamp
  updated_at: timestamp
}

Unique constraint: (item_id, field_id)
Index: (field_id, value) -- for filtering
```

### EAV Query Optimization

For performant queries on EAV data:
1. Index `(field_id, value)` for filtered searches
2. Use materialized views for common queries
3. Cache schema definitions in memory
4. Consider denormalized search tables for large datasets
