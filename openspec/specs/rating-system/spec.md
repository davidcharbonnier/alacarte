# rating-system Specification

## Purpose

Simplify the rating system by removing the redundant `item_type` column from the ratings table. After all items are unified in the `items` table with a `schema_id` foreign key, `item_id` alone is sufficient to identify what a rating is about. Replace the GORM polymorphic association with a direct foreign key to `items.id` with CASCADE delete.

## Requirements

### Requirement: Create Rating

The system SHALL allow authenticated users to create ratings for items without requiring an `item_type` field.

#### Scenario: User creates a rating

- **GIVEN** a user is authenticated
- **AND** an item with ID 42 exists in the `items` table
- **WHEN** the user creates a rating with grade=4.5, note="Great!", item_id=42
- **THEN** the system SHALL create the rating
- **AND** the rating SHALL reference the item via `item_id` foreign key
- **AND** the `item_type` field SHALL NOT be required or stored

#### Scenario: System rejects rating for non-existent item

- **GIVEN** a user is authenticated
- **AND** no item with ID 999 exists
- **WHEN** the user creates a rating with item_id=999
- **THEN** the system SHALL reject the creation
- **AND** the system SHALL return a foreign key constraint error

### Requirement: Retrieve Ratings by Item

The system SHALL allow users to retrieve ratings for an item using only the item ID.

#### Scenario: User retrieves ratings for an item

- **GIVEN** item 42 has 3 ratings
- **WHEN** the user requests GET /api/rating/42
- **THEN** the system SHALL return all 3 ratings visible to the user
- **AND** the response SHALL NOT include an `item_type` field

#### Scenario: User retrieves ratings for non-existent item

- **GIVEN** no item with ID 999 exists
- **WHEN** the user requests GET /api/rating/999
- **THEN** the system SHALL return an empty list (not an error)

### Requirement: Retrieve Ratings by Author

The system SHALL allow users to retrieve their own ratings without filtering by item type.

#### Scenario: User retrieves their ratings

- **GIVEN** user 7 has ratings for items of different schema types (cheese, gin, coffee)
- **WHEN** the user requests GET /api/rating/author/7
- **THEN** the system SHALL return all ratings by user 7
- **AND** the `?type=` query parameter SHALL be removed

### Requirement: Retrieve Ratings by Viewer

The system SHALL allow users to retrieve ratings shared with them without filtering by item type.

#### Scenario: User retrieves shared ratings

- **GIVEN** user 12 has access to ratings for items of different schema types
- **WHEN** the user requests GET /api/rating/viewer/12
- **THEN** the system SHALL return all ratings visible to user 12
- **AND** the `?type=` query parameter SHALL be removed

### Requirement: Edit Rating

The system SHALL allow users to edit their ratings without requiring an `item_type` field.

#### Scenario: User edits a rating

- **GIVEN** user 7 created rating 10 for item 42
- **WHEN** the user updates the rating with grade=3.0, note="Updated", item_id=42
- **THEN** the system SHALL update the rating
- **AND** the `item_type` field SHALL NOT be required or updated

### Requirement: Community Statistics

The system SHALL provide anonymous community statistics for an item using only the item ID.

#### Scenario: User requests community stats

- **GIVEN** item 42 has 10 ratings with average grade 4.2
- **WHEN** a user requests GET /api/stats/community/42
- **THEN** the system SHALL return `{total_ratings: 10, average_rating: 4.2, item_id: 42}`
- **AND** the response SHALL NOT include an `item_type` field

### Requirement: Cascade Delete on Item Removal

The system SHALL automatically delete all ratings when their associated item is deleted.

#### Scenario: Admin deletes an item

- **GIVEN** item 42 has 25 ratings
- **WHEN** an administrator deletes item 42
- **THEN** all 25 ratings for item 42 SHALL be automatically deleted via FK CASCADE
- **AND** no manual rating cleanup SHALL be required

### Requirement: Foreign Key Constraint

The system SHALL enforce referential integrity between ratings and items.

#### Scenario: FK constraint prevents orphaned ratings

- **GIVEN** the `ratings.item_id` column has a FK constraint to `items.id`
- **WHEN** any operation attempts to create or update a rating with a non-existent `item_id`
- **THEN** the database SHALL reject the operation
- **AND** the system SHALL return an appropriate error

### Requirement: Client-Side Rating Filtering Without itemType

The client SHALL filter ratings by item type without relying on a `Rating.itemType` field. After removal, the client SHALL derive the item type from the item's schema or use item ID sets for filtering.

#### Scenario: Item type screen filters ratings by item ID set

- **GIVEN** the user is viewing the "cheese" item type screen
- **AND** the user has ratings for items of multiple types (cheese, gin, coffee)
- **WHEN** the client loads ratings via `RatingByAuthor` or `RatingByViewer`
- **THEN** the client SHALL filter ratings to show only those for cheese items
- **AND** the filtering SHALL use item IDs from the loaded items list (not a `Rating.itemType` field)
- **AND** all `r.itemType == widget.itemType` comparisons SHALL be replaced with `cheeseItemIds.contains(r.itemId)`

#### Scenario: Rating deletion clears correct community stats cache

- **GIVEN** a rating for a cheese item (ID 42) is deleted
- **WHEN** the rating provider clears the community stats cache
- **THEN** the cache SHALL be cleared for the correct item type "cheese"
- **AND** the item type SHALL be derived from the item's schema (not from `existingRating.itemType`)

#### Scenario: Rating validation does not check itemType

- **GIVEN** a rating is being created or updated
- **WHEN** the client validates the rating data
- **THEN** the validation SHALL NOT check `rating.itemType.trim().isEmpty`
- **AND** the validation SHALL still check `rating.itemId > 0`
