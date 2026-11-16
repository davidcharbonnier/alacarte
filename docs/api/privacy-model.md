# Privacy Model Documentation - Backend

> **Concepts first:** the cross-app privacy model (visibility tiers, audience, sharing behavior, cascade rules, privacy guarantees) lives in [docs/features/privacy-model.md](/docs/features/privacy-model.md). This document covers only the backend implementation.

---
**Last Updated:** September 2025  
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
// User privacy settings
api.GET("/user/privacy-stats", controllers.GetUserPrivacyStats)          // shared ratings count, recipient list
api.GET("/user/sharing-relationships", controllers.GetSharingRelationships) // per-user share counts
api.PATCH("/user/me", controllers.UpdateUserProfile)                     // display_name + discoverable updates

// Bulk privacy operations
api.PUT("/ratings/bulk/make-private", controllers.MakeAllRatingsPrivate)       // clear viewers on all ratings
api.PUT("/ratings/bulk/remove-user/:user_id", controllers.RemoveUserFromAllShares) // remove one user from all shares

// Individual rating privacy
api.GET("/ratings/shared", controllers.GetSharedRatings)                 // ?type= item-type filter
api.PUT("/rating/:id/share", controllers.RatingShare)                    // batch share with user list
api.PUT("/rating/:id/hide", controllers.RatingHide)                      // legacy single-user hide
api.PUT("/rating/:id/unshare-from/:user_id", controllers.UnshareRatingFromUser)
api.PUT("/rating/:id/make-private", controllers.MakeRatingPrivate)       // clear all viewers
api.GET("/rating/viewer/:id", controllers.RatingByViewer)                // user's own + shared ratings

// User discovery for sharing dialogs
api.GET("/users/shareable", controllers.GetShareableUsers)               // previous_connections + discoverable
```

### Implementation Notes

- **`PATCH /user/me`** — partial update; validates display name (trimmed, non-empty, unique → 409) and applies `discoverable`.
- **Bulk operations** (`make-private`, `remove-user`) run in a transaction; they count affected ratings/viewers and return `ratings_affected` (plus `viewers_removed` / `user_removed`).
- **`/ratings/shared`** — filters by `item_type` query parameter (default `%`), returns only ratings that have viewers.
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
