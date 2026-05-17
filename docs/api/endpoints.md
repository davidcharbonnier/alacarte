# API Endpoints Reference

Complete REST API endpoint documentation for the À la carte platform.

**Base URL:** `http://localhost:8080` (development)

---

## 🔐 Authentication

All protected endpoints require a JWT token in the `Authorization` header:

### Health Check

```http
GET /health
```

Returns `200 OK` indicating the service is healthy.

---

```bash
Authorization: Bearer YOUR_JWT_TOKEN
```

### OAuth

---

## 🔐 Google OAuth Exchange

```http
POST /auth/google
Content-Type: application/json

{
  "id_token": "google-id-token",
  "access_token": "google-access-token"
}
```

## 👤 Profile Management

### Complete Profile

```http
POST /profile/complete
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "display_name": "John",
  "discoverable": true
}
```

### Check Display Name Availability

```http
GET /profile/check-display-name?name=John
Authorization: Bearer JWT_TOKEN
```

---

## 🔐 Authentication

### Check Admin Status

```http
GET /api/auth/check-admin
Authorization: Bearer JWT_TOKEN
```

#### Exchange Google Token for Backend JWT

```http
POST /auth/google
Content-Type: application/json

{
  "id_token": "google-id-token",
  "access_token": "google-access-token"
}
```

**Response:**
```json
{
  "token": "backend-jwt-token",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "display_name": "John",
    "is_admin": false
  }
}
```

---

## 👤 User Management

### Get Current User

```http
GET /api/user/me
Authorization: Bearer JWT_TOKEN
```

### Update Current User

```http
PATCH /api/user/me
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "display_name": "New Name",
  "discoverable": true
}
```

### Delete Current User

```http
DELETE /api/user/me
Authorization: Bearer JWT_TOKEN
```

### Get Shareable Users

```http
GET /api/users/shareable
Authorization: Bearer JWT_TOKEN
```

Returns users with `discoverable = true` and completed profiles.

---

## 🧀 Item Endpoints (Legacy)

**Deprecated:** The legacy item endpoints (`/api/:itemType/*`) are deprecated in favor of the [dynamic item endpoints](#-dynamic-item-endpoints) (`/api/items/:type/*`). The legacy endpoints will return `410 Gone` in a future release.

Supported item types via dynamic endpoints: any active schema (e.g., `cheese`, `gin`, `wine`, `coffee`, `chili-sauce`)

### Get All Items (Legacy)

```http
GET /api/:itemType/all
Authorization: Bearer JWT_TOKEN
```

**Example:**
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/items/cheese
```

### Get Item by ID (Legacy)

```http
GET /api/:itemType/:id
Authorization: Bearer JWT_TOKEN
```

### Create Item (Legacy)

```http
POST /api/:itemType/new
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "name": "Item Name",
  "origin": "Quebec",
  ...
}
```

### Update Item (Legacy)

```http
PUT /api/:itemType/:id
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "name": "Updated Name",
  ...
}
```

### Delete Item (Legacy)

```http
DELETE /api/:itemType/:id
Authorization: Bearer JWT_TOKEN
```

---

## 📸 Image Endpoints

Upload or delete images for any item type via dynamic endpoints.

```http
POST /api/items/:type/:id/image
Authorization: Bearer JWT_TOKEN
Content-Type: multipart/form-data

