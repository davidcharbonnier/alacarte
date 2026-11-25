# Sharing System

> **See also:** Privacy architecture in [Privacy Model](/docs/features/privacy-model.md) · API endpoints in [/docs/api/endpoints.md](/docs/api/endpoints.md) · Backend privacy details in [/docs/api/privacy-model.md](/docs/api/privacy-model.md)

**Last Updated:** November 2026  
**Status:** Production Ready

The À la carte sharing system lets users share their ratings with specific other users. A shared rating appears in the recipient's item detail screen as a **Recommendation**. Sharing is always per-user and explicit: ratings are private by default, and unsharing a user (or making a rating private) removes their access immediately.

---

## 🎯 Sharing Model

### Per-User Shares

- Sharing is a many-to-many relationship between ratings and users, stored in the `rating_viewers` table (`rating_id`, `user_id`).
- The author is **not** stored as a viewer — ownership is implicit through `ratings.user_id`.
- A shared rating stays visible to the author and to every user in its viewer list; no one else can see it.
- Sharing never makes a rating public. There is no public visibility tier for individual ratings; community data is anonymous aggregates only (see [Privacy Model](/docs/features/privacy-model.md) — Community tier).

### Hide = Unshare

- "Hiding" a rating is the backend term for **unsharing** it from users. There is no separate hidden state: hiding removes viewer rows, so hidden users simply lose access.
- **Making a rating private** = unsharing it from everyone (empty viewer list). There is no "private" flag on the rating — private means zero viewers.
- Deleting a rating is a soft delete (`deleted_at`); its `rating_viewers` rows are not physically removed, but soft-deleted ratings are no longer returned.

### Discoverability

- The share dialog lists only **discoverable** users plus **previous connections** (users who have shared with you before).
- Users can turn off discoverability in their privacy settings; existing shares keep working, but they disappear from other users' sharing dialogs.
- Only users with completed profiles (`profile_completed = true`) appear in sharing dialogs.

---

## 📡 API Endpoints

| Method | Endpoint | Purpose | Body |
|---|---|---|---|
| `PUT` | `/api/rating/:id/share` | Share rating with users (batch) | `{"user_ids": [2, 3]}` |
| `PUT` | `/api/rating/:id/hide` | Unshare rating from users (batch or legacy single) | `{"user_ids": [2]}` or `{"user_id": 2}` |
| `PUT` | `/api/rating/bulk/private` | Make all the current user's ratings private | — |
| `PUT` | `/api/rating/bulk/unshare/:userId` | Remove one user from all the current user's shares | — |
| `GET` | `/api/users/shareable` | Users available for sharing | — |
| `GET` | `/api/rating/author/:id` | Current user's own ratings (with viewers) | — |
| `GET` | `/api/rating/viewer/:id` | The current user's own ratings plus ratings shared with them (`:id` must be their own user id) | — |
| `GET` | `/api/rating/:id` | Ratings **shared with** the current user for one item (`:id` is the item id; their own are not included) | — |

**Behavior details:**

- `PUT /api/rating/:id/share` requires `user_ids` (batch array). It appends viewers; duplicates are ignored by GORM. Only the author can share. Returns the updated rating with its viewer list.
- `PUT /api/rating/:id/hide` accepts `user_ids` (batch) or the legacy singular `user_id`; at least one is required. Only the author can unshare. Returns the updated rating.
- `PUT /api/rating/bulk/private` clears the viewer list of every rating owned by the current user and returns `{"message", "ratings_affected"}`.
- `PUT /api/rating/bulk/unshare/:userId` removes the target user from every rating the current user has shared with them and returns `{"message", "ratings_affected", "removed_user"}` (display name).
- Known gap: `previous_connections` comes from raw SQL that ignores `deleted_at`, so soft-deleted users (after `DELETE /api/user/me`) can still appear.
- `GET /api/users/shareable` returns `{"previous_connections": [...], "discoverable": [...]}` — previous connections are users who already share with the current user; discoverable users exclude the current user and previous connections. Both lists include only completed profiles.

---

## 📱 Client Implementation

### Share Rating Dialog

**Location**: `lib/widgets/rating/share_rating_dialog.dart`

The dialog is opened from the share button in `MyRatingSection` (item detail screen), next to the Edit and Delete buttons.

