# Change: Add filter for items with a picture

## Why

Users need a way to quickly find items that have an associated picture, improving discoverability and user experience for visual browsing.

## What Changes

- Add a new filter option to item listings that allows users to display only items that have an associated picture.
- The filtering will be implemented client-side, leveraging existing item data in the application state, consistent with current best practices for filter option generation. This will be implemented using a dedicated `ItemFilterProvider` for better state management.

## Impact

- Affected specs: item-management
- Affected code: Item listing UI, Item data model (potentially), client-side filtering logic (e.g., `ItemFilterProvider` for better state management).