image=@file.jpg
```

**Legacy (deprecated):**
```http
POST /api/:itemType/:id/image
```

**Constraints:**
- Max size: 5MB
- Formats: JPEG, PNG, WebP
- Min dimensions: 100x100px
- Max dimensions: 8000x8000px

**Processing:**
- Resized to max 1200x1200px
- Converted to JPEG (85% quality)
- Sharpened to compensate for resize

**Response:**
```json
{
  "message": "Image uploaded successfully",
  "image_url": "http://localhost:9000/alacarte-images/items/wine_1.jpg"
}
```

### Delete Image

```http
DELETE /api/items/:type/:id/image
Authorization: Bearer JWT_TOKEN
```

**Legacy (deprecated):**
```http
DELETE /api/:itemType/:id/image
```

**Response:**
```json
{
  "message": "Image deleted successfully"
}
```

---

## ⭐ Rating Endpoints

### Create Rating

```http
POST /api/rating/new
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "item_type": "wine",
  "item_id": 1,
  "grade": 8.5,
  "note": "Excellent wine!"
}
```

### Get Ratings by Author

```http
GET /api/rating/author/:userId
Authorization: Bearer JWT_TOKEN
```

### Get Ratings by Viewer

```http
GET /api/rating/viewer/:userId
Authorization: Bearer JWT_TOKEN
```

Returns ratings shared with the specified user.

### Get Ratings by Item

```http
GET /api/rating/:type/:id
Authorization: Bearer JWT_TOKEN
```

**Example:** `GET /api/rating/wine/1`

Returns:
- User's own ratings for this item
- Ratings shared with the user

### Update Rating

```http
PUT /api/rating/:id
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "grade": 9.0,
  "note": "Updated review"
}
```

### Delete Rating

```http
DELETE /api/rating/:id
Authorization: Bearer JWT_TOKEN
```

### Share Rating

```http
PUT /api/rating/:id/share
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "user_ids": [2, 3, 4]
}
```

### Unshare Rating

```http
PUT /api/rating/:id/hide
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "user_ids": [2, 3]
}
```

### Bulk Make Ratings Private

```http
PUT /api/rating/bulk/private
Authorization: Bearer JWT_TOKEN
```

Removes all viewers from all of the user's ratings.

### Bulk Remove User from Shares

```http
PUT /api/rating/bulk/unshare/:userId
Authorization: Bearer JWT_TOKEN
```

Removes specified user from all of the author's shared ratings.

---

## 📊 Statistics Endpoints

### Get Community Stats

```http
GET /api/stats/community/:type/:id
Authorization: Bearer JWT_TOKEN
```

**Example:** `GET /api/stats/community/wine/1`

**Response:**
```json
{
  "total_ratings": 15,
  "average_rating": 8.2
}
```

Returns anonymous aggregate statistics (no individual attribution).

---

## 📐 Schema Endpoints

Dynamic schema discovery and management endpoints. Schemas define the structure of item types (fields, validation, display hints).

### List All Schemas

```http
GET /api/schemas?include_counts=true&include_inactive=false
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `include_counts` | boolean | false | Include item count per schema |
| `include_inactive` | boolean | false | Include deactivated schemas |

**Response:**
```json
{
  "schemas": [
    {
      "id": 1,
      "name": "cheese",
      "display_name": "Cheese",
      "plural_name": "Cheeses",
      "icon": "Cheese",
      "color": "#673AB7",
      "is_active": true,
      "unique_fields": ["name", "origin"],
      "item_count": 42,
      "fields": [
        {
          "key": "name",
          "label": "Name",
          "field_type": "text",
          "required": true,
          "order": 0,
          "options": [],
          "validation": { "minLength": 1, "maxLength": 100 },
          "display": { "badge": true }
        }
      ]
    }
  ]
}
```

### Get Schema Details

```http
GET /api/schemas/:type
```

Returns detailed schema information with ETag caching headers (`Cache-Control: public, max-age=300`).

**Response:**
```json
{
  "name": "cheese",
  "display_name": "Cheese",
  "plural_name": "Cheeses",
  "icon": "Cheese",
  "color": "#673AB7",
  "is_active": true,
  "unique_fields": ["name", "origin"],
  "version": 1,
  "version_hash": "abc123...",
  "item_count": 42,
  "fields": [ ... ]
}
```

---

## 🧩 Dynamic Item Endpoints

Item endpoints that adapt to any schema-defined item type. Replace `:type` with any active schema name (e.g., `cheese`, `gin`, `wine`).

### List Items

```http
GET /api/items/:type?page=1&per_page=20&sort=name&search=query&filter[field_key]=value&filter[has_image]=true
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `per_page` | integer | 20 | Items per page (max 100) |
| `sort` | string | - | Sort field (prefix with `-` for descending) |
| `search` | string | - | Search across all fields |
| `filter[field_key]` | string | - | Filter by EAV field value |
| `filter[has_image]` | boolean | - | Filter items with/without images |

**Response:**
```json
{
  "items": [
    {
      "id": 1,
      "name": "Cheddar",
      "description": "Aged cheddar cheese",
      "image_url": "http://localhost:9000/alacarte-images/cheese_1.jpg",
      "field_values": {
        "origin": "Quebec",
        "milk_type": "Cow",
        "age_months": 12
      },
      "user_id": 1,
      "schema_version_id": 1,
      "created_at": "2025-01-15T10:00:00Z",
      "updated_at": "2025-01-15T10:00:00Z"
    }
  ],
  "total": 42,
  "page": 1,
  "per_page": 20,
  "total_pages": 3
}
```

### Get Item by ID

```http
GET /api/items/:type/:id
```

### Create Item

```http
POST /api/items/:type
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "name": "Item Name",
  "description": "Optional description",
  "field_values": {
    "origin": "Quebec",
    "milk_type": "Cow",
    "age_months": 12
  }
}
```

**Notes:**
- `name` is stored as a first-class column (fast queries)
- Field values are validated against the schema's validation rules
- Dual-write: JSON column (fast reads) + EAV rows (filterable)
- Uniqueness is enforced based on schema's `unique_fields` configuration

**Validation Error Response (400):**
```json
{
  "error": "validation_failed",
  "errors": {
    "name": ["Name is required"],
    "age_months": ["Must be a number"]
  }
}
```

### Update Item

```http
PUT /api/items/:type/:id
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "name": "Updated Name",
  "field_values": {
    "origin": "France"
  }
}
```

**Notes:**
- Only the item owner can update (admins can override)
- Partial updates supported (omitted fields keep existing values)

### Delete Item

```http
DELETE /api/items/:type/:id
Authorization: Bearer JWT_TOKEN
```

**Notes:**
- Only the item owner can delete (admins can override)
- Cascading delete: removes item, ratings, and shares

### Upload Image

```http
POST /api/items/:type/:id/image
Authorization: Bearer JWT_TOKEN
Content-Type: multipart/form-data

