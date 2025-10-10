# Privacy Model

**Last Updated:** January 2025  
**Status:** Production Ready

The A la carte platform implements a **privacy-first architecture** where user data is private by default with explicit sharing controls.

---

## 🎯 Core Principles

### 1. Private by Default
- New ratings are **only visible to the author**
- No public ratings without explicit user action
- Display names hide real identity

### 2. Explicit Sharing
- Users choose **exactly who** can see their ratings
- Share/unshare individual ratings with specific users
- Bulk privacy actions for all ratings

### 3. Selective Discovery
- Users control visibility in **sharing dialogs**
- Discoverable toggle hides user from sharing lists
- Real identity protected via display names

### 4. Anonymous Community Data
- Aggregate statistics (average ratings, totals)
- No individual rating attribution
- Community insights without privacy violations

---

## 🗄️ Database Architecture

### Privacy-Related Tables

```sql
-- Users with privacy controls
users (
    id, google_id, email, full_name,
    display_name,           -- User-chosen identity
    discoverable BOOLEAN,   -- Sharing dialog visibility
    is_admin BOOLEAN,
    created_at, updated_at, last_login_at
)

-- Ratings (private by default)
ratings (
    id, user_id, item_id, item_type,
    grade, note,
    created_at, updated_at
)

-- Explicit sharing permissions
rating_viewers (
    rating_id, user_id,  -- Many-to-many
    created_at
)

-- Sharing relationship analytics
sharing_relationships (
    user_a_id, user_b_id,
    first_shared_at, last_shared_at,
    total_shares
)
```

### Privacy Cascade Rules

**When a user is deleted:**
- ✅ All their ratings are deleted
- ✅ All sharing relationships are removed
- ✅ Shared ratings no longer visible to others

**When an item is deleted:**
- ✅ All ratings for that item are deleted
- ✅ All sharing relationships for those ratings are removed

**When a rating is made private:**
- ✅ All viewer permissions are removed
- ✅ No one except author can see it

---

## 📡 Backend Implementation

### Rating Visibility Logic

```go
// Three visibility levels
func GetUserVisibleRatings(userID int, itemType string, itemID int) []Rating {
    var ratings []Rating
    
    DB.Where("item_type = ? AND item_id = ?", itemType, itemID).
       Where("user_id = ? OR id IN (?)",
           userID,  // 1. Ratings authored by user
           DB.Model(&RatingViewer{}).
              Select("rating_id").
              Where("user_id = ?", userID),  // 2. Ratings shared with user
       ).
       Preload("User").
       Find(&ratings)
    
    return ratings
}

// Community statistics (anonymous)
func GetCommunityStats(itemType string, itemID int) CommunityStats {
    var stats CommunityStats
    
    DB.Model(&Rating{}).
       Where("item_type = ? AND item_id = ?", itemType, itemID).
       Select("COUNT(*) as total_ratings, AVG(grade) as average_rating").
       Scan(&stats)
    
    return stats  // No individual attribution
}
```

### Privacy Endpoints

```go
// Get users available for sharing (respects discoverable flag)
GET /api/users/shareable
// Returns only users with discoverable = true AND completed profile

// Share rating with specific users
PUT /api/rating/:id/share
Body: { "viewer_ids": [2, 3, 4] }

// Remove specific user from rating viewers
PUT /api/rating/:id/unshare
Body: { "viewer_id": 3 }

// Make rating completely private
PUT /api/rating/:id/private
// Removes all viewer permissions

// Bulk privacy actions
PUT /api/user/privacy/make-all-private
// Makes all user's ratings private

PUT /api/user/privacy/remove-from-all-shares
// Removes user from all shares by others
```

**See:** [API Privacy Implementation](/docs/api/privacy-model.md) for backend details

---

## 📱 Frontend Implementation

### Privacy Settings Screen

**Progressive Item Loading:**
- Shows all shared ratings with item information
- Progressively loads missing item data
- Visual feedback during loading

**Item Type Filtering:**
- Filter ratings by item type (cheese, gin, etc.)
- Auto-populates filter chips
- Persists filter selection

**Individual Rating Management:**
- Manage sharing for each rating
- View who has access
- Quick unshare actions

