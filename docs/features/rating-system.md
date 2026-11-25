# Rating System Implementation

> **See also:** API rating endpoints are documented in [/docs/api/endpoints.md](/docs/api/endpoints.md).

**Last Updated**: January 2025  
**Status**: Production-Ready - All Core Features Complete

> **Documentation Maintenance**: This document reflects the current implementation state. When adding new rating features, update the corresponding sections immediately to prevent documentation drift.

## Overview

The À la carte rating system enables users to create, edit, share, and manage ratings for items across multiple categories. The implementation focuses on personal reference lists enhanced by collaborative sharing between users.

## Core Features Implemented

### 1. Rating Creation
**Location**: `lib/screens/rating/rating_create_screen.dart`

**User Flow**:
- User navigates to item detail → Clicks "Rate [ItemName]" FAB
- Form loads with item context card showing item details
- User selects a star rating in half-star steps (0.5 to 5); 0 cannot be submitted (the create/edit screens require `> 0` and the API rejects a zero grade)
- User adds optional notes
- Form validates and submits via RatingProvider
- Success feedback and navigation back to item detail

**Technical Implementation**:
- Uses FormScaffold for consistent form layout
- StarRatingInput widget for star selection
- Real-time validation with submit button state
- Offline-aware with connectivity messaging
- Comprehensive error handling and user feedback

### 2. Rating Editing
**Location**: `lib/screens/rating/rating_edit_screen.dart`

**User Flow**:
- User clicks "Edit Rating" button in MyRatingSection
- Form pre-populated with existing rating data
- Change detection shows "unsaved changes" indicator
- Submit only enabled when changes detected
- Success feedback and navigation back to item detail

**Technical Implementation**:
- Ownership validation (users can only edit their own ratings)
- Change detection comparing current vs original values
- Pre-populated form fields with existing data
- Same form components as creation for consistency

### 3. Rating Sharing & Unsharing
**Location**: `lib/widgets/rating/share_rating_dialog.dart`

**User Flow - Sharing**:
- User clicks "Share Rating" button in MyRatingSection
- Dialog opens showing list of available users (excluding current user)
- User selects recipients via checkboxes
- Sharing request sent to backend with proper data format
- Success feedback and automatic data refresh

**User Flow - Unsharing**:
- User opens share dialog for already-shared rating
- Previously shared users appear pre-selected with checkboxes
- User can uncheck individual users to unshare with them
- "Make Private" button quickly removes all sharing
- Changes are batched and sent as single API call
- Success notification indicates unsharing completion

**Technical Implementation**:
- **ShareRatingDialog** loads `GET /api/users/shareable` (previous connections and discoverable users)
- **Pre-selection state**: Dialog tracks `currentlySharedWith` users
- **Change detection**: Compares initial vs current selection to determine actions
- **Batch operations**: Single API call for sharing, single call for unsharing
- **Make Private**: Quick action button to clear all viewers at once
- **Backend integration**: Uses `PUT /api/rating/:id/share` and `PUT /api/rating/:id/hide`
- Author names come from the rating (`rating.authorName`), with a localized "Anonymous User" fallback
- Comprehensive error handling and visual feedback

**Backend Endpoints**:
- `PUT /api/rating/:id/share` - Add users to viewers (batch support)
- `PUT /api/rating/:id/hide` - Remove users from viewers (batch support)
  - Accepts `user_ids` array for batch unsharing
  - Also supports legacy `user_id` for single user
- `PUT /api/rating/bulk/private` - Remove all viewers from all ratings
- `PUT /api/rating/bulk/unshare/:userId` - Remove specific user from all shares

### 4. Rating Deletion
**Location**: `lib/widgets/rating/delete_rating_dialog.dart`

**User Flow**:
- User clicks "Delete Rating" button in MyRatingSection
- Confirmation dialog shows deletion warning and sharing impact
- User confirms deletion with understanding of consequences
- Rating deleted with success feedback and navigation