**User experience:**

1. Dialog opens pre-checked with the rating's current viewers (`currentlySharedWith`).
2. User list loads from `GET /api/users/shareable` — previous connections and discoverable users, combined and sorted alphabetically by display name.
3. Each user appears as a card with checkbox, display name, and avatar (network image or initials fallback).
4. Changes are detected against the initial selection; the confirm button is disabled until something changes ("No Changes" label).
5. **Make Private** button (shown only when the rating is currently shared) clears the selection so the rating can be unshared from everyone in one save.
6. Saving computes two diffs and issues **one API call per action type**:
   - `shareWithUserIds` = newly selected users → `PUT /api/rating/:id/share`
   - `removeFromUserIds` = previously shared users now deselected → `PUT /api/rating/:id/hide` with `user_ids`
7. Success feedback depends on the action taken:
   - Unshare only → `ratingUnsharedFromUsers(count)`
   - Share only → `shareRatingSuccess`
   - Both → `sharingPreferencesUpdated`
8. Data refreshes after saving.

**States:** loading users (`loadingUsers`), load error with retry (`tryAgain`), and empty state when no users are available (`noUsersAvailable`).

### Recipient Experience — "Recommendations"

Shared ratings surface as recommendations in two places:

- **Item detail screen** (`SharedRatingsList` in `lib/widgets/items/shared_ratings_list.dart`): renders each shared rating as a recommendation-colored card with the author's avatar, display name, and star grade. Only the privacy-safe display name is shown (`rating.authorName`); an "Anonymous User" fallback uses the localized `anonymousUser` string. Empty state shows `noSharedRatings` ("No Recommendations") with `noSharedRatingsMessage(itemName)` ("No one has shared their recommendations for {itemName} with you yet").
- **Item type list** (e.g. cheeses): a "Recommendations" filter (`recommendationsFilter`) separates items recommended by others from the user's own rated items.

The client fetches shared ratings via `GET /api/rating/viewer/:id` (ratings where the user is author or viewer) and `GET /api/rating/:id` (per-item visibility via the `rating_viewers` subquery).

### Client Service Layer

**`lib/services/rating_service.dart`** — sharing methods over the API:

- `shareRating(id, userIds)` — requires a non-empty `user_ids` array; sends one batch call to `PUT /api/rating/:id/share`.
- `unshareRatingFromUsers(ratingId, userIds)` — batch unshare via `PUT /api/rating/:id/hide` with `user_ids`.
- `unshareRatingFromUser(ratingId, userId)` — legacy singular unshare via `user_id` (kept for backward compatibility).
- `hideRating(id)` — deprecated placeholder; the backend `/hide` endpoint requires at least one user, so callers should use the batch methods or "Make Private" instead.
- `getRatingsByAuthor(id)` / `getRatingsByViewer(id)` — own ratings (with viewer lists) and ratings shared with the user; the viewer list is cached.

**`lib/providers/rating_provider.dart`** — Riverpod state: exposes `shareRating()` and `makeAllRatingsPrivate()` to widgets, holds load/error state, and triggers refresh after share/unshare so dialogs and lists stay in sync.

**`lib/config/api_config.dart`** — all sharing route constants (`ratingShare`, `ratingHide`, `ratingBulkPrivate`, `ratingBulkUnshare`).

### Delete Warning

Deleting a shared rating warns about the impact first:
- With viewers: `deleteRatingWithSharing` — "This will also remove it from {count} people who have access to your recommendation."
- Without viewer count: `deleteRatingGenericSharing` — "If this rating has been shared, it will also be removed from other users' recommendations."

### Bulk Privacy Actions

**Location**: `lib/screens/settings/privacy_settings_screen.dart`

- **Make All Ratings Private** (`makeAllRatingsPrivate` / `makeAllRatingsPrivateDescription`) — confirmation dialog with impact preview, then `PUT /api/rating/bulk/private`. Removes all viewers from all the user's ratings.
- **Remove User from Shares** (`removeUserFromShares` with `removeUserWarning`) — removes one user from all shared ratings via `PUT /api/rating/bulk/unshare/:userId`, so they no longer see any of the user's recommendations.

---

## 🌍 Localization Keys

All sharing strings are localized in `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`.

