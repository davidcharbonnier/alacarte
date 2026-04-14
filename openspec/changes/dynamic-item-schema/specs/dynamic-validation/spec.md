# dynamic-validation Specification

## Purpose

Provide server-side validation that enforces rules defined in schema definitions. This ensures data integrity regardless of client and provides a single source of truth for validation logic.

## ADDED Requirements

### Requirement: Validate Required Fields

The system SHALL reject items that are missing required field values.

#### Scenario: Missing required field

- **GIVEN** schema "beer" has required field "name"
- **WHEN** a user creates an item without providing "name"
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return error:
  ```json
  {
    "field": "name",
    "code": "required",
    "message": "Name is required"
  }
  ```

#### Scenario: Empty string fails required check

- **GIVEN** schema "wine" has required field "producer"
- **WHEN** a user provides producer as empty string ""
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return a required validation error

#### Scenario: Whitespace-only string fails required check

- **GIVEN** schema "cheese" has required field "name"
- **WHEN** a user provides name as "   " (whitespace only)
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return a required validation error

### Requirement: Validate String Length

The system SHALL enforce maximum and minimum length constraints on text fields.

#### Scenario: Exceeds maximum length

- **GIVEN** schema "gin" has field "description" with maxLength=500
- **WHEN** a user provides a description of 600 characters
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return error:
  ```json
  {
    "field": "description",
    "code": "max_length",
    "message": "Description must be at most 500 characters",
    "details": {"max": 500, "actual": 600}
  }
  ```

#### Scenario: Below minimum length

- **GIVEN** schema "coffee" has field "name" with minLength=2
- **WHEN** a user provides name as "A"
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return a min_length validation error

### Requirement: Validate Numeric Range

The system SHALL enforce minimum and maximum constraints on number fields.

#### Scenario: Below minimum value

- **GIVEN** schema "beer" has field "abv" with min=0
- **WHEN** a user provides abv as -1
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return error:
  ```json
  {
    "field": "abv",
    "code": "min_value",
    "message": "ABV must be at least 0",
    "details": {"min": 0, "actual": -1}
  }
  ```

#### Scenario: Exceeds maximum value

- **GIVEN** schema "chili-sauce" has field "scoville" with max=10000000
- **WHEN** a user provides scoville as 15000000
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return a max_value validation error

### Requirement: Validate Pattern Match

The system SHALL enforce regex pattern constraints on text fields.

#### Scenario: Pattern validation fails

- **GIVEN** schema "wine" has field "vintage" with pattern="^\\d{4}$"
- **WHEN** a user provides vintage as "2020-2021"
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return error:
  ```json
  {
    "field": "vintage",
    "code": "pattern",
    "message": "Vintage must be a valid year",
    "details": {"pattern": "^\\d{4}$"}
  }
  ```

#### Scenario: Pattern validation passes

- **GIVEN** schema "wine" has field "vintage" with pattern="^\\d{4}$"
- **WHEN** a user provides vintage as "2020"
- **THEN** the system SHALL accept the value

### Requirement: Validate Select Options

The system SHALL reject values that are not in the defined options for select and enum fields.

#### Scenario: Invalid select option

- **GIVEN** schema "beer" has field "style" with options ["IPA", "Stout", "Pilsner"]
- **WHEN** a user provides style as "Lager"
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return error:
  ```json
  {
    "field": "style",
    "code": "invalid_option",
    "message": "Style must be one of: IPA, Stout, Pilsner",
    "details": {"allowed": ["IPA", "Stout", "Pilsner"], "actual": "Lager"}
  }
  ```

#### Scenario: Valid select option

- **GIVEN** schema "beer" has field "style" with options ["IPA", "Stout", "Pilsner"]
- **WHEN** a user provides style as "IPA"
- **THEN** the system SHALL accept the value

### Requirement: Validate Field Type

The system SHALL reject values that do not match the expected field type.

#### Scenario: Number field receives string

