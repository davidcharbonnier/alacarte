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

## 🧀 Item Endpoints

Supported item types: `cheese`, `gin`, `wine`, `coffee`

Item endpoints follow the same pattern for all item types:
- `/api/cheese` - Cheese operations
- `/api/gin` - Gin operations  
- `/api/wine` - Wine operations
- `/api/coffee` - Coffee operations

### Get All Items

```http
GET /api/:itemType/all
Authorization: Bearer JWT_TOKEN
```

**Example:**
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/wine/all
```

### Get Item by ID

```http
GET /api/:itemType/:id
Authorization: Bearer JWT_TOKEN
```

### Create Item

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

### Update Item

```http
PUT /api/:itemType/:id
Authorization: Bearer JWT_TOKEN
Content-Type: application/json

{
  "name": "Updated Name",
  ...
}
```

### Delete Item

```http
DELETE /api/:itemType/:id
Authorization: Bearer JWT_TOKEN
```

---

## 📸 Image Endpoints

### Upload Image

Upload an image for any item type.

```http
POST /api/:itemType/:id/image
Authorization: Bearer JWT_TOKEN
Content-Type: multipart/form-data

image=@file.jpg
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
  "image_url": "http://localhost:9000/alacarte-images/wine_uuid.jpg"
}
```

**Example:**
```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@wine-bottle.jpg" \
  http://localhost:8080/api/wine/1/image
```

### Delete Image

```http
DELETE /api/:itemType/:id/image
Authorization: Bearer JWT_TOKEN
```

**Response:**
```json
{
  "message": "Image deleted successfully"
}
```

**Example:**
```bash
curl -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/wine/1/image
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

## 🔧 Admin Endpoints

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

Most endpoints don't use query parameters. Filtering and sorting are handled server-side.

---

## 📝 Notes

### Item Type Pattern

All item endpoints follow the pattern:
- `POST /api/:itemType/new` - Create
- `GET /api/:itemType/all` - List
- `GET /api/:itemType/:id` - Read
- `PUT /api/:itemType/:id` - Update
- `DELETE /api/:itemType/:id` - Delete

Supported item types: `cheese`, `gin`, `wine`

### Image Endpoints

Image upload/delete endpoints work for all item types:
- `POST /api/:itemType/:id/image` - Upload
- `DELETE /api/:itemType/:id/image` - Delete

Any authenticated user can upload/delete images (collaborative platform).

### Privacy Model

Ratings are private by default:
- Only visible to author
- Can be shared with specific users
- Community stats are anonymous aggregates

See [Privacy Model](/docs/features/privacy-model.md) for details.

---

## 🚀 Related Documentation

- [API Overview](/docs/api/README.md) - Getting started
- [Authentication System](/docs/features/authentication.md) - OAuth and JWT
- [Image Upload System](/docs/features/image-upload.md) - Image handling
- [Privacy Model](/docs/features/privacy-model.md) - Privacy architecture
- [Adding New Item Types](/docs/guides/adding-new-item-types.md) - Backend implementation
