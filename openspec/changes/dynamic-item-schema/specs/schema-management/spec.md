# schema-management Specification

## Purpose

Enable administrators to define, edit, version, and delete item type schemas through the admin panel. Schemas define the structure of consumable items (cheese, gin, wine, etc.) including field definitions, validation rules, and display hints.

## ADDED Requirements

### Requirement: Create Item Type Schema

The system SHALL allow administrators to create new item type schemas with a unique name, display labels, icon, color, and field definitions.

#### Scenario: Administrator creates a new schema

- **GIVEN** an administrator is authenticated
- **AND** the administrator navigates to the schema management page
- **WHEN** the administrator creates a schema with:
  - Name: "beer"
  - Singular label: "Beer"
  - Plural label: "Beers"
  - Icon: "Beer"
  - Color: "#FFA000"
- **THEN** the system SHALL create the schema record
- **AND** the system SHALL assign version 1 to the schema
- **AND** the schema SHALL be available for item creation immediately

#### Scenario: Schema name must be unique

- **GIVEN** an administrator is authenticated
- **AND** a schema with name "wine" already exists
- **WHEN** the administrator attempts to create another schema with name "wine"
- **THEN** the system SHALL reject the creation
- **AND** the system SHALL display an error indicating the name is already in use

#### Scenario: Schema name must be kebab-case

- **GIVEN** an administrator is authenticated
- **WHEN** the administrator attempts to create a schema with name "Red Wine"
- **THEN** the system SHALL reject the creation
- **AND** the system SHALL display an error indicating the name must be lowercase kebab-case

### Requirement: Define Schema Fields

The system SHALL allow administrators to define fields for each schema including key, label, type, validation rules, and display hints.

#### Scenario: Administrator adds a text field

- **GIVEN** an administrator is editing a schema
- **WHEN** the administrator adds a field with:
  - Key: "brewery"
  - Label: "Brewery"
  - Type: "text"
  - Required: true
  - Max length: 100
- **THEN** the system SHALL save the field definition
- **AND** the field SHALL appear in the schema's field list

#### Scenario: Administrator adds a select field with options

- **GIVEN** an administrator is editing a schema
- **WHEN** the administrator adds a field with:
  - Key: "style"
  - Label: "Beer Style"
  - Type: "select"
  - Options: ["IPA", "Stout", "Pilsner", "Lager", "Ale"]
- **THEN** the system SHALL save the field with options
- **AND** the options SHALL be available for selection in forms

#### Scenario: Administrator adds a number field with constraints

- **GIVEN** an administrator is editing a schema
- **WHEN** the administrator adds a field with:
  - Key: "abv"
  - Label: "ABV %"
  - Type: "number"
  - Min: 0
  - Max: 100
- **THEN** the system SHALL save the field with constraints
- **AND** the constraints SHALL be enforced during validation

#### Scenario: Field key must be unique within schema

- **GIVEN** an administrator is editing a schema
- **AND** the schema has a field with key "name"
- **WHEN** the administrator attempts to add another field with key "name"
- **THEN** the system SHALL reject the addition
- **AND** the system SHALL display an error indicating duplicate field key

### Requirement: Reorder Schema Fields

The system SHALL allow administrators to reorder fields within a schema to control display order.

#### Scenario: Administrator reorders fields

- **GIVEN** an administrator is editing a schema
- **AND** the schema has fields in order: name, brewery, style
- **WHEN** the administrator drags "style" to position 2
- **THEN** the field order SHALL be updated to: name, style, brewery
- **AND** the new order SHALL be reflected in forms and detail views

### Requirement: Edit Schema Fields

The system SHALL allow administrators to modify existing field definitions.

#### Scenario: Administrator modifies field label

- **GIVEN** an administrator is editing a schema
- **AND** the schema has a field with key "abv" and label "ABV"
- **WHEN** the administrator changes the label to "Alcohol By Volume"
- **THEN** the system SHALL update the field label
- **AND** existing items SHALL display the new label

#### Scenario: Administrator marks optional field as required

- **GIVEN** an administrator is editing a schema
- **AND** the schema has an optional field "description"
- **WHEN** the administrator marks the field as required
- **THEN** the system SHALL update the field to required
- **AND** new items SHALL require the field
- **AND** existing items without the field SHALL remain valid

### Requirement: Delete Schema Fields

The system SHALL allow administrators to remove fields from schemas.

#### Scenario: Administrator deletes a field

- **GIVEN** an administrator is editing a schema
- **AND** the schema has a field "notes"
- **WHEN** the administrator deletes the field
- **THEN** the system SHALL remove the field definition
- **AND** existing field values SHALL be preserved in the database
- **AND** the field SHALL no longer appear in forms or detail views