| Key | EN | FR |
|---|---|---|
| `shareRating` | Share Rating | Partager l'Évaluation |
| `shareWith` | Share with... | Partager avec... |
| `shareRatingWith` | Share Rating With | Partager l'Évaluation Avec |
| `selectUsersToShare` | Select users to share this rating with | Sélectionnez les utilisateurs avec qui partager cette évaluation |
| `shareRatingSuccess` | Rating shared successfully! | Évaluation partagée avec succès ! |
| `shareRatingError` | Could not share rating. Please try again. | (FR equivalent) |
| `sharedWith` / `sharedWithCount` | Shared with {count} person(s) | Partagé avec {count} personne(s) |
| `sharedRatings` | Shared Ratings | Évaluations Partagées |
| `sharedRatingsCount` | {count} shared rating(s) | {count} évaluation(s) partagée(s) |
| `noSharedRatings` | No Recommendations | Aucune Recommandation |
| `noSharedRatingsMessage` | No one has shared their recommendations for {itemName} with you yet | (FR equivalent) |
| `recommendations` | Recommendations | Recommandations |
| `recommendationsFromFriends` | {count} recommendations from friends | {count} recommandations d'amis |
| `makePrivate` | Make Private | Rendre Privé |
| `saveChanges` / `noChanges` | Save Changes / No Changes | Enregistrer les Modifications / Aucun Changement |
| `loadingUsers` | Loading users... | Chargement des utilisateurs... |
| `noUsersAvailable` | No users available to share with | Aucun utilisateur disponible pour le partage |
| `tryAgain` | Try Again | Réessayer |
| `ratingUnsharedFromUsers` | Rating unshared from {count} user(s) | Évaluation non partagée avec {count} personne(s) |
| `sharingPreferencesUpdated` | Sharing preferences updated successfully | Préférences de partage mises à jour avec succès |
| `bulkPrivacyActions` | Bulk Privacy Actions | Actions de Confidentialité en Lot |
| `makeAllRatingsPrivate` | Make All Ratings Private | Rendre Toutes les Évaluations Privées |
| `removeUserFromShares` | Remove User from Shares | Retirer l'Utilisateur des Partages |
| `removeUserWarning` | This will remove {userName} from all your shared ratings... | (FR equivalent) |
| `deleteRatingWithSharing` | This will also remove it from {count} people... | Cela la supprimera également de {count} personne(s)... |
| `deleteRatingGenericSharing` | If this rating has been shared, it will also be removed... | Si cette évaluation a été partagée... |
| `discoverabilityDisabledWithExplanation` | You are no longer discoverable. Existing shared ratings remain accessible. | Vous n'êtes plus découvrable. Les évaluations partagées existantes restent accessibles. |

---

## 🧪 Behavior Scenarios

1. **Share**: User A shares a rating with User B → B sees it in "Recommendations"; User C does not.
2. **Unshare**: A hides the rating from B (batch `user_ids`) → B immediately loses access.
3. **Make Private**: A clicks "Make Private" in the dialog → all viewers removed in one save.
4. **Bulk private**: A uses "Make All Ratings Private" in privacy settings → every rating's viewer list is cleared.
5. **Bulk unshare user**: A removes User B from all shares → B loses access to all of A's shared ratings at once.
6. **Discoverability off**: User B sets discoverable = false → B disappears from new sharing dialogs; existing shares keep working.
7. **Delete rating**: A deletes a shared rating → it is soft-deleted, so recipients no longer receive it (viewer rows are not physically removed).
8. **Delete user**: A deletes their account (`DELETE /api/user/me`) → only the user row is soft-deleted; their ratings and shares remain.

---

## 📚 Related Documentation

- [Privacy Model](/docs/features/privacy-model.md) — visibility tiers, privacy principles, bulk actions
- [Rating System](/docs/features/rating-system.md) — rating CRUD and user flows
- [API Privacy Model](/docs/api/privacy-model.md) — backend privacy implementation
- [API Endpoints](/docs/api/endpoints.md) — full endpoint reference
- [Client Privacy Implementation](/docs/client/privacy-model.md) — frontend privacy UI and state

---

**Sharing is explicit and per-user: nothing is visible to anyone until the author shares it, and removing a share removes access immediately.**
