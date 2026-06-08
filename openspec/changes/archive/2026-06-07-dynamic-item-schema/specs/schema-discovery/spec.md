# schema-discovery Specification

## Purpose

Provide API endpoints for clients to discover available item type schemas at runtime. This enables the Flutter client to dynamically render forms and displays based on server-defined schemas without code changes.

## ADDED Requirements

### Requirement: List Available Schemas

The system SHALL provide an endpoint to list all active schemas available for item creation.

#### Scenario: Client fetches schema list

- **GIVEN** multiple schemas exist (cheese, gin, wine, coffee, chili-sauce)
- **AND** schema "seasonal" is inactive
- **WHEN** the client requests GET /api/schemas
- **THEN** the system SHALL return an array of schema summaries:
  ```json
  [
    {"name": "cheese", "display_name": "Cheese", "plural_name": "Cheeses", "icon": "Pizza", "color": "#673AB7"},
    {"name": "gin", "display_name": "Gin", "plural_name": "Gins", "icon": "GlassWater", "color": "#009688"},
    ...
  ]
  ```
- **AND** inactive schemas SHALL NOT be included

#### Scenario: Schema list includes item counts

- **GIVEN** the client requests schema list with include_counts=true
- **WHEN** the client requests GET /api/schemas?include_counts=true
- **THEN** each schema SHALL include an item_count field
- **AND** the count SHALL reflect only active (non-deleted) items

### Requirement: Get Schema Details

The system SHALL provide an endpoint to retrieve complete schema details including all field definitions.

#### Scenario: Client fetches schema details

- **GIVEN** schema "beer" exists with fields: name, brewery, style, abv, description
- **WHEN** the client requests GET /api/schemas/beer
- **THEN** the system SHALL return:
  ```json
  {
    "name": "beer",
    "display_name": "Beer",
    "plural_name": "Beers",
    "icon": "Beer",
    "color": "#FFA000",
    "unique_fields": ["producer", "type"],
    "version": 2,
    "version_hash": "a1b2c3d4",
    "versions": [
      {"id": 1, "version": 1, "fields": [...], "is_active": false, "created_at": "2024-01-15T10:00:00Z"},
      {"id": 2, "version": 2, "fields": [...], "is_active": true,  "created_at": "2024-01-20T14:30:00Z"}
    ],
    "fields": [
      {
        "key": "name",
        "label": "Name",
        "type": "text",
        "required": true,
        "order": 1,
        "validation": {"maxLength": 100},
        "display": {"badge": false, "primary": true, "secondary": false}
      },
      ...
    ]
  }
  ```

#### Scenario: Client fetches non-existent schema

- **GIVEN** no schema with name "whiskey" exists
- **WHEN** the client requests GET /api/schemas/whiskey
- **THEN** the system SHALL return a 404 error

### Requirement: Schema Response Includes Validation Rules

The system SHALL include validation rules in schema responses for client-side validation.

#### Scenario: Schema includes validation rules

- **GIVEN** schema "wine" has a field "vintage" with min=1900, max=2100
- **WHEN** the client fetches the schema
- **THEN** the field SHALL include:
  ```json
  {
    "key": "vintage",
    "validation": {"min": 1900, "max": 2100}
  }
  ```

### Requirement: Schema Response Includes Display Hints

The system SHALL include display hints in schema responses for UI rendering.

#### Scenario: Schema includes display configuration

- **GIVEN** schema "coffee" has fields with various display settings
- **WHEN** the client fetches the schema
- **THEN** each field SHALL include display hints:
  ```json
  {
    "display": {
      "badge": false,
      "primary": false,
      "secondary": false
    }
  }
  ```

### Requirement: Schema Response Includes Select Options

The system SHALL include available options for select and enum field types.

#### Scenario: Schema includes select options

- **GIVEN** schema "beer" has field "style" with options ["IPA", "Stout", "Pilsner", "Lager"]
- **WHEN** the client fetches the schema
- **THEN** the field SHALL include:
  ```json
  {
    "key": "style",
    "type": "select",
    "options": [
      {"value": "IPA", "label": "IPA"},
      {"value": "Stout", "label": "Stout"},
      ...
    ]
  }
  ```

### Requirement: Schema Caching Headers

The system SHALL provide appropriate caching headers for schema responses.

#### Scenario: Schema response includes cache headers

- **WHEN** the client fetches any schema
- **THEN** the response SHALL include:
  - `Cache-Control: public, max-age=300` (5 minutes)
  - `ETag: <schema-version-hash>`
- **AND** the client MAY use If-None-Match for conditional requests

#### Scenario: Client uses conditional request

- **GIVEN** the client has a cached schema with ETag "abc123"
- **WHEN** the client requests GET /api/schemas/beer with header `If-None-Match: abc123`
- **AND** the schema has not changed
- **THEN** the system SHALL return 304 Not Modified

### Requirement: Schema Versioning in Response

The system SHALL include schema version information in responses for cache invalidation.

#### Scenario: Schema response includes version

