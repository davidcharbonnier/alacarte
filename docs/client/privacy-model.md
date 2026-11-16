# Privacy Model Documentation - Frontend

> **Concepts first:** the cross-app privacy model (visibility tiers, audience, sharing behavior, cascade rules, privacy guarantees) lives in [docs/features/privacy-model.md](/docs/features/privacy-model.md). This document covers only the Flutter client implementation.

---
**Last Updated:** September 2025  
**Related Documentation:**
- [Privacy Model (canonical)](/docs/features/privacy-model.md)
- [Authentication System](authentication-system.md)
- [Rating System](../features/rating-system.md)
---

## Privacy Settings Screen

`lib/screens/user/privacy_settings_screen.dart`, built from the reusable `lib/widgets/settings/` component library.

### Privacy Overview
- Summary card with **Shared Ratings Count** and **Recipients Count** (unique users with access, deduplicated)
- Counts computed client-side from current data and refresh immediately after any privacy action

### Discovery Settings
- `SwitchListTile` bound to `user.discoverable`; changes PATCH `/user/me` immediately with success/error feedback

### Bulk Privacy Actions
- **Make All Ratings Private** — multi-step confirmation dialog with impact preview, loading state, success message with affected count, automatic UI refresh
- **Remove Person from All Shares** — user selection dialog with real avatars + per-user impact preview, double confirmation, batch removal

### Rating List & Filtering
- Complete shared-ratings list directly on the screen (no item-limit popups)
- `FilterChip` row per item type with live counts ("All (6)", "Fromage (6)"); auto-creates chips for new item types
- **Progressive item loading** — shows localized fallbacks ("fromage #1") instantly, loads real item data in the background, minimal `[FROMAGE]` type badges

### Service & Provider Implementation

```dart
// RatingService — batch bulk operations
Future<Map<String, dynamic>> makeAllRatingsPrivate() =>
    handleResponse<Map<String, dynamic>>(put(ApiConfig.ratingBulkPrivate), (json) => json as Map<String, dynamic>);

Future<Map<String, dynamic>> removeUserFromAllShares(int userId) =>
    handleResponse<Map<String, dynamic>>(put(ApiConfig.ratingBulkUnshare(userId)), (json) => json as Map<String, dynamic>);

// RatingNotifier wraps each call with isLoading/error state and UI refresh
Future<Map<String, dynamic>> removeUserFromAllShares(int userId) async {
  state = state.copyWith(isLoading: true, error: null);
  final result = await _ratingService.removeUserFromAllShares(userId);
  // Refresh state, then show localized snackbar with ratings_affected count
}
```

Error handling and dialogs must keep the original `BuildContext` mounted-checked while dialogs use their own `dialogContext`:

```dart
if (confirmed == true && context.mounted) { /* loading + API call on original context */ }
```

## Display Name Validation

```dart
// lib/utils/display_name_generator.dart
static String? validateDisplayName(String displayName) {
  // required, trimmed; 2–50 characters; basic inappropriate-content check
}

// Generation rule (First L.) shared with the backend — see canonical doc
```

## Sharing Dialog

Behavior (pre-checked state, batch share/unshare, "Make Private" button, ordering) is described in the canonical doc; implementation lives in `lib/widgets/rating/share_rating_dialog.dart`.

## Localization

All privacy features are localized EN/FR, e.g.:

```dart
context.l10n.makingRatingsPrivate        // "Privatisation des évaluations..."
context.l10n.allRatingsMadePrivate       // "Toutes les évaluations sont maintenant privées"
context.l10n.userRemovedFromShares       // "{user} retiré de {count} évaluations"
context.l10n.discoverableForSharing      // "Découvrable pour le Partage" / "Discoverable for Sharing"
```

## Privacy Logic Testing

`test/utils/rating_visibility_test.dart` covers the visibility rules: user sees own ratings, sees ratings shared with them, and cannot see private ratings from others (`RatingVisibilityUtils.isRatingVisibleToUser`).

---

**This privacy model provides a comprehensive, user-friendly approach to managing personal taste preferences while enabling selective social sharing.**