**Technical Implementation**:
- Generic sharing impact warning for all ratings
- Destructive action styling with proper confirmation
- Safe navigation back to item detail after deletion
- Deletion is a soft delete on the backend; the viewer rows stay but the rating is no longer returned

### 5. Rating Display System

#### MyRatingSection
**Location**: `lib/widgets/items/my_rating_section.dart`

**Features**:
- Displays user's personal rating with star visualization
- Shows rating notes or localized placeholder for empty notes
- Compact icon-only action buttons (Edit, Share, Delete) in header row
- Empty state encouragement for unrated items
- Integrated sharing and deletion confirmation dialogs

#### Community Statistics Display
**Location**: `lib/widgets/items/rating_summary_card.dart`
**Provider**: `lib/providers/community_stats_provider.dart`

**Enhanced Implementation**:
- Single-purpose widget for community statistics display
- **Riverpod Provider Architecture**: Uses `FutureProvider.family` for efficient caching
- **Automatic Caching**: Stats cached per item id, with batch fetch support (`CommunityStatsParams(itemIds: [...])`) - no duplicate API calls
- **Optimized data source**: Uses `/api/stats/community/:id` endpoint
- Clean, original design maintained from previous implementation
- Efficient loading states and error handling with AsyncValue
- Anonymous aggregate data without privacy violations

**Performance Benefits**:
- **Eliminated Duplicate API Calls**: FutureBuilder anti-pattern replaced with proper provider caching
- **Single API call per item**: Provider caches results throughout app session
- **Faster loading**: Aggregate statistics computed server-side
- **Improved privacy**: No individual rating data exposure
- **Better UX**: Consistent loading states and error handling
- **App-wide availability**: Stats accessible from any widget via provider

**Provider Architecture**:
```dart
// Community stats provider with automatic caching
final communityStatsProvider = FutureProvider.family<Map<int, Map<String, dynamic>>, CommunityStatsParams>(
  (ref, params) async {
    if (params.itemIds.isEmpty) return {};
    final apiService = ref.watch(apiServiceProvider);

    // One request per item id, in parallel
    final responses = await Future.wait(
      params.itemIds.map((itemId) => apiService.getCommunityStats(itemId)),
    );

    final statsMap = <int, Map<String, dynamic>>{};
    for (var i = 0; i < params.itemIds.length; i++) {
      final response = responses[i];
      if (response is ApiSuccess<Map<String, dynamic>>) {
        statsMap[params.itemIds[i]] = response.data; // failed items are skipped
      }
    }
    return statsMap;
  },
);
```

**Data Structure**:
```dart
// Community statistics from backend
{
  "total_ratings": 5,
  "average_rating": 4.2,
  "item_id": 123
}
```

**Widget Usage**:
```dart
RatingSummaryCard(
  item: cheeseItem, // Provider fetches stats automatically by item id
  itemType: 'cheese',
)
```

**Cache Invalidation**:
```dart
// On pull-to-refresh or data updates
ref.invalidate(communityStatsProvider); // Clears all cached stats
```

#### SharedRatingsList (Recommendations)
**Location**: `lib/widgets/items/shared_ratings_list.dart`

**Features**:
- Shows ratings shared by other users with green color identity
- Shows the author display name from the rating (`rating.authorName`)
- Displays notes or localized placeholder for all ratings
- Empty state messaging for items without recommendations

#### Compact UI Design System
**Location**: `lib/screens/items/item_type_screen.dart`

**Space Optimization Features**:
- Inline rating badges positioned after item titles
- Removed redundant title boxes and verbose descriptions
- Compact pill-style indicators instead of card layouts
- Mobile-optimized design showing 2-3x more items per screen

**Badge System**:
- Personal: `👤 5.0` (purple - your own ratings)
- Recommendations: `👍 2` (green - friend suggestions)
- Community: `👥 4.5 (3)` (orange - anonymous community aggregate)
- No ratings: Clean item appearance without clutter