- **WHEN** the client fetches any schema
- **THEN** the response SHALL include:
  ```json
  {
    "version": 2,
    "version_hash": "a1b2c3d4"
  }
  ```
- **AND** the version SHALL increment when fields are added, removed, or modified

### Requirement: Authenticated vs Public Schema Access

The system SHALL provide different schema visibility based on authentication status.

#### Scenario: Unauthenticated user accesses schemas

- **GIVEN** no authentication is provided
- **WHEN** the user requests GET /api/schemas
- **THEN** the system SHALL return only active schemas
- **AND** the response SHALL NOT include admin-only metadata

#### Scenario: Authenticated user accesses schemas

- **GIVEN** a user is authenticated
- **WHEN** the user requests GET /api/schemas
- **THEN** the system SHALL return active schemas
- **AND** the response MAY include user-specific metadata (e.g., item counts for user)

### Requirement: Schema Field Groups

The system SHALL support grouping fields for organized display in forms.

#### Scenario: Schema includes field groups

- **GIVEN** schema "wine" has fields grouped as "Basic Info" and "Details"
- **WHEN** the client fetches the schema
- **THEN** fields SHALL include a group property:
  ```json
  {
    "key": "grape",
    "group": "Basic Info"
  }
  ```
- **AND** the client MAY render fields grouped by this property

## API Endpoints

### List Schemas

```
GET /api/schemas
Query params:
  - include_counts: boolean (default: false)
  - include_inactive: boolean (default: false, admin only)

Response: 200 OK
{
  "schemas": [
    {
      "name": "cheese",
      "display_name": "Cheese",
      "plural_name": "Cheeses",
      "icon": "Pizza",
      "color": "#673AB7",
      "item_count": 42
    }
  ]
}
```

### Get Schema

```
GET /api/schemas/:type
Query params:
  - version: integer (optional, defaults to latest active)

Response: 200 OK
{
  "name": "cheese",
  "display_name": "Cheese",
  "plural_name": "Cheeses",
  "icon": "Pizza",
  "color": "#673AB7",
  "version": 2,
  "version_hash": "a1b2c3d4",
  "unique_fields": ["name"],
  "versions": [
    {"id": 1, "version": 1, "fields": [...], "is_active": false, "created_at": "2024-01-15T10:00:00Z"},
    {"id": 2, "version": 2, "fields": [...], "is_active": true,  "created_at": "2024-01-20T14:30:00Z"}
  ],
  "fields": [...]
}
```

### Get Schema Version (Admin)

```
GET /admin/schemas/:type/versions/:version

Response: 200 OK
{
  "version": 1,
  "fields": [...],
  "created_at": "2024-01-15T10:00:00Z",
  "migrated_at": null
}
```

### Get Type Stats

```
GET /api/stats/type/:type
Authorization: required

Response: 200 OK
{
  "total_items": 150,
  "user_rated_count": 42
}
```

## ADDED Requirements (Pagination Support)

### Requirement: Type Stats Endpoint

The system SHALL provide an endpoint returning item count and user-rated count for a given schema type.

#### Scenario: Authenticated user requests type stats

- **GIVEN** schema "cheese" has 150 total items
- **AND** the authenticated user has rated 42 distinct cheese items
- **WHEN** the user requests GET /api/stats/type/cheese
- **THEN** the system SHALL return `{ "total_items": 150, "user_rated_count": 42 }`

#### Scenario: Stats for empty type

- **GIVEN** schema "beer" has 0 items
- **WHEN** the user requests GET /api/stats/type/beer
- **THEN** the system SHALL return `{ "total_items": 0, "user_rated_count": 0 }`

#### Scenario: Unauthenticated request denied

- **GIVEN** no valid auth token
- **WHEN** the user requests GET /api/stats/type/cheese
- **THEN** the system SHALL return 401 Unauthorized

#### Scenario: Stats for unknown type

- **GIVEN** no schema exists with name "nonexistent"
- **WHEN** the user requests GET /api/stats/type/nonexistent
- **THEN** the system SHALL return 404 Not Found

### Requirement: Schema Fields Provide Filter Options

Schema select and enum field definitions SHALL be used by the Flutter client as the source of truth for filter option values, replacing the prior approach of scanning loaded items.

#### Scenario: Client uses schema for filter chip options

- **GIVEN** schema "cheese" has field "milk_type" (enum) with options ["Cow", "Goat", "Sheep", "Buffalo"]
- **WHEN** the Flutter client builds the cheese listing filter UI
- **THEN** the filter chip options SHALL be ["Cow", "Goat", "Sheep", "Buffalo"]
- **AND** the client SHALL NOT scan loaded items to derive these options

#### Scenario: Schema field options are authoritative

- **GIVEN** schema "gin" has field "style" (select) with options ["London Dry", "Old Tom", "Plymouth"]
- **AND** only "London Dry" gins exist in the first page of results
- **WHEN** the Flutter client builds the gin listing filter UI
- **THEN** all three options SHALL be displayed ("London Dry", "Old Tom", "Plymouth")
- **AND** the filter SHALL work correctly when "Old Tom" is selected (server-side filter, not client-side)
