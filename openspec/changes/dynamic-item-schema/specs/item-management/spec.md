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

## ADDED Requirements (Pagination & Server-Side Filtering)

### Requirement: Client-Side Pagination

The Flutter client SHALL support paginated item browsing with infinite scroll, using the API's existing offset-based pagination.

#### Scenario: Initial page load

- **GIVEN** schema "cheese" has 150 items and the user navigates to the cheese listing
- **WHEN** the screen initializes
- **THEN** the client SHALL fetch GET /api/items/cheese?page=1&per_page=20
- **AND** SHALL display the first 20 items
- **AND** SHALL store pagination metadata (total, page, perPage, totalPages)

#### Scenario: Infinite scroll loads next page

- **GIVEN** the user has scrolled to within 200px of the list bottom
- **AND** `hasMore` is true (currentPage < totalPages)
- **AND** no load-more request is in flight
- **WHEN** the scroll threshold is crossed
- **THEN** the client SHALL fetch GET /api/items/cheese?page=<currentPage+1>&per_page=20
- **AND** SHALL append new items to the existing list
- **AND** SHALL show a loading indicator at the bottom during the fetch

#### Scenario: All items loaded

- **GIVEN** the client has loaded all pages (currentPage == totalPages)
- **WHEN** the user scrolls to the bottom
- **THEN** no additional request SHALL be made
- **AND** "All items loaded" text SHALL be displayed

#### Scenario: Pull-to-refresh resets pagination

- **GIVEN** the user has scrolled through 3 pages (60 items loaded)
- **WHEN** the user pulls to refresh
- **THEN** accumulated items SHALL be cleared
- **AND** pagination SHALL reset to page 1
- **AND** current search and filter state SHALL be preserved

#### Scenario: Network error during loadMore

- **GIVEN** a loadMore request fails due to network error
- **WHEN** the error occurs
- **THEN** existing items and pagination state SHALL be preserved
- **AND** `isLoadingMore` SHALL be set to false
- **AND** the user MAY scroll to bottom again to retry

### Requirement: Server-Side Search

The Flutter client SHALL delegate search to the API instead of filtering client-side.

#### Scenario: Debounced search triggers API call

- **GIVEN** the user types "brie" into the search field
- **WHEN** 300ms elapses since the last keystroke
- **THEN** the client SHALL fetch GET /api/items/cheese?page=1&per_page=20&search=brie
- **AND** pagination SHALL reset to page 1
- **AND** existing items SHALL be replaced with search results

#### Scenario: Rapid typing coalesces into single request

- **GIVEN** the user types "b", "r", "i", "e" in rapid succession (< 300ms between keystrokes)
- **WHEN** 300ms after the last keystroke ("e")
- **THEN** exactly ONE API request SHALL be made with search="brie"
- **AND** no intermediate requests for "b", "br", "bri" SHALL be made

#### Scenario: Search cleared

- **GIVEN** a search query is active with filtered results showing
- **WHEN** the user clears the search field
- **THEN** the client SHALL fetch page 1 with no search param (but active category filters preserved)
- **AND** items SHALL be replaced with unfiltered results

### Requirement: Server-Side Category Filtering

The Flutter client SHALL delegate category filters to the API instead of filtering client-side.

#### Scenario: Category filter triggers API call

- **GIVEN** the user selects filter "type" = "Soft" for cheese items
- **WHEN** the filter is applied
- **THEN** the client SHALL fetch GET /api/items/cheese?page=1&per_page=20&filter[type]=Soft
- **AND** pagination SHALL reset to page 1

#### Scenario: Multiple filters combined with search

- **GIVEN** search query is "brie"
- **AND** filter "type" = "Soft" is active
- **WHEN** the user adds filter "region" = "France"
- **THEN** the client SHALL fetch GET /api/items/cheese?page=1&per_page=20&search=brie&filter[type]=Soft&filter[region]=France

#### Scenario: Filter removed

- **GIVEN** filters "type" = "Soft" and "region" = "France" are active
- **WHEN** the user removes the "region" filter
- **THEN** the client SHALL fetch page 1 with only "type" = "Soft" + current search

#### Scenario: All filters cleared

- **GIVEN** search and category filters are active
- **WHEN** the user clears all filters
- **THEN** the client SHALL fetch page 1 with no filter or search params

### Requirement: Schema-Based Filter Option Discovery

The Flutter client SHALL derive available filter options from schema field definitions, not from scanning loaded items.

#### Scenario: Filter options come from schema

- **GIVEN** schema "cheese" has field "type" (select) with options ["Soft", "Hard", "Blue", "Fresh"]
- **WHEN** the cheese listing screen builds its filter UI
- **THEN** available filter values SHALL be ["Soft", "Hard", "Blue", "Fresh"]
- **AND** they SHALL NOT be derived by scanning currently loaded items

#### Scenario: Schema without select/enum fields

- **GIVEN** schema "wine" has no select or enum fields
- **WHEN** the wine listing screen builds its filter UI
- **THEN** no category filters SHALL be displayed (only search + hasImage)

### Requirement: My List Tab Pagination

The "My List" tab SHALL support the same infinite scroll pagination as the "All Items" tab.

#### Scenario: My List supports loadMore

- **GIVEN** the user is on the My List tab with filtered+rated items
- **WHEN** the user scrolls near the bottom
- **THEN** loadMoreItems SHALL be triggered using the same ScrollController
- **AND** the same loading indicator and "All items loaded" states SHALL apply