**Bulk Privacy Actions:**
- "Make All Ratings Private" - Remove all shares
- "Remove Me From All Shares" - Stop seeing others' ratings
- Confirmation dialogs with impact preview

### Sharing Dialog

**Enhanced Features:**
- Pre-checked boxes show current sharing state
- Only shows users with completed profiles
- Real user avatars
- Change detection (button enabled only when changed)
- "Make Private" button for quick unsharing

**State Management:**
```dart
// Calculate sharing changes
final shareWith = newlySelected - currentlyShared
final unshareFrom = currentlyShared - newlySelected

// Apply changes
await ratingService.shareRating(ratingId, shareWith);
await ratingService.unshareFromUsers(ratingId, unshareFrom);
```

### Privacy Analytics

**Sharing Statistics:**
- Total ratings shared
- Number of users with access
- Sharing relationships count
- Available via user profile

**See:** [Client Privacy Implementation](/docs/client/privacy-model.md) for frontend details

---

## 🔐 Privacy Guarantees

### What Users Control

✅ **Who sees their ratings** - Explicit permission required  
✅ **Their display name** - Customizable identity  
✅ **Discoverable status** - Visibility in sharing dialogs  
✅ **Bulk privacy actions** - Make all ratings private  
✅ **Account deletion** - Complete data removal  

### What Users Cannot See

❌ **Other users' private ratings** - Unless explicitly shared  
❌ **Individual rating authors in community stats** - Only aggregates  
❌ **Real identities** - Only display names visible  
❌ **Email addresses** - Not exposed in UI (admin only)  

### What Admins Can See

Admins have additional access for platform management:
- All user email addresses (via admin panel)
- Delete impact assessments
- User management capabilities
- Cannot see private ratings (same privacy rules apply)

---

## 🧪 Privacy Testing Scenarios

### Scenario 1: Rating Creation
1. User creates rating → Only visible to author ✅
2. Check other users → Cannot see the rating ✅
3. Community stats → Include the rating in aggregates ✅

### Scenario 2: Rating Sharing
1. User shares rating with User B → B can now see it ✅
2. User C (not shared with) → Cannot see the rating ✅
3. Author makes rating private → B can no longer see it ✅

### Scenario 3: User Discovery
1. User sets discoverable = false ✅
2. Other users → Cannot see them in sharing dialogs ✅
3. Existing shares → Continue to work ✅

### Scenario 4: Account Deletion
1. User deletes account ✅
2. All their ratings → Deleted ✅
3. Shared ratings → No longer visible to others ✅
4. Community stats → Recalculated without their data ✅

---

## 📊 Privacy Metrics

### User Privacy Stats

Available via `GET /api/user/sharing-stats`:

```json
{
  "total_ratings": 15,
  "total_shares": 8,
  "unique_users_shared_with": 3,
  "discoverable": true,
  "sharing_relationships": [
    {
      "user_id": 2,
      "display_name": "Alice",
      "total_shares": 5
    }
  ]
}
```

### Platform Privacy Metrics (Admin)

- Average ratings per user
- Average shares per user
- Discoverable vs non-discoverable users
- Community participation rate

---

## 🔄 Future Enhancements

### Planned Privacy Features

- [ ] **Temporary Shares** - Time-limited access to ratings
- [ ] **Share Groups** - Share with predefined groups
- [ ] **Privacy Audit Log** - Track sharing changes
- [ ] **Export Privacy Data** - GDPR-compliant data export
- [ ] **Granular Permissions** - View-only vs edit permissions

### Under Consideration

- [ ] **Anonymous Ratings** - Option to hide author completely
- [ ] **Private Collections** - Share curated rating lists
- [ ] **Privacy Levels** - Friends, Close Friends, Public presets

---

## 📚 Related Documentation

### Implementation Details
- [Backend Privacy Model](/docs/api/privacy-model.md) - Database and API implementation
- [Client Privacy Settings](/docs/client/privacy-model.md) - UI and state management

### Related Features
- [Authentication System](/docs/features/authentication.md) - User identity
- [Sharing System](/docs/features/sharing-system.md) - Rating sharing mechanics
- [Rating System](/docs/features/rating-system.md) - Rating CRUD operations

---

**Privacy-first design ensures users maintain complete control over their data while enabling meaningful sharing and community insights.**