- **GIVEN** schema "coffee" has field "altitude" of type "number"
- **WHEN** a user provides altitude as "high"
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return error:
  ```json
  {
    "field": "altitude",
    "code": "type_mismatch",
    "message": "Altitude must be a number",
    "details": {"expected": "number", "actual": "string"}
  }
  ```

#### Scenario: Checkbox field receives non-boolean

- **GIVEN** schema "wine" has field "organic" of type "checkbox"
- **WHEN** a user provides organic as "yes"
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return a type_mismatch error

### Requirement: Validate Unknown Fields

The system SHALL reject items with fields not defined in the schema.

#### Scenario: Unknown field provided

- **GIVEN** schema "cheese" has fields: name, type, origin
- **WHEN** a user provides an additional field "age_months"
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return error:
  ```json
  {
    "field": "age_months",
    "code": "unknown_field",
    "message": "Field 'age_months' is not defined in schema 'cheese'"
  }
  ```

### Requirement: Multiple Validation Errors

The system SHALL return all validation errors in a single response.

#### Scenario: Multiple fields invalid

- **GIVEN** schema "beer" has:
  - name (required, maxLength=100)
  - abv (min=0, max=100)
- **WHEN** a user provides:
  - name: "" (empty)
  - abv: 150 (exceeds max)
- **THEN** the system SHALL reject the request
- **AND** the system SHALL return:
  ```json
  {
    "errors": [
      {"field": "name", "code": "required", "message": "Name is required"},
      {"field": "abv", "code": "max_value", "message": "ABV must be at most 100"}
    ]
  }
  ```

### Requirement: Validation on Update

The system SHALL validate items on update, considering partial updates.

#### Scenario: Partial update validation

- **GIVEN** an item exists with valid field values
- **AND** schema "wine" has field "vintage" with min=1900
- **WHEN** a user updates only the vintage field to "1800"
- **THEN** the system SHALL validate only the provided field
- **AND** the system SHALL reject if validation fails

#### Scenario: Update preserves existing valid values

- **GIVEN** an item exists with name="Valid Name"
- **AND** schema "beer" has name as required
- **WHEN** a user updates the description field without providing name
- **THEN** the system SHALL NOT require name to be provided again
- **AND** the existing name value SHALL be preserved

### Requirement: Validation Error Localization

The system SHALL provide validation error messages using field labels.

#### Scenario: Error uses field label

- **GIVEN** schema "coffee" has field with key="roast_level" and label="Roast Level"
- **WHEN** validation fails for this field
- **THEN** the error message SHALL use "Roast Level" not "roast_level"
- **AND** the message SHALL read: "Roast Level is required"

### Requirement: Schema Version Validation

The system SHALL validate items against the schema version active at creation time.

#### Scenario: Item validated against creation schema version

- **GIVEN** schema "beer" is at version 2 with new required field "ibu"
- **AND** an item was created at version 1 (before ibu was added)
- **WHEN** the item is retrieved
- **THEN** the item SHALL be valid despite missing ibu
- **AND** the item SHALL NOT require fields added in later versions

#### Scenario: Update uses current schema version

- **GIVEN** schema "beer" is at version 2 with required field "ibu"
- **WHEN** a user updates an item created at version 1
- **THEN** the update SHALL be validated against version 2
- **AND** new required fields SHALL be enforced

## Error Response Format

### Validation Error Response

```json
{
  "error": "validation_failed",
  "message": "Request validation failed",
  "errors": [
    {
      "field": "name",
      "code": "required",
      "message": "Name is required"
    },
    {
      "field": "abv",
      "code": "max_value",
      "message": "ABV must be at most 100",
      "details": {
        "max": 100,
        "actual": 150
      }
    }
  ]
}
```

### Error Codes

| Code | Description |
|------|-------------|
| `required` | Field is required but missing or empty |
| `min_length` | String is shorter than minimum length |
| `max_length` | String is longer than maximum length |
| `min_value` | Number is below minimum |
| `max_value` | Number exceeds maximum |
| `pattern` | String does not match required pattern |
| `invalid_option` | Value not in allowed options |
| `type_mismatch` | Value type does not match field type |
| `unknown_field` | Field not defined in schema |