#### Color Identity System
**Location**: `lib/utils/constants.dart`

**Visual Distinction Strategy**:
- **Personal Ratings** (Deep Purple): Your own experiences and opinions
- **Recommendations** (Green): Ratings shared by friends specifically with you
- **Community Ratings** (Orange): Anonymous community averages and counts

**Applied Consistently Across**:
- List view badges and indicators
- Detail view rating sections
- Action button colors (share button uses green)
- Background colors and borders for rating containers

### 6. Integration Points

#### Item Detail Screen
**Location**: `lib/screens/items/item_detail_screen.dart`

**Data Loading Strategy**:
- Loads the user's visible ratings via `getRatingsByViewer()` (includes shared ratings)
- Separates personal vs shared ratings for proper display
- Note: `getRatingsByItem()` exists in the service but is not used by this screen

#### Item Type Screen
**Location**: `lib/screens/items/item_type_screen.dart`

**Personal List Enhancements**:
- Remembers the last active tab (defaults to "All Items")
- Distinguishes personal ratings vs recommendations visually
- Shows side-by-side personal + recommendations for same item
- Clear visual indicators (person icon for personal, thumbs up for recommendations)

#### Home Screen
**Location**: `lib/screens/home/home_screen.dart`

**Metrics Calculation**:
- Counts unique rated items instead of total ratings
- Accurate reference list statistics
- Proper aggregation of personal + shared item counts

## Technical Architecture

### State Management
**Provider**: `lib/providers/rating_provider.dart`

**Key Methods**:
- `createRating()` - Create new ratings with validation
- `updateRating()` - Edit existing ratings with ownership checks
- `shareRating()` - Share ratings with specific users (batch support)
- `unshareRatingFromUsers()` - Remove sharing from specific users (batch support)
- `makeAllRatingsPrivate()` - Bulk remove all sharing from all ratings
- `removeUserFromAllShares()` - Bulk unshare specific user from all ratings
- `loadRatingsByViewer()` - Load user's complete reference list
- `loadRatingsForCurrentUser()` - Reload ratings after auth changes

### API Integration
**Service**: `lib/services/rating_service.dart`

**Endpoints Used**:
- `POST /api/rating/new` - Create rating
- `PUT /api/rating/:id` - Update rating
- `PUT /api/rating/:id/share` - Share rating with users (batch: `user_ids` array)
- `PUT /api/rating/:id/hide` - Unshare rating from users (batch: `user_ids` array)
- `GET /api/rating/viewer/:id` - Get user's complete rating list (personal + shared)
- `GET /api/stats/community/:id` - Get community stats for one item
- `PUT /api/rating/bulk/private` - Make all user's ratings private
- `PUT /api/rating/bulk/unshare/:userId` - Remove user from all shares

### Data Models
**Rating Model**: `lib/models/rating.dart`

**Key Properties**:
- `id`, `grade`, `note`, `authorId`, `itemId`
- `author`, `viewers` - Populated relations from backend (`cheese` is a legacy dynamic field kept for backward compatibility)
- Extension methods for UI convenience (`starRating`, `authorName`, etc.)

## User Experience Flow

### Personal Reference Lists
1. **User creates ratings** for items they've tried
2. **Ratings appear in "My List"** with personal indicators
3. **Users can edit/share** their ratings anytime
4. **Reference list grows** with personal opinions and recommendations

### Collaborative Sharing
1. **User shares rating** via dialog interface
2. **Recipient sees rating** in "Recommendations" section
3. **Visual distinction** between personal vs recommended items
4. **Combined reference lists** include both personal and shared content

### Item Discovery
1. **"All Items" tab** shows community ratings and statistics
2. **Item detail pages** show comprehensive rating information
3. **Users can rate** items directly from detail views
4. **Community feedback** encourages rating participation

## Localization Coverage

### French-First Experience
All rating features fully localized with natural French phrasing:
- Rating creation/editing forms
- Sharing interface and feedback
- Error messages and validation
- Empty states and placeholders
- User fallback text patterns

