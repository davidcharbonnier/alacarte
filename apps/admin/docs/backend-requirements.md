# Backend API Requirements - Admin Panel

**Last Updated:** January 2025  
**Status:** 📋 Specification for Backend Implementation

---

## 🎯 Overview

This document specifies all backend API endpoints required by the admin panel, including request/response formats, authentication requirements, and implementation notes.

---

## 🔐 Authentication

### Required Endpoint (Implemented)

```
POST /auth/google
```

**Purpose:** Exchange Google OAuth tokens for backend JWT

**Request:**
```json
{
  "id_token": "google-jwt-token",
  "access_token": "google-access-token"
}
```

**Response (Success - 200):**
```json
{
  "token": "backend-jwt-token",
  "user": {
    "ID": 1,
    "email": "admin@example.com",
    "display_name": "Admin User",
    "is_admin": true,
    "google_id": "123456789",
    "full_name": "Admin User",
    "avatar": "https://...",
    "discoverable": true,
    "CreatedAt": "2024-01-01T00:00:00Z",
    "UpdatedAt": "2024-01-01T00:00:00Z",
    "last_login_at": "2025-01-01T00:00:00Z"
  },
  "message": "Authentication successful"
}
```

**Response (Error - 400/401):**
```json
{
  "error": "Invalid Google ID token or missing profile data"
}
```

**Notes:**
- Backend validates Google token with Google API
- Creates or updates user in database
- Admin panel uses **same Google Client ID** as backend
- JWT token includes user_id, email, display_name claims

---

## 📦 Item Management

### Cheese Endpoints

#### **Public Endpoints (Reused by Admin)**

```
GET /api/cheese/all
GET /api/cheese/:id
```

**Notes:**
- Admin panel reuses these existing endpoints
- No admin-specific auth needed (publicly accessible)
- Returns all cheeses in database

**Response Format:**
```json
[
  {
    "ID": 1,
    "name": "Oka",
    "type": "Pâte pressée",
    "origin": "Quebec",
    "producer": "Fromagerie d'Oka",
    "description": "...",
    "CreatedAt": "2024-01-01T00:00:00Z",
    "UpdatedAt": "2024-01-01T00:00:00Z"
  }
]
```

**Note:** Admin panel transforms `ID`/`CreatedAt` → `id`/`created_at`

#### **Admin-Only Endpoints (To Be Implemented)**

```
GET    /admin/cheese/:id/delete-impact
DELETE /admin/cheese/:id
POST   /admin/cheese/seed
POST   /admin/cheese/validate
```

##### **Delete Impact Assessment**

```
GET /admin/cheese/:id/delete-impact
```

**Authorization:** Requires admin JWT

**Response (200):**
```json
{
  "can_delete": true,
  "warnings": [
    "This will permanently delete all ratings for this item",
    "Users who rated this item will lose their ratings"
  ],
  "impact": {
    "ratings_count": 12,
    "users_affected": 8,
    "sharings_count": 15,
    "affected_users": [
      {
        "id": 1,
        "display_name": "John Doe",
        "ratings_count": 2
      },
      {
        "id": 2,
        "display_name": "Jane Smith",
        "ratings_count": 1
      }
    ]
  }
}
```

**Implementation Notes:**
- Query all ratings for this cheese
- Count unique users who rated it
- Count sharing relationships (rating_viewers)
- Return list of affected users with their rating counts
- Set `can_delete` based on business rules (always true for now)

##### **Delete Cheese**

```
DELETE /admin/cheese/:id
```

**Authorization:** Requires admin JWT

**Behavior:**
- Cascade delete all ratings for this cheese
- Remove all sharing relationships (rating_viewers)
- Delete the cheese record itself
- Update sharing_relationships analytics table

**Response (200):**
```json
{
  "message": "Cheese deleted successfully"
}
```

**Response (404):**
```json
{
  "error": "Cheese not found"
}
```

##### **Seed Cheeses**

```
POST /admin/cheese/seed
```

**Authorization:** Requires admin JWT

**Request:**
```json
{
  "url": "https://example.com/cheeses.json"
}
```

**Expected JSON Format at URL:**
```json
{
  "cheeses": [
    {
      "name": "Oka",
      "type": "Pâte pressée",
      "origin": "Quebec",
      "producer": "Fromagerie d'Oka",
      "description": "..."
    }
  ]
}
```

**Response (200):**
```json
{
  "added": 25,
  "skipped": 3,
  "errors": []
}
```

**Implementation Notes:**
- Fetch JSON from provided URL
- Validate structure
- Use natural key matching (name + origin)
- Only add new items (skip existing)
- Return count of added/skipped/errors

##### **Validate Cheese JSON**

```
POST /admin/cheese/validate
```

**Authorization:** Requires admin JWT

