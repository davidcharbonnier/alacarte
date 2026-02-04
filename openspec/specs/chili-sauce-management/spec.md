# chili-sauce-management Specification

## Purpose

Enable users to create, view, edit, rate, and share chili sauces across the À la carte platform. This spec defines the requirements for adding chili sauce as a new consumable item type with full CRUD operations, image support, and integration with existing rating and privacy systems.

## Requirements

### Requirement: Create Chili Sauce

The system SHALL allow authenticated users to create new chili sauce entries with name, brand, spice level, chilis used, and optional description.

#### Scenario: User creates a new chili sauce

- **GIVEN** a user is authenticated
- **AND** the user navigates to the chili sauce creation form
- **WHEN** the user enters:
  - Name: "Sriracha Hot Sauce"
  - Brand: "Huy Fong Foods"
  - Spice Level: "Hot"
  - Chilis: "Jalapeño, Garlic"
  - Description: "A classic Thai hot sauce with garlic kick"
- **AND** the user submits the form
- **THEN** a new chili sauce SHALL be created
- **AND** the system SHALL validate that name and brand are not empty
- **AND** the system SHALL enforce unique constraint on name + brand combination
- **AND** the user SHALL be redirected to the chili sauce detail view

#### Scenario: System rejects duplicate chili sauce

- **GIVEN** a user is authenticated
- **AND** a chili sauce with name "Sriracha Hot Sauce" and brand "Huy Fong Foods" already exists
- **WHEN** the user attempts to create another chili sauce with the same name and brand
- **THEN** the system SHALL reject the creation
- **AND** the system SHALL display an error message indicating the duplicate

### Requirement: View Chili Sauce List

The system SHALL allow users to view a paginated list of all chili sauces with search and filtering capabilities.

#### Scenario: User views all chili sauces

- **GIVEN** a user is authenticated
- **WHEN** the user navigates to the chili sauce list page
- **THEN** the system SHALL display all chili sauces
- **AND** each item SHALL show: name, brand, spice level, and image (if available)
- **AND** the list SHALL support pagination
- **AND** the list SHALL be sorted by name in ascending order by default

#### Scenario: User filters chili sauces by spice level

- **GIVEN** a user is viewing the chili sauce list
- **WHEN** the user selects "Hot" from the spice level filter
- **THEN** the system SHALL display only chili sauces with spice level "Hot"
- **AND** the filter SHALL be reflected in the URL

#### Scenario: User searches chili sauces by name or brand

- **GIVEN** a user is viewing the chili sauce list
- **WHEN** the user enters "Sriracha" in the search field
- **THEN** the system SHALL display chili sauces matching "Sriracha" in name or brand
- **AND** the search SHALL be case-insensitive

### Requirement: View Chili Sauce Details

The system SHALL allow users to view detailed information about a specific chili sauce.

#### Scenario: User views chili sauce details

- **GIVEN** a user is authenticated
- **AND** a chili sauce with ID 42 exists
- **WHEN** the user navigates to `/chili-sauce/42`
- **THEN** the system SHALL display:
  - Name: "Sriracha Hot Sauce"
  - Brand: "Huy Fong Foods"
  - Spice Level: "Hot"
  - Chilis: "Jalapeño, Garlic"
  - Description: "A classic Thai hot sauce with garlic kick"
  - Image (if available)
  - User's rating (if rated)
  - Community statistics

### Requirement: Edit Chili Sauce

The system SHALL allow authenticated users to edit chili sauce entries they created.

#### Scenario: User edits chili sauce details

- **GIVEN** a user is authenticated
- **AND** the user created a chili sauce with ID 42
- **WHEN** the user navigates to the edit form
- **AND** the user changes the spice level from "Hot" to "Extra Hot"
- **AND** the user submits the form
- **THEN** the chili sauce SHALL be updated
- **AND** the system SHALL display a success message
- **AND** the user SHALL be redirected to the detail view

### Requirement: Delete Chili Sauce

The system SHALL allow authenticated users to delete chili sauce entries they created, with cascade deletion of associated ratings.

#### Scenario: User deletes a chili sauce

- **GIVEN** a user is authenticated
- **AND** the user created a chili sauce with ID 42
- **WHEN** the user clicks the delete button
- **AND** the user confirms the deletion
- **THEN** the chili sauce SHALL be deleted
- **AND** all associated ratings SHALL be deleted
- **AND** the user SHALL be redirected to the list view
- **AND** the system SHALL display a success message

### Requirement: Upload Chili Sauce Image

The system SHALL allow users to upload and associate images with chili sauce entries.

#### Scenario: User uploads an image for chili sauce

- **GIVEN** a user is authenticated
- **AND** the user created a chili sauce with ID 42
- **WHEN** the user uploads an image file
- **THEN** the image SHALL be processed and stored
- **AND** the chili sauce's ImageURL SHALL be updated
- **AND** the image SHALL be displayed on the detail view

### Requirement: Rate Chili Sauce

The system SHALL allow users to rate chili sauces with the standard rating system (automatic via existing infrastructure).

#### Scenario: User rates a chili sauce

- **GIVEN** a user is authenticated
- **AND** the user is viewing a chili sauce detail page
- **WHEN** the user clicks "Rate" and submits a rating
- **THEN** the rating SHALL be created (handled by existing rating system)
- **AND** the rating SHALL be associated with the chili sauce
- **AND** the rating SHALL appear in the user's ratings list

### Requirement: Admin Delete Impact Assessment

The system SHALL allow administrators to view the impact of deleting a chili sauce before confirming deletion.

#### Scenario: Admin views delete impact

- **GIVEN** an administrator is authenticated
- **WHEN** the administrator navigates to `/admin/chili-sauce/42/delete-impact`
- **THEN** the system SHALL display:
  - Number of ratings that will be deleted
  - Number of users affected
  - List of affected users (if any)

### Requirement: Admin Bulk Seed

The system SHALL allow administrators to bulk import chili sauces from a JSON data source.

#### Scenario: Admin seeds chili sauces from JSON

- **GIVEN** an administrator is authenticated
- **AND** a JSON file with chili sauce data exists
- **WHEN** the administrator triggers the seed operation
- **THEN** the system SHALL parse the JSON
- **AND** the system SHALL create chili sauces that don't exist
- **AND** the system SHALL skip duplicates based on name + brand
- **AND** the system SHALL report the number of items created and skipped

### Requirement: Admin JSON Validation

The system SHALL allow administrators to validate JSON data before seeding.

#### Scenario: Admin validates chili sauce JSON

- **GIVEN** an administrator is authenticated
- **AND** a JSON file with chili sauce data exists
- **WHEN** the administrator triggers the validation operation
- **THEN** the system SHALL validate the JSON structure
- **AND** the system SHALL validate required fields (name, brand)
- **AND** the system SHALL validate spice level values
- **AND** the system SHALL report any validation errors
- **AND** the system SHALL NOT create any items

## Data Model

### Chili Sauce Entity

```
ChiliSauce {
  id: integer (auto-generated)
  name: string (required, max 255)
  brand: string (required, max 255)
  spice_level: enum (Mild, Medium, Hot, Extra Hot, Extreme)
  chilis: string (optional, comma-separated list, max 500)
  description: string (optional, max 1000)
  image_url: string (optional, nullable)
  created_at: timestamp
  updated_at: timestamp
  deleted_at: timestamp (soft delete)
}
```

### Spice Level Values

- Mild
- Medium
- Hot
- Extra Hot
- Extreme

### Unique Constraint

- Combination of `name` and `brand` must be unique