image=@file.jpg
```

### Delete Image

```http
DELETE /api/items/:type/:id/image
Authorization: Bearer JWT_TOKEN
```

---

## 🔧 Admin Schema Endpoints

All admin endpoints require `is_admin = true`.

### Create Schema

```http
POST /admin/schemas
Authorization: Bearer ADMIN_JWT
Content-Type: application/json

{
  "name": "beer",
  "display_name": "Beer",
  "plural_name": "Beers",
  "icon": "Beer",
  "color": "#FFA726",
  "unique_fields": ["name", "brewery"],
  "fields": [
    {
      "key": "name",
      "label": "Name",
      "field_type": "text",
      "required": true,
      "validation": { "minLength": 1, "maxLength": 100 },
      "display": { "badge": true }
    },
    {
      "key": "brewery",
      "label": "Brewery",
      "field_type": "text",
      "required": true
    },
    {
      "key": "style",
      "label": "Style",
      "field_type": "select",
      "required": true,
      "options": ["IPA", "Stout", "Pilsner", "Wheat"],
      "display": { "primary": true }
    },
    {
      "key": "abv",
      "label": "ABV (%)",
      "field_type": "number",
      "required": false,
      "validation": { "min": 0, "max": 20 }
    },
    {
      "key": "organic",
      "label": "Organic",
      "field_type": "checkbox",
      "required": false,
      "display": { "secondary": true }
    }
  ]
}
```

**Field Types:** `text`, `textarea`, `number`, `select`, `checkbox`, `enum`

**Validation Rules:**
- `required`: boolean
- `minLength` / `maxLength`: string length (text/textarea)
- `min` / `max`: numeric range (number)
- `pattern`: regex pattern (text)

**Display Hints:**
- `badge`: boolean - shows as pill on item cards
- `primary`: boolean - primary subtitle field
- `secondary`: boolean - secondary subtitle field

**Constraints:**
- `name` must be unique, kebab-case (e.g., `chili-sauce`)
- Creates initial schema version automatically (version 1)

### Update Schema

```http
PUT /admin/schemas/:type
Authorization: Bearer ADMIN_JWT
Content-Type: application/json

{
  "display_name": "Craft Beer",
  "is_active": true,
  "fields": [ ... ]
}
```

**Notes:**
- Updates create a new schema version automatically
- Old items keep their creation version for data integrity
- Setting `is_active: false` hides the type from clients

### Delete Schema

```http
DELETE /admin/schemas/:type
Authorization: Bearer ADMIN_JWT
```

**Constraints:**
- Cannot delete schema with existing items
- Deactivate instead (`is_active: false`) to hide without data loss

### Get Schema Version History

```http
GET /admin/schemas/:type/versions/:version
Authorization: Bearer ADMIN_JWT
```

**Response:**
```json
{
  "version": 1,
  "fields": "[{...}]",
  "is_active": true,
  "migrated_at": null,
  "created_at": "2025-01-15T10:00:00Z"
}
```

---

## 🔧 Admin Dynamic Item Endpoints

### Get Delete Impact

```http
GET /admin/items/:type/:id/delete-impact
Authorization: Bearer ADMIN_JWT
```

Returns impact assessment before deletion (ratings count, affected users, sharing relationships).

### Seed Items

```http
POST /admin/items/:type/seed
Authorization: Bearer ADMIN_JWT
Content-Type: application/json

{
  "url": "https://example.com/beers.json"
}
```

Bulk import from JSON URL. Uses `unique_fields` for deduplication.

### Validate Seed Data

```http
POST /admin/items/:type/validate
Authorization: Bearer ADMIN_JWT
Content-Type: application/json

