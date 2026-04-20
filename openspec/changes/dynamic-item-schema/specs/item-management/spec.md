# item-management Specification (Delta)

## Purpose

Extend the existing item-management capability to support filtering dynamically-typed items by picture presence.

## MODIFIED Requirements

### Requirement: Filter Items by Picture Presence

The system SHALL allow users to filter item listings to display only items that have an associated picture.

#### Scenario: User filters for items with pictures

- **WHEN** a user navigates to any item listing page
- **AND** the user activates the "Show only items with pictures" filter
- **THEN** only items that have at least one associated picture SHALL be displayed
- **AND** items without pictures SHALL be excluded from the listing

#### Scenario: User disables filter

- **WHEN** a user has activated the "Show only items with pictures" filter
- **AND** the user deactivates the filter
- **THEN** all items, regardless of picture presence, SHALL be displayed

#### Scenario: Filter applies to dynamic item types

- **GIVEN** a schema "beer" exists with items
- **WHEN** a user filters beer items by picture presence
- **THEN** the filter SHALL work identically to hardcoded item types
- **AND** the filter SHALL check the `image_url` field on the dynamic item

## ADDED Requirements

### Requirement: Filter Parameter for Dynamic Items

The system SHALL support the `filter[has_image]` query parameter for dynamic item endpoints.

#### Scenario: API filter for items with images

- **GIVEN** schema "beer" has items with and without images
- **WHEN** a client requests GET /api/items/beer?filter[has_image]=true
- **THEN** the system SHALL return only items where image_url IS NOT NULL

#### Scenario: API filter for items without images

- **GIVEN** schema "beer" has items with and without images
- **WHEN** a client requests GET /api/items/beer?filter[has_image]=false
- **THEN** the system SHALL return only items where image_url IS NULL

#### Scenario: Default behavior without filter

- **WHEN** a client requests GET /api/items/beer without has_image filter
- **THEN** the system SHALL return all items regardless of image presence