**Request:**
```json
{
  "url": "https://example.com/cheeses.json"
}
```

**Response (200):**
```json
{
  "valid": true,
  "errors": [],
  "item_count": 28,
  "duplicates": 3
}
```

**Implementation Notes:**
- Validate JSON structure without importing
- Check for required fields
- Identify duplicates within the file
- Return validation errors if any

### Gin Endpoints

Same structure as cheese:
- `GET /api/gin/all` (implemented)
- `GET /api/gin/:id` (implemented)
- `GET /admin/gin/:id/delete-impact` (to implement)
- `DELETE /admin/gin/:id` (to implement)
- `POST /admin/gin/seed` (to implement)
- `POST /admin/gin/validate` (to implement)

---

## 👥 User Management

### Admin Endpoints (To Be Implemented)

```
GET    /admin/users/all
GET    /admin/user/:id
GET    /admin/user/:id/delete-impact
DELETE /admin/user/:id
```

#### **List All Users**

```
GET /admin/users/all
```

**Authorization:** Requires admin JWT

**Response (200):**
```json
[
  {
    "ID": 1,
    "email": "user@example.com",
    "display_name": "User Name",
    "full_name": "Full Name",
    "is_admin": false,
    "discoverable": true,
    "CreatedAt": "2024-01-01T00:00:00Z",
    "last_login_at": "2025-01-01T00:00:00Z"
  }
]
```

**Privacy Note:** This endpoint is admin-only because it exposes user emails

#### **Get User Details**

```
GET /admin/user/:id
```

**Authorization:** Requires admin JWT

**Response:** Same as list, but single user object

#### **User Delete Impact**

```
GET /admin/user/:id/delete-impact
```

**Authorization:** Requires admin JWT

**Response (200):**
```json
{
  "can_delete": true,
  "warnings": [
    "This will delete all of the user's ratings",
    "Other users will lose shared ratings from this user"
  ],
  "impact": {
    "ratings_count": 45,
    "users_affected": 12,
    "sharings_count": 28,
    "affected_users": [
      {
        "id": 2,
        "display_name": "Friend Name",
        "ratings_count": 8
      }
    ]
  }
}
```

**Implementation Notes:**
- Count all ratings by this user
- Count users who have ratings shared from this user
- Count total sharing relationships
- List affected users (who will lose shared ratings)

#### **Delete User**

```
DELETE /admin/user/:id
```

**Authorization:** Requires admin JWT

**Behavior:**
- Delete all ratings by this user
- Remove user as viewer from all ratings
- Delete sharing relationships
- Delete user account
- Cascade deletes via GORM

**Response (200):**
```json
{
  "message": "User deleted successfully"
}
```

---

## ⭐ Rating Moderation (Phase 2)

### Admin Endpoints (To Be Implemented)

```
GET    /admin/ratings/all
PATCH  /admin/rating/:id/moderate
PATCH  /admin/rating/:id/unmoderate
PATCH  /admin/ratings/bulk-moderate
DELETE /admin/rating/:id
```

#### **List All Ratings**

```
GET /admin/ratings/all
```

**Query Parameters:**
- `user_id` (optional) - Filter by user
- `item_type` (optional) - Filter by item type
- `item_id` (optional) - Filter by specific item
- `moderation_status` (optional) - all, moderated, unmoderated
- `page` (optional) - Page number
- `page_size` (optional) - Items per page

**Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 5,
      "user_display_name": "John Doe",
      "item_id": 10,
      "item_type": "cheese",
      "item_name": "Oka",
      "grade": 4.5,
      "note": "Excellent cheese...",
      "is_moderated": false,
      "viewers_count": 3,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 150,
  "page": 1,
  "page_size": 20
}
```

#### **Moderate Rating**

```
PATCH /admin/rating/:id/moderate
```

**Request:**
```json
{
  "reason": "Language violates community guidelines"
}
```

**Response (200):**
```json
{
  "message": "Rating moderated successfully",
  "rating": {
    "id": 1,
    "is_moderated": true,
    "moderation_reason": "Language violates community guidelines",
    "moderated_at": "2025-01-01T12:00:00Z",
    "moderated_by": 1,
    "moderated_by_name": "Admin User"
  }
}
```

**Side Effects:**
- Creates in-app notification for rating owner
- Hides note content from other users (grade remains visible)
- Preserves original note text in database

#### **Unmoderate Rating**

```
PATCH /admin/rating/:id/unmoderate
```

**Response (200):**
```json
{
  "message": "Rating approved successfully"
}
```

**Side Effects:**
- Removes moderation flag
- Clears moderation reason
- Makes note visible to shared users again
- Creates approval notification

#### **Bulk Moderate**

```
PATCH /admin/ratings/bulk-moderate
```

**Request:**
```json
{
  "rating_ids": [1, 2, 3, 4],
  "reason": "Spam content"
}
```

**Response (200):**
```json
{
  "message": "4 ratings moderated successfully",
  "moderated_count": 4,
  "failed_count": 0
}
```

**Side Effects:**
- Moderates all specified ratings with same reason
- Creates individual notification for each affected user

#### **Delete Rating**

```
DELETE /admin/rating/:id
```

**Response (200):**
```json
{
  "message": "Rating deleted permanently"
}
```

**Side Effects:**
- Permanently deletes rating
- Removes from all sharing relationships
- Creates deletion notification for owner
- Cannot be undone

---

## 🔔 Notifications (Phase 3)

### Public Endpoints (To Be Implemented)

```
GET    /api/user/notifications
PATCH  /api/user/notifications/:id/read
DELETE /api/user/notifications/:id
```

#### **Get User Notifications**

```
GET /api/user/notifications
```

**Authorization:** Requires JWT (any user)

**Response (200):**
```json
[
  {
    "id": 1,
    "user_id": 5,
    "type": "rating_moderated",
    "title": "Rating Moderated",
    "message": "Your rating for Oka has been moderated: Language violates community guidelines",
    "data": {
      "rating_id": 10,
      "item_type": "cheese",
      "item_id": 5
    },
    "is_read": false,
    "created_at": "2025-01-01T12:00:00Z"
  }
]
```

#### **Mark as Read**

```
PATCH /api/user/notifications/:id/read
```

**Response (200):**
```json
{
  "message": "Notification marked as read"
}
```

---

## 🔧 Implementation Guidelines

### Admin Authorization Pattern

```go
// Middleware for admin-only endpoints
func RequireAdmin() gin.HandlerFunc {
    return func(c *gin.Context) {
        user := c.MustGet("user").(models.User)
        if !user.IsAdmin {
            c.JSON(403, gin.H{"error": "Admin access required"})
            c.Abort()
            return
        }
        c.Next()
    }
}

// Apply to admin routes
admin := router.Group("/admin")
admin.Use(RequireAuth(), RequireAdmin())
{
    admin.GET("/cheese/:id/delete-impact", GetCheeseDeleteImpact)
    admin.DELETE("/cheese/:id", DeleteCheese)
    // ... other admin routes
}
```

### GORM Field Naming

**Important:** GORM uses uppercase field names by default:
- `ID` not `id`
- `CreatedAt` not `created_at`
- `UpdatedAt` not `updated_at`

**Admin panel handles this via transformation:**
```typescript
function transformCheese(backend: any): Cheese {
  return {
    id: backend.ID,              // uppercase → lowercase
    created_at: backend.CreatedAt,
    updated_at: backend.UpdatedAt,
    // ... other fields
  };
}
```

### Natural Key Matching for Seeding

Use `name + origin` as natural key for duplicate detection:

```go
// Check if cheese already exists
var existing Cheese
err := db.Where("name = ? AND origin = ?", cheese.Name, cheese.Origin).First(&existing).Error

if err == nil {
  // Already exists - skip
  skipped++
  continue
}

// Create new cheese
db.Create(&cheese)
added++
```

---

## 📋 Implementation Priority

### **Phase 1: Item Management**
1. ✅ Authentication endpoint (implemented)
2. 🔲 Delete impact for cheese/gin
3. 🔲 Delete endpoints for cheese/gin
4. 🔲 Seed endpoints for cheese/gin
5. 🔲 User management endpoints

### **Phase 2: Rating Moderation**
6. 🔲 List all ratings
7. 🔲 Moderate/unmoderate endpoints
8. 🔲 Bulk moderation
9. 🔲 Delete rating

### **Phase 3: Notifications**
10. 🔲 Notification endpoints
11. 🔲 Auto-create notifications on moderation

---

## 🧪 Testing Endpoints

### Manual Testing with curl

```bash
# Get JWT token first (from admin panel login)
TOKEN="your-backend-jwt-token"

# Test delete impact
curl -H "Authorization: Bearer $TOKEN" \
     http://localhost:8080/admin/cheese/1/delete-impact

# Test seeding
curl -X POST \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"url":"https://example.com/cheeses.json"}' \
     http://localhost:8080/admin/cheese/seed

# Test delete
curl -X DELETE \
     -H "Authorization: Bearer $TOKEN" \
     http://localhost:8080/admin/cheese/1
```

---

## 📚 Related Documentation

- [Authentication System](authentication-system.md) - NextAuth.js integration
- [Adding New Item Types](adding-new-item-types.md) - Extending admin functionality
- [Phased Implementation](phased-implementation.md) - Development timeline

---

**This specification provides complete backend requirements for all admin panel features across three development phases.**