{
  "url": "https://example.com/beers.json"
}
```

Validates JSON without importing. Checks validation rules and unique field presence.

---

All admin endpoints require `is_admin = true` in the user's profile.

### Item Management

#### Get Delete Impact

```http
GET /admin/:itemType/:id/delete-impact
Authorization: Bearer ADMIN_JWT
```

Returns impact assessment before deletion:
- Number of ratings
- Users affected
- Sharing relationships

#### Delete Item (Admin)

```http
DELETE /admin/:itemType/:id
Authorization: Bearer ADMIN_JWT
```

Cascading delete (removes item, ratings, and shares).

#### Seed Items

```http
POST /admin/:itemType/seed
Authorization: Bearer ADMIN_JWT
Content-Type: application/json

{
  "url": "https://example.com/data.json"
}
```

Bulk import items from JSON URL.

#### Validate Seed Data

```http
POST /admin/:itemType/validate
Authorization: Bearer ADMIN_JWT
Content-Type: application/json

{
  "url": "https://example.com/data.json"
}
```

Validates JSON without importing.

### User Management

#### Get All Users

```http
GET /admin/users/all
Authorization: Bearer ADMIN_JWT
```

#### Get User Details

```http
GET /admin/user/:id
Authorization: Bearer ADMIN_JWT
```

#### Get User Delete Impact

```http
GET /admin/user/:id/delete-impact
Authorization: Bearer ADMIN_JWT
```

#### Delete User

```http
DELETE /admin/user/:id
Authorization: Bearer ADMIN_JWT
```

Cascading delete (removes user, ratings, and shares).

#### Promote User to Admin

```http
PATCH /admin/user/:id/promote
Authorization: Bearer ADMIN_JWT
```

#### Demote User from Admin

```http
PATCH /admin/user/:id/demote
Authorization: Bearer ADMIN_JWT
```

**Note:** Initial admin cannot be demoted.

---

## 📋 Response Formats

### Success Response

```json
{
  "data": { ... },
  "message": "Success message"
}
```

### Error Response

```json
{
  "error": "Error message",
  "details": {
    "field": ["validation error"]
  }
}
```

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 500 | Internal Server Error |

---

## 🔍 Query Parameters

### Dynamic Item List Parameters

| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `page` | integer | `1` | Page number for pagination |
| `per_page` | integer | `20` | Items per page (default: 20, max: 100) |
| `sort` | string | `name` or `-created_at` | Sort field. Prefix with `-` for descending |
| `search` | string | `mountain` | Full-text search across all fields |
| `filter[field_key]` | string | `filter[origin]=Quebec` | Filter by EAV field value |
| `filter[has_image]` | boolean | `true` | Filter items with images only |

### Schema List Parameters

| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `include_counts` | boolean | `true` | Include item count per schema |
| `include_inactive` | boolean | `true` | Include deactivated schemas |

---

## 📝 Notes

### Dynamic Item Type Pattern

All item types are now dynamically defined by schemas. The API automatically supports any active schema without code changes.

**Dynamic endpoints:**
- `GET /api/items/:type` - List items for any schema type
- `GET /api/items/:type/:id` - Get single item
- `POST /api/items/:type` - Create item (validated against schema)
- `PUT /api/items/:type/:id` - Update item
- `DELETE /api/items/:type/:id` - Delete item

**Schema discovery:**
- `GET /api/schemas` - List all active schemas
- `GET /api/schemas/:type` - Get schema details (cached with ETag)

**Supported field types:** `text`, `textarea`, `number`, `select`, `checkbox`, `enum`

**Validation:** Server-side validation enforces schema rules (required, length, range, pattern, enum values). Validation errors return `400` with field-level details.

### Legacy Endpoints (Deprecated)

The old per-type endpoints (`/api/cheese/*`, `/api/gin/*`, etc.) are deprecated and will return `410 Gone` in a future release. Migrate to `/api/items/:type/*` endpoints.

### Image Endpoints

Image upload/delete endpoints work for all item types via dynamic endpoints:
- `POST /api/items/:type/:id/image` - Upload
- `DELETE /api/items/:type/:id/image` - Delete

Any authenticated user can upload/delete images (collaborative platform).

### Privacy Model

Ratings are private by default:
- Only visible to author
- Can be shared with specific users
- Community stats are anonymous aggregates

See [Privacy Model](/docs/features/privacy-model.md) for details.

### Schema Versioning

Each schema update creates a new immutable version. Items store their creation `schema_version_id` and are validated against that version. This ensures data integrity as schemas evolve.

---

## 🚀 Related Documentation

- [API Overview](/docs/api/README.md) - Getting started
- [Authentication System](/docs/features/authentication.md) - OAuth and JWT
- [Image Upload System](/docs/features/image-upload.md) - Image handling
- [Privacy Model](/docs/features/privacy-model.md) - Privacy architecture
- [Schema Management Guide](/docs/admin/schema-management.md) - Admin schema UI guide
- [Adding New Item Types](/docs/guides/adding-new-item-types.md) - Developer guide for new types
