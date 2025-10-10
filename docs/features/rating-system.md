# Rating System Implementation

## Overview

The A la carte rating system enables users to create, edit, share, and manage ratings for items across multiple categories. The implementation focuses on personal reference lists enhanced by collaborative sharing between users.

## Core Features Implemented

### 1. Rating Creation
**Location**: `lib/screens/rating/rating_create_screen.dart`

**User Flow**:
- User navigates to item detail → Clicks "Rate [ItemName]" FAB
- Form loads with item context card showing item details
- User selects star rating (1-5, 0 allowed for disliked items)
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

### 3. Rating Sharing
**Location**: `lib/widgets/rating/share_rating_dialog.dart`

**User Flow**:
- User clicks "Share Rating" button in MyRatingSection
- Dialog opens showing list of available users (excluding current user)
- User selects recipients via checkboxes
- Sharing request sent to backend with proper data format
- Success feedback and automatic data refresh

**Technical Implementation**:
- ShareRatingDialog loads all users and filters appropriately
- Backend integration with proper request format (`ViewerID` field)
- Cross-references user list for actual usernames vs "User #X" fallbacks
- Localized user fallback text when usernames unavailable
- Comprehensive error handling and visual feedback

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
- Backend handles cleanup of shared rating relationships

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
- **Automatic Caching**: Stats cached per (itemType, itemId) pair - no duplicate API calls
- **Optimized data source**: Uses `/api/stats/community/:type/:id` endpoint
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
final communityStatsProvider = FutureProvider.family<Map<String, dynamic>, CommunityStatsParams>(
  (ref, params) async {
    final apiService = ref.watch(apiServiceProvider);
    final response = await apiService.getCommunityStats(params.itemType, params.itemId);

    // Use direct type checking as documented in README
    if (response is ApiSuccess<Map<String, dynamic>>) {
      return response.data;
    } else if (response is ApiError<Map<String, dynamic>>) {
      throw Exception('Failed to load community stats: ${response.message}');
    }
    
    throw Exception('Unexpected loading state');
  },
);
```

**Data Structure**:
```dart
// Community statistics from backend
{
  "total_ratings": 5,
  "average_rating": 4.2,
  "item_type": "cheese",
  "item_id": 123
}

// Convenient extension methods
stats.totalRatings  // int
stats.averageRating // double
```

**Widget Usage**:
```dart
RatingSummaryCard(
  item: cheeseItem,
  itemType: 'cheese', // Provider fetches stats automatically
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
- Resolves actual usernames from available user cache
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
- Community: `👥 4.5 (3)` (orange - public ratings)
- No ratings: Clean item appearance without clutter

#### Color Identity System
**Location**: `lib/utils/constants.dart`

**Visual Distinction Strategy**:
- **Personal Ratings** (Deep Purple): Your own experiences and opinions
- **Recommendations** (Green): Ratings shared by friends specifically with you
- **Community Ratings** (Orange): General public ratings and averages

**Applied Consistently Across**:
- List view badges and indicators
- Detail view rating sections
- Action button colors (share button uses green)
- Background colors and borders for rating containers

### 5. Integration Points

#### Item Detail Screen
**Location**: `lib/screens/items/item_detail_screen.dart`

**Data Loading Strategy**:
- Loads community ratings via `getRatingsByItem()`
- Loads user's viewer ratings via `getRatingsByViewer()`
- Merges both sources to ensure shared ratings appear
- Separates personal vs shared ratings for proper display

#### Item Type Screen
**Location**: `lib/screens/items/item_type_screen.dart`

**Personal List Enhancements**:
- Defaults to "My List" tab for improved UX
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
- `shareRating()` - Share ratings with specific users
- `loadRatingsByViewer()` - Load user's complete reference list
- `loadRatingsByItem()` - Load community ratings for specific items

### API Integration
**Service**: `lib/services/rating_service.dart`

**Endpoints Used**:
- `POST /rating/new` - Create rating
- `PUT /rating/:id` - Update rating
- `PUT /rating/:id/share` - Share rating (expects `ViewerID` in request body)
- `GET /rating/viewer/:id` - Get user's complete rating list (personal + shared)
- `GET /rating/:itemType/:id` - Get all community ratings for item

### Data Models
**Rating Model**: `lib/models/rating.dart`

**Key Properties**:
- `id`, `grade`, `note`, `authorId`, `itemId`, `itemType`
- `author`, `viewers`, `cheese` - Populated relations from backend
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
- Rating range validation (0.0-5.0)
- Ownership checks for editing/sharing
- User selection validation for sharing
- Network connectivity awareness

### Offline Behavior
- Clear messaging about offline limitations
- Cached data display where possible
- Smart user switching with connectivity awareness
- Graceful degradation of sharing features

### Data Consistency
- Automatic refresh after rating operations
- Cross-screen state synchronization
- Proper handling of user switches
- Duplicate prevention in merged rating lists

## Performance Considerations

### Current Implementation
- Individual API calls per item for community ratings
- Real-time user lookups for name resolution
- Manual data refresh patterns
- Client-side filtering and aggregation

### Future Enhancement Opportunities
- Batch loading of community ratings
- Caching strategies for frequently accessed data
- Lazy loading for large rating lists
- Optimistic updates for better perceived performance

## Navigation Patterns

### Safe Navigation Integration
All rating screens use SafeNavigation helpers:
- `goBackFromRatingCreation()` - Always returns to item detail
- `goBackFromRatingEdit()` - Context-aware navigation  
- Crash-proof navigation with smart fallbacks
- Deep link support for rating URLs

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
- Rating creation with star picker and notes
- Rating editing with change detection and pre-populated forms
- Rating sharing with user selection dialog and username resolution
- Rating deletion with confirmation and sharing impact warnings
- Personal vs shared rating visual distinction with color coding
- Comprehensive localization (French/English)
- Cross-screen data consistency and automatic refresh
- Offline-aware behavior with smart user switching
- Safe navigation patterns with context-aware fallbacks
- Compact UI design optimized for mobile browsing
- Color-coded rating identity system
- Username resolution for shared ratings
- Complete CRUD functionality for ratings

**Ready for Enhancement**:
- Rating unsharing (make rating private again)
- Sharing status indicators ("shared with X people")
- Bulk sharing capabilities
- Performance optimization with caching
- Enhanced discovery features

The rating system provides a complete collaborative experience where users can build personal reference lists enhanced by recommendations from friends, with full French localization and robust error handling throughout.