### Key Localized Elements
- **Form Labels**: "Votre Évaluation", "Ajoutez vos notes"
- **Actions**: "Modifier l'Évaluation", "Partager l'Évaluation"  
- **Feedback**: "Évaluation partagée avec succès!"
- **Sections**: "Mon Évaluation", "Recommandations"
- **Empty States**: "Aucune note ajoutée", "Aucune Recommandation"

## Error Handling & Edge Cases

### Validation
- Rating range validation (0.5-5.0 in practice; see above)
- Ownership checks for editing/sharing
- User selection validation for sharing
- Network connectivity awareness

### Offline Behavior
- Clear messaging about offline limitations
- Cached data display where possible
- Graceful degradation of sharing features

### Data Consistency
- Automatic refresh after rating operations
- Cross-screen state synchronization
- Duplicate prevention in merged rating lists

## Performance Optimizations

### Parallel Loading

- Community stats: the batch provider issues one request per item id with `Future.wait()` (`lib/providers/community_stats_provider.dart`)
- Privacy settings: item types load in parallel with `Future.wait()` (`lib/screens/settings/privacy_settings_screen.dart`)
- Requests are multiplexed over one connection only where the platform provides HTTP/2 (e.g. browsers); the default Dio adapter on mobile/desktop is HTTP/1.1. The speed-up figures in code comments were not measured.

### Current Implementation
- Provider-based caching with 5-minute TTL
- Real-time user lookups for name resolution
- Manual data refresh patterns
- Client-side filtering and aggregation

### Future Enhancement Opportunities
- Additional caching strategies for frequently accessed data
- Lazy loading for large rating lists
- Optimistic updates for better perceived performance

## Navigation Patterns

### Safe Navigation Integration
All rating screens use SafeNavigation helpers:
- `goBackFromRatingCreation()` - Always returns to item detail
- `goBackFromRatingEdit()` - Context-aware navigation  
- Crash-proof navigation with smart fallbacks
- Deep links are not configured (no VIEW intent-filter)

### Route Structure
- `/rating/create/:itemType/:itemId` - Rating creation
- `/rating/edit/:ratingId` - Rating editing
- Proper parameter validation and error handling

## Integration with Generic Architecture

### RateableItem Interface
Ratings work with any item type implementing the RateableItem interface:
- Type-safe rating associations
- Extensible to future item categories
- Zero refactoring needed for new item types

### Provider Patterns
- Generic ItemProvider works with rating integration
- Reactive updates across all related providers
- Clean separation of concerns between item and rating management

## Current Status

**Completed Features**:
- ✅ Rating creation with star picker and notes
- ✅ Rating editing with change detection and pre-populated forms
- ✅ Rating sharing with user selection dialog
- ✅ **Rating unsharing with checkbox deselection and "Make Private" button**
- ✅ **Batch unsharing operations (multiple users at once)**
- ✅ **Bulk privacy actions (make all private, remove user from all shares)**
- ✅ Rating deletion with confirmation and sharing impact warnings
- ✅ Personal vs shared rating visual distinction with color coding
- ✅ Comprehensive localization (French/English)
- ✅ Cross-screen data consistency and automatic refresh
- ✅ Fullscreen offline screen when the server is unreachable
- ✅ Safe navigation patterns with context-aware fallbacks
- ✅ Compact UI design optimized for mobile browsing
- ✅ Color-coded rating identity system
- ✅ Username resolution for shared ratings
- ✅ Complete CRUD functionality for ratings
- ✅ **Privacy settings integration with progressive item loading**

**Ready for Enhancement**:
- Sharing status indicators ("shared with X people") in rating display
- Quick share to recent contacts
- Performance optimization with additional caching layers
- Enhanced discovery features (recommendations based on ratings)

The rating system provides a complete collaborative experience where users can build personal reference lists enhanced by recommendations from friends, with full French localization and robust error handling throughout.
