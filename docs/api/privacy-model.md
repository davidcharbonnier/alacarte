# Privacy Model Documentation - Backend

> **Concepts first:** the cross-app privacy model (visibility tiers, audience, sharing behavior, cascade rules, privacy guarantees) lives in [docs/features/privacy-model.md](/docs/features/privacy-model.md). This document covers only the backend implementation.

---
**Last Updated:** November 2026  
**Related Documentation:**
- [Privacy Model (canonical)](/docs/features/privacy-model.md)
- [Authentication System](authentication-system.md)
---

## Data Schema

### Privacy-Focused User Model

```go
// models/userModel.go
type User struct {
	gorm.Model

	// Authentication fields
	GoogleID string `gorm:"uniqueIndex;not null" json:"google_id"`
	Email    string `gorm:"uniqueIndex;not null" json:"email"`
	FullName string `gorm:"not null" json:"full_name"`
	Avatar   string `json:"avatar"`

	// Privacy fields
	DisplayName      string `gorm:"uniqueIndex" json:"display_name"`
	Discoverable     bool   `gorm:"default:true" json:"discoverable"`
	ProfileCompleted bool   `gorm:"default:false" json:"profile_completed"`
	IsAdmin          bool   `gorm:"default:false" json:"is_admin"`

	Ratings     []Rating   `gorm:"foreignKey:UserID" json:"ratings,omitempty"`
	LastLoginAt time.Time  `json:"last_login_at"`
}
```

### Rating Model with Viewers

```go
// models/ratingModel.go
type Rating struct {
	gorm.Model

	Grade    float32 `json:"grade"`
	Note     string  `json:"note"`

	// Item association (polymorphic)
	ItemID   int    `json:"item_id"`
	ItemType string `json:"item_type"`

	UserID int  `json:"user_id"`
	User   User `gorm:"foreignKey:UserID" json:"user,omitempty"`

	// Privacy - users who can see this rating
	Viewers []User `gorm:"many2many:rating_viewers;" json:"viewers,omitempty"`
}

// Author can always see their own rating; others only if in viewers list
func (r *Rating) IsVisibleToUser(userID uint) bool {
	if r.UserID == int(userID) {
		return true
	}
	for _, viewer := range r.Viewers {
		if viewer.ID == userID {
			return true
		}
	}
	return false
}
```

## API Endpoints

All privacy routes require authentication (`authMiddleware`). Registration in `main.go`:

```go
// User account (display_name + discoverable updates)
user.GET("/me", controllers.GetCurrentUser)
user.PATCH("/me", controllers.UpdateCurrentUser)
user.DELETE("/me", controllers.DeleteCurrentUser)

// Rating privacy
rating.POST("/new", controllers.RatingCreate)
rating.PUT("/:id/share", controllers.RatingShare)                        // batch share with user list
rating.PUT("/:id/hide", controllers.RatingHide)                          // hide (make private)
rating.GET("/viewer/:id", controllers.RatingByViewer)                    // user's own + shared ratings

// Bulk privacy operations
rating.PUT("/bulk/private", controllers.BulkMakeRatingsPrivate)          // clear viewers on all ratings
rating.PUT("/bulk/unshare/:userId", controllers.BulkRemoveUserFromShares) // remove one user from all shares

// User discovery for sharing dialogs
users.GET("/shareable", controllers.GetShareableUsers)                   // previous_connections + discoverable
```

### Implementation Notes

- **`PATCH /user/me`** — partial update; writes only whitelisted fields (`display_name`, `discoverable`). Display-name validation (2–50 chars, uniqueness → 409) happens at profile completion (`/profile/complete`), not here.
- **Bulk operations** (`/bulk/private`, `/bulk/unshare/:userId`) run per rating and return `ratings_affected` (plus `removed_user` display name for unshare).
- **`/users/shareable`** — returns `previous_connections` (users who have shared with the current user, via `rating_viewers` join) and `discoverable` users, excluding the requester and previous connections so previous connections appear first.
- **Ownership check** — all rating-mutation endpoints verify `rating.UserID` matches the token user (403 otherwise).

## Security & Performance

### Database Indexes for Privacy Queries

```sql
CREATE INDEX idx_rating_viewers_user_id ON rating_viewers(user_id);
CREATE INDEX idx_rating_viewers_rating_id ON rating_viewers(rating_id);
CREATE INDEX idx_ratings_user_item ON ratings(user_id, item_type, item_id);
CREATE INDEX idx_ratings_item ON ratings(item_type, item_id);
CREATE INDEX idx_users_discoverable ON users(discoverable);
CREATE INDEX idx_users_display_name ON users(display_name);
```

---

**This privacy model backend implementation provides a secure, scalable foundation for user-controlled rating sharing while maintaining strong privacy protections and efficient query performance.**