### Requirement: Schema Versioning

The system SHALL track schema versions to support safe migrations and backward compatibility.

#### Scenario: Schema version increments on field changes

- **GIVEN** a schema exists at version 1
- **WHEN** an administrator adds a new field
- **THEN** the system SHALL create version 2
- **AND** version 1 SHALL remain accessible for historical reference

#### Scenario: Administrator views schema history

- **GIVEN** a schema has multiple versions
- **WHEN** the administrator views the schema history
- **THEN** the system SHALL display all versions with timestamps
- **AND** the system SHALL show what changed between versions

### Requirement: Delete Schema

The system SHALL allow administrators to delete schemas that have no associated items.

#### Scenario: Administrator deletes empty schema

- **GIVEN** an administrator is authenticated
- **AND** a schema "test-type" exists with no items
- **WHEN** the administrator deletes the schema
- **THEN** the system SHALL remove the schema and all field definitions
- **AND** the schema SHALL no longer appear in listings

#### Scenario: Cannot delete schema with items

- **GIVEN** an administrator is authenticated
- **AND** a schema "wine" has 150 items
- **WHEN** the administrator attempts to delete the schema
- **THEN** the system SHALL reject the deletion
- **AND** the system SHALL display an error indicating items exist
- **AND** the system SHALL suggest deleting items first or deactivating the schema

### Requirement: Deactivate Schema

The system SHALL allow administrators to deactivate schemas without deleting them.

#### Scenario: Administrator deactivates a schema

- **GIVEN** an administrator is authenticated
- **AND** a schema "seasonal-special" exists
- **WHEN** the administrator deactivates the schema
- **THEN** the schema SHALL be marked as inactive
- **AND** the schema SHALL NOT appear in client discovery
- **AND** existing items SHALL remain accessible
- **AND** new items SHALL NOT be creatable for inactive schemas

### Requirement: Set Primary and Secondary Display Fields

The system SHALL allow administrators to designate which fields are used for primary and secondary display in listings.

#### Scenario: Administrator sets primary display field

- **GIVEN** an administrator is editing a schema
- **WHEN** the administrator marks the "name" field as primary
- **THEN** the name field SHALL be used as the main title in item cards
- **AND** only one field SHALL be marked as primary

#### Scenario: Administrator sets secondary display field

- **GIVEN** an administrator is editing a schema
- **WHEN** the administrator marks the "brewery" field as secondary
- **THEN** the brewery field SHALL be used as the subtitle in item cards
- **AND** only one field SHALL be marked as secondary

## Data Model

### Schema Entity

```
ItemTypeSchema {
  id: integer (auto-generated)
  name: string (unique, kebab-case, max 50)
  display_name: string (max 100)
  plural_name: string (max 100)
  icon: string (Lucide icon name, max 50)
  color: string (hex color, max 7)
  is_active: boolean (default true)
  created_at: timestamp
  updated_at: timestamp
  deleted_at: timestamp (soft delete)
}
```

### Field Entity

```
ItemTypeField {
  id: integer (auto-generated)
  schema_id: integer (foreign key)
  key: string (max 50)
  label: string (max 100)
  field_type: enum (text, textarea, number, select, checkbox, enum)
  required: boolean (default false)
  order: integer
  group: string (optional, max 50)
  validation: JSON (validation rules)
  display: JSON (display hints)
  options: JSON (for select/enum types)
  created_at: timestamp
  updated_at: timestamp
}

Unique constraint: (schema_id, key)
```

### Version Entity

```
SchemaVersion {
  id: integer (auto-generated)
  schema_id: integer (foreign key)
  version: integer
  fields: JSON (snapshot of fields)
  is_active: boolean
  migrated_at: timestamp (nullable)
  created_at: timestamp
}

Unique constraint: (schema_id, version)
```

### Field Types

| Type | Description | Validation Options |
|------|-------------|-------------------|
| text | Single-line text | maxLength, minLength, pattern |
| textarea | Multi-line text | maxLength, minLength |
| number | Numeric value | min, max |
| select | Single selection | options (array) |
| checkbox | Boolean | none |
| enum | Enumerated values | options (array) |

### Validation Rules Schema

```json
{
  "maxLength": 100,
  "minLength": 1,
  "min": 0,
  "max": 100,
  "pattern": "^[a-zA-Z]+$"
}
```

### Display Hints Schema

```json
{
  "component": "text-field",
  "width": "full",
  "hideInList": false,
  "hideInDetail": false,
  "hideInForm": false,
  "primary": false,
  "secondary": false
}
```
