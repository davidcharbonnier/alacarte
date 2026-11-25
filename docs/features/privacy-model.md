# Privacy Model

> **See also:** Full backend privacy implementation is in [/docs/api/privacy-model.md](/docs/api/privacy-model.md).

**Last Updated:** January 2025  
**Status:** Production Ready

The À la carte platform implements a **privacy-first architecture** where user data is private by default with explicit sharing controls.

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
- Users are shown by display name (see the known gap below: the API still returns email and Google id)

### 4. Anonymous Community Data
- Aggregate statistics (average ratings, totals)
- No individual rating attribution
- Community insights without privacy violations

---

## 👁️ Visibility Tiers

Every rating exists in exactly one tier:

| Tier | Who sees it | Where it appears |
|---|---|---|
| **Personal** | Author only (default for new ratings) | "My Rating" section in item details |
| **Shared** | Author + explicitly shared users | "Recommendations" section for recipients |
| **Community** | Everyone, anonymous aggregates only | "Community" stats (averages, counts) |

Equivalent access-control layers: Personal → Shared → Community → Blocked (no access to private/unshared ratings).

The backend sets a new user's initial display name to their Google full name; users can change it (unique, validated by each app; client: 2–50 characters). The client's setup screen suggests a `First L.` form (first name + upper-cased last initial).

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
    id, user_id,
    item_id,               -- FK -> items (plain foreign key, no item_type column)
    grade, note,
    created_at, updated_at
)

-- Explicit sharing permissions
rating_viewers (
    rating_id, user_id   -- Many-to-many join table
)
```

### Privacy Cascade Rules

**When a user is deleted:**
- Deletion is a **soft delete** (`gorm.Model` sets `deleted_at`); the database `ON DELETE CASCADE` does not run
- `DELETE /api/user/me` soft-deletes only the user row; their ratings and shares remain in the database (and still count in community stats)
- The admin path `DELETE /admin/user/:id` differs: it removes the user's `rating_viewers` rows and soft-deletes their ratings (see the known gap in [endpoints.md](/docs/api/endpoints.md))

**When an item is deleted:**
- Soft delete as well; ratings and shares for that item are not physically removed

**When a rating is made private:**
- ✅ All viewer permissions are removed
- ✅ No one except author can see it

---

## 📡 Backend Implementation

The detailed backend privacy implementation—including rating visibility logic, privacy endpoints, and related details—is documented in the API privacy model documentation: [/docs/api/privacy-model.md](/docs/api/privacy-model.md).

## 📱 Frontend Implementation

### Privacy Settings Screen

**Progressive Item Loading:**
- Shows all shared ratings with item information
- Progressively loads missing item data
- Visual feedback during loading

**Item Type Filtering:**
- Filter ratings by item type (cheese, gin, etc.)
- Auto-populates filter chips

**Individual Rating Management:**
- Manage sharing for each rating
- View who has access
- Quick unshare actions

**Bulk Privacy Actions:**
- "Make All Ratings Private" - Remove all shares
- "Remove Person from All Shares" - Remove one chosen person from all your shares
- Confirmation dialogs with impact preview

### Sharing Dialog

**Location**: `lib/widgets/rating/share_rating_dialog.dart`

**Enhanced Features:**
- ✅ Pre-checked boxes show current sharing state
- ✅ Only shows users with completed profiles
- ✅ Real user avatars
- ✅ Change detection (button enabled only when changed)
- ✅ **"Make Private" button for quick unsharing of all users**
- ✅ **Batch operations - single API call per action type**
- ✅ Previous connections shown first, discoverable users second

**State Management:**
```dart
// Calculate sharing changes (batch operations)
final shareWith = newlySelected - currentlyShared      // Users to add
final unshareFrom = currentlyShared - newlySelected    // Users to remove

// Apply changes with batch API calls
if (shareWith.isNotEmpty) {
  await ratingService.shareRating(ratingId, shareWith);
}
if (unshareFrom.isNotEmpty) {
  await ratingService.unshareRatingFromUsers(ratingId, unshareFrom);
}

// Success notification based on actions taken
if (shareWith.isEmpty && unshareFrom.isNotEmpty) {
  showMessage(context.l10n.ratingUnsharedFromUsers(unshareFrom.length));
} else if (shareWith.isNotEmpty && unshareFrom.isEmpty) {
  showMessage(context.l10n.shareRatingSuccess);
} else {
  showMessage(context.l10n.sharingPreferencesUpdated);
}
```

### Privacy Analytics

The only statistics are two client-side counts on the privacy settings screen: shared ratings and unique recipients.

**See:** [Client Privacy Implementation](/docs/client/privacy-model.md) for frontend details

---

## 🔐 Privacy Guarantees

### What Users Control

✅ **Who sees their ratings** - Explicit permission required  
✅ **Their display name** - Customizable identity  
✅ **Discoverable status** - Visibility in sharing dialogs  
✅ **Bulk privacy actions** - Make all ratings private  
⚠️ **Account deletion** - Soft delete of the user row only (see cascade rules)  

### What Users Cannot See

❌ **Other users' private ratings** - Unless explicitly shared  
❌ **Individual rating authors in community stats** - Only aggregates  
⚠️ **Real identities and emails** - The UI shows only display names, but `GET /api/users/shareable` also returns `email`, `google_id` and `full_name` for discoverable users (known gap: the API does not strip them)  

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

### Scenario 2: Rating Sharing & Unsharing
1. User shares rating with User B → B can now see it ✅
2. User C (not shared with) → Cannot see the rating ✅
3. Author unshares from User B → B can no longer see it ✅
4. Author clicks "Make Private" → All viewers removed at once ✅
5. Bulk unshare User B from all ratings → B loses access to all ✅

### Scenario 3: User Discovery
1. User sets discoverable = false ✅
2. Other users → Cannot see them in sharing dialogs ✅
3. Existing shares → Continue to work ✅

### Scenario 4: Account Deletion
1. User deletes account (`DELETE /api/user/me`) → user row soft-deleted
2. Their ratings and shares stay in the database
3. Shared ratings remain visible to the people they were shared with
4. Community stats keep counting their ratings
5. Known risk (read from code, not run): the soft-deleted row keeps its unique `google_id`/`email`, so signing in again with the same Google account may fail at user creation

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
