# Privacy Model Documentation - Frontend

## Table of Contents
- [Privacy Philosophy](/docs/client/privacy-model.md#privacy-philosophy)
- [Rating Visibility Models](/docs/client/privacy-model.md#rating-visibility-models)
- [Display Name System](/docs/client/privacy-model.md#display-name-system)
- [User Discovery Architecture](/docs/client/privacy-model.md#user-discovery-architecture)
- [Sharing System Implementation](/docs/client/privacy-model.md#sharing-system-implementation)
- [Privacy Controls](/docs/client/privacy-model.md#privacy-controls)
- [Privacy Settings Screen](/docs/client/privacy-model.md#privacy-settings-screen)
- [User Experience Flows](/docs/client/privacy-model.md#user-experience-flows)
- [Frontend Architecture](/docs/client/privacy-model.md#frontend-architecture)
- [Testing & Validation](/docs/client/privacy-model.md#testing--validation)
- [Migration from Profile System](/docs/client/privacy-model.md#migration-from-profile-system)

---
**Last Updated:** September 2025  
**Related Documentation:**
- [Authentication System](authentication-system.md)
- [Rating System](rating-system.md)
- **Backend Privacy Model** - See `rest-api/docs/privacy-model.md`
---

## Privacy Philosophy

À la carte implements a **privacy-first rating system** designed around the core principle that personal taste preferences should remain private by default, with explicit user control over sharing.

### Core Privacy Principles

1. **Private by Default** - All ratings start as personal reference entries
2. **Explicit Sharing** - Users must actively choose to share specific ratings
3. **Identity Control** - Users control how they appear to others via display names
4. **Selective Discovery** - Users opt-in to being discoverable for new sharing relationships
5. **Relationship-Based** - Sharing builds natural networks without complex friend systems

### Privacy vs Social Balance

```
Privacy ←------------------→ Social
   ↑                          ↑
Personal         Selective     Community
Reference        Sharing       Discovery
Lists            
   ↑                          ↑
Default          Opt-in        Anonymous
State            Control       Aggregates
```

**The privacy model enables:**
- ✅ **Honest personal ratings** - No social pressure affecting taste preferences
- ✅ **Selective recommendation sharing** - Share only what you want with who you want
- ✅ **Natural network building** - Relationships form through sharing activity
- ✅ **Community insights** - Anonymous aggregate data for discovery
- ✅ **Zero spam potential** - Cannot contact users without explicit sharing relationship

## Rating Visibility Models

### Three-Tier Visibility System

#### **Tier 1: Personal (Private)**
- **Visibility**: Only the rating author
- **Purpose**: Personal reference and taste tracking
- **Default**: All new ratings start here
- **Display Location**: "My Rating" section in item details

#### **Tier 2: Shared (Selective)**
- **Visibility**: Rating author + specifically selected users
- **Purpose**: Recommendations to trusted individuals
- **Mechanism**: Explicit sharing action required
- **Display Location**: "Recommendations" section for recipients

#### **Tier 3: Community (Anonymous Aggregates)**
- **Visibility**: Statistical aggregates only, no individual attribution
- **Purpose**: General community insights and trends
- **Data**: Average ratings, distribution, counts
- **Display Location**: "Community" section with anonymous statistics

### Implementation Architecture

```dart
// lib/models/rating_visibility.dart
enum RatingVisibility {
  private('private'),
  shared('shared'),
  public('public'); // Future feature

  const RatingVisibility(this.value);
  final String value;
}

// Rating display logic
class RatingDisplayService {
  static List<Rating> getVisibleRatings(
    List<Rating> allRatings,
    int currentUserId,
    RatingVisibility visibilityFilter,
  ) {
    return allRatings.where((rating) {
      switch (visibilityFilter) {
        case RatingVisibility.private:
          return rating.userId == currentUserId;
        case RatingVisibility.shared:
          return rating.userId != currentUserId && 
                 rating.isVisibleToUser(currentUserId);
        case RatingVisibility.public:
          return rating.visibility == RatingVisibility.public;
      }
    }).toList();
  }
}
```

## Display Name System

### Purpose & Design

Display names solve the privacy challenge of showing user identity in shared ratings while protecting real personal information.

### Display Name Generation

```dart
// lib/utils/display_name_generator.dart
class DisplayNameGenerator {
  /// Generates privacy-friendly display name from full name
  static String generateFromFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    
    if (parts.length == 1) {
      return parts[0]; // Just first name
    }
    
    final firstName = parts[0];
    final lastInitial = parts.last[0].toUpperCase();
    
    return '$firstName $lastInitial.';
  }
  
  /// Validates display name meets requirements
  static String? validateDisplayName(String displayName) {
    final trimmed = displayName.trim();
    
    if (trimmed.isEmpty) {
      return 'Display name is required';
    }
    
    if (trimmed.length < 2) {
      return 'Display name must be at least 2 characters';
    }
    
    if (trimmed.length > 50) {
      return 'Display name must be 50 characters or less';
    }
    
    // Check for inappropriate content (basic implementation)
    if (_containsInappropriateContent(trimmed)) {
      return 'Display name contains inappropriate content';
    }
    
    return null;
  }
  
  static bool _containsInappropriateContent(String name) {
    // Basic implementation - in production, use more sophisticated filtering
    final inappropriate = ['admin', 'system', 'null', 'undefined'];
    return inappropriate.any((word) => 
        name.toLowerCase().contains(word.toLowerCase()));
  }
}
```

## User Discovery Architecture

### Discovery Modes

Users appear in sharing dialogs based on two criteria:
1. **Discoverable Users** - Users who opted into being discoverable
2. **Previous Connections** - Users who have shared ratings with current user

### Smart Discovery Implementation

```dart
// lib/services/user_discovery_service.dart
class UserDiscoveryService {
  final UserService _userService;
  final RatingService _ratingService;

  UserDiscoveryService(this._userService, this._ratingService);

  /// Gets users available for sharing with current user
  Future<ShareableUsersResponse> getShareableUsers() async {
    final currentUserId = await _getCurrentUserId();
    
    // Get users who have shared with current user
    final previousConnections = await _getPreviousConnections(currentUserId);
    
    // Get discoverable users (excluding current user and previous connections)
    final discoverable = await _getDiscoverableUsers(
      currentUserId, 
      previousConnections.map((u) => u.id).toList(),
    );
    
    return ShareableUsersResponse(
      previousConnections: previousConnections,
      discoverable: discoverable,
    );
  }

  Future<List<User>> _getPreviousConnections(int currentUserId) async {
    // Get users who have shared ratings with current user
    final sharedRatings = await _ratingService.getRatingsByViewer(currentUserId);
    
    // Extract unique user IDs (excluding current user)
    final userIds = sharedRatings
        .where((rating) => rating.userId != currentUserId)
        .map((rating) => rating.userId)
        .toSet()
        .toList();
    
    if (userIds.isEmpty) return [];
    
    return await _userService.getUsersByIds(userIds);
  }

  Future<List<User>> _getDiscoverableUsers(
    int currentUserId, 
    List<int> excludeIds,
  ) async {
    return await _userService.getDiscoverableUsers(
      excludeUserId: currentUserId,
      excludeIds: excludeIds,
    );
  }
}
```

## Privacy Settings Screen (Updated September 2025)

À la carte features a comprehensive privacy management screen that provides users with complete control over their rating sharing and personal information visibility.

### **🔒 Privacy Dashboard Features (Production Ready)**

#### **Privacy Overview Section**
Provides users with a clear overview of their current sharing activity:
- **Shared Ratings Count** - Total number of ratings shared with others
- **Recipients Count** - Number of unique people who can see ratings
- **Visual Summary Card** - Highlighted container with key metrics
- **Real-time Updates** - Counts update immediately after privacy actions

#### **Discovery Settings Control**
Users control whether they appear in sharing dialogs:
- **Toggle Control** - Simple on/off switch for user discoverability
- **Clear Explanation** - Describes what discoverability means
- **Immediate Feedback** - Success/error messages for setting changes
- **Server Synchronization** - Changes synced with backend immediately

### **⚡ Bulk Privacy Actions (Fully Implemented)**

#### **Make All Ratings Private**
**Status: ✅ Production Ready**
- **One-Click Privacy** - Remove sharing from all ratings at once
- **Warning Dialog** - Multi-step confirmation with impact preview
- **Loading States** - "Making ratings private..." during processing
- **Success Feedback** - Confirmation with affected ratings count
- **Error Handling** - Graceful error messages with retry capability
- **UI Refresh** - Automatic screen updates after completion

#### **Remove Person from All Shares**
**Status: ✅ Production Ready**
- **User Selection Dialog** - Lists all people you've shared ratings with
- **Real User Avatars** - Shows actual profile pictures from user data
- **Impact Preview** - Shows how many ratings each person can access
- **Confirmation Flow** - Double-confirmation before removing user
- **Batch Processing** - Removes user from all shared ratings efficiently
- **Real-time Feedback** - Success messages with affected counts

### **📝 Enhanced Individual Rating Management**

#### **Full List Display with Filtering**
**Status: ✅ Implemented - No 5-Item Limit**
- **Complete Visibility** - Shows all shared ratings directly on privacy screen
- **Item Type Filters** - Clean FilterChip system: "All (6)", "Fromage (6)"
- **Real-time Filtering** - Instant list updates when switching filters
- **Future-Ready** - Automatic filter creation for wine, beer, coffee item types
- **No Popups Required** - Everything accessible from main privacy screen

#### **Individual Rating Controls**
- **Direct Management** - Manage sharing for each rating individually
- **Real User Avatars** - Actual profile pictures in all sharing dialogs
- **Enhanced Sharing Dialog** - Shows current sharing state with visual indicators
- **Context Preservation** - Manage sharing without leaving privacy settings

### **🎨 User Experience Enhancements**

#### **Real User Avatars (September 2025)**
- **Network Images** - Loads actual user profile pictures from backend
- **Graceful Fallbacks** - Shows user initials if avatar fails to load
- **Consistent Styling** - Maintains app's design language
- **Performance Optimized** - Efficient image loading with error handling

#### **Clean Filter System**
- **Simple Design** - No colors or icons, just clean FilterChip buttons
- **Dynamic Counts** - Real-time count updates: "All (6)", "Fromage (6)"
- **Consistent Pattern** - Matches filtering system used elsewhere in app
- **Extensible** - Ready for multiple item types without code changes

### **🔧 Technical Implementation (Updated)**

#### **Backend Integration**
```dart
// Bulk privacy operations
Future<Map<String, dynamic>> makeAllRatingsPrivate() async {
  return handleResponse<Map<String, dynamic>>(
    put(ApiConfig.ratingBulkPrivate),
    (json) => json as Map<String, dynamic>,
  );
}

Future<Map<String, dynamic>> removeUserFromAllShares(int userId) async {
  return handleResponse<Map<String, dynamic>>(
    put(ApiConfig.ratingBulkUnshare(userId)),
    (json) => json as Map<String, dynamic>,
  );
}
```

#### **State Management**
```dart
// Privacy provider methods
class RatingNotifier extends StateNotifier<RatingState> {
  Future<Map<String, dynamic>> makeAllRatingsPrivate() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _ratingService.makeAllRatingsPrivate();
    // Handle response and refresh UI
  }
  
  Future<Map<String, dynamic>> removeUserFromAllShares(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _ratingService.removeUserFromAllShares(userId);
    // Handle response and refresh UI
  }
}
```

#### **User Interface Architecture**
```dart
// Enhanced privacy settings with filtering
class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  String _selectedItemTypeFilter = 'all'; // Filter state
  
  Widget _buildItemTypeFilters() {
    return Wrap(
      children: [
        FilterChip(
          label: Text(context.l10n.allFilterOption + ' (${total})'),
          selected: _selectedItemTypeFilter == 'all',
          onSelected: (selected) => setState(() => _selectedItemTypeFilter = 'all'),
        ),
        // Dynamic filters for each item type
      ],
    );
  }
}
```

### **🌍 Complete Localization**

#### **Filter System Localization**
- **All Filter**: "All" → "Tous" (French)
- **Item Types**: "Cheese" → "Fromage" (French)
- **Anonymous Users**: "Anonymous User" → "Utilisateur Anonyme" (French)

#### **Bulk Action Messages**
```dart
// Localized bulk action feedback
context.l10n.makingRatingsPrivate        // "Privatisation des évaluations..."
context.l10n.allRatingsMadePrivate       // "Toutes les évaluations sont maintenant privées"
context.l10n.removingUserFromShares      // "Suppression de {user} des partages..."
context.l10n.userRemovedFromShares       // "{user} retiré de {count} évaluations"
```

### **📊 Current Implementation Status**

**✅ Fully Implemented Features:**
- **Bulk Make All Private** - Production-ready bulk privacy action
- **Bulk Remove User** - Production-ready user removal from all shares
- **Individual Rating Management** - Enhanced sharing dialog with real avatars
- **Item Type Filtering** - Clean filter system ready for multiple item types
- **Progressive Item Loading** - Smart background loading of missing item data
- **Real User Avatars** - Actual profile pictures in all privacy dialogs
- **Complete Localization** - Full French/English support for all features
- **Error Handling** - Comprehensive error recovery and user feedback

**🎯 User Experience Benefits:**
- **No Artificial Limits** - Shows complete list of all shared ratings
- **Clean Visual Design** - Removed clutter, focused on essential information
- **Efficient Workflows** - All privacy management in one screen
- **Professional Feedback** - Clear success/error messages with action counts
- **Context-Safe Dialogs** - Robust dialog handling preventing crashes
- **Real-time Updates** - UI refreshes immediately after privacy actions

### **🔧 Technical Implementation**

#### **Context Management**
Robust context handling prevents BuildContext validation errors:

```dart
// Proper dialog context separation
void _confirmRemoveUser(BuildContext context, WidgetRef ref, int userId, String userName) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      // Use dialogContext for dialog-specific UI
      title: Text(dialogContext.l10n.removeUserFromShares),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.l10n.cancel),
        ),
      ],
    ),
  );
  
  // Use original context for subsequent operations
  if (confirmed == true && context.mounted) {
    // Show loading and perform API call
  }
}
```

#### **Error Handling & User Feedback**
```dart
// Enhanced error handling with user-friendly messages
try {
  final result = await ref.read(ratingProvider.notifier).removeUserFromAllShares(userId);
  
  if (context.mounted) {
    final ratingsAffected = result['ratings_affected'] as int? ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.userRemovedFromShares(userName, ratingsAffected)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
} catch (e) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.errorRemovingUserFromShares),
        backgroundColor: AppConstants.warningColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
```

### **🌍 Localization Support**

Complete French and English localization for all privacy features:

**Privacy Overview:**
- `privacyOverview` - "Aperçu de la Confidentialité" / "Privacy Overview"
- `yourSharingActivity` - "Votre Activité de Partage" / "Your Sharing Activity"
- `sharedRatingsCount` - "évaluations partagées" / "shared ratings"
- `recipientsCount` - "destinataires" / "recipients"

**Discovery Settings:**
- `discoverySettings` - "Paramètres de Découverte" / "Discovery Settings"
- `discoverableForSharing` - "Découvrable pour le Partage" / "Discoverable for Sharing"
- `discoverabilityExplanation` - "Contrôle qui peut vous trouver lors du partage" / "Control who can find you when sharing"

**Bulk Actions:**
- `bulkPrivacyActions` - "Actions de Confidentialité en Lot" / "Bulk Privacy Actions"
- `makeAllRatingsPrivate` - "Rendre Toutes les Évaluations Privées" / "Make All Ratings Private"
- `removePersonFromAllShares` - "Retirer une Personne de Tous les Partages" / "Remove Person from All Shares"

### **📊 Privacy Analytics**

The privacy screen provides users with clear metrics about their sharing activity:

- **Real-time Calculations** - All counts computed from current data
- **Unique Recipient Tracking** - Deduplicates users across multiple shared ratings
- **Impact Awareness** - Users understand the scope of privacy actions
- **Historical Context** - Shows long-term sharing relationships

```dart
// Helper methods for privacy analytics
Set<String> _getUniqueRecipients(List<Rating> sharedRatings) {
  final recipients = <String>{};
  
  for (final rating in sharedRatings) {
    if (rating.viewers != null && rating.viewers is List) {
      final viewers = rating.viewers as List;
      for (final viewer in viewers) {
        if (viewer is Map<String, dynamic> && viewer['id'] != rating.authorId) {
          final displayName = viewer['display_name'] as String? ?? 'Anonymous User';
          recipients.add(displayName);
        }
      }
    }
  }
  
  return recipients;
}

int _countRatingsSharedWithUser(List<Rating> sharedRatings, int userId) {
  int count = 0;
  for (final rating in sharedRatings) {
    if (rating.viewers != null && rating.viewers is List) {
      final viewers = rating.viewers as List;
      if (viewers.any((viewer) => viewer['id'] == userId)) {
        count++;
      }
    }
  }
  return count;
}
```

The Privacy Settings Screen provides users with complete transparency and control over their personal data sharing, following privacy-by-design principles while maintaining an intuitive and accessible user interface.

### User Privacy Settings Screen

```dart
// lib/screens/user/privacy_settings_screen.dart
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.privacySettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Discovery settings
          _buildDiscoverySection(user),
          
          const SizedBox(height: 24),
          
          // Display name settings
          _buildDisplayNameSection(user),
          
          const SizedBox(height: 24),
          
          // Data management
          _buildDataManagementSection(),
        ],
      ),
    );
  }

  Widget _buildDiscoverySection(User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.explore,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.discoverySettings,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: Text(context.l10n.allowDiscovery),
              subtitle: Text(context.l10n.allowDiscoveryExplanation),
              value: user.discoverable,
              onChanged: _updateDiscoverability,
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.howSharingWorks,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.sharingExplanation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Frontend Architecture

### Provider Structure

```dart
// lib/providers/providers.dart (Privacy-related providers)

// User discovery for sharing
final userDiscoveryServiceProvider = Provider<UserDiscoveryService>((ref) {
  return UserDiscoveryService(
    ref.read(userServiceProvider),
    ref.read(ratingServiceProvider),
  );
});

// Current user's privacy settings
final userPrivacySettingsProvider = FutureProvider<UserPrivacySettings>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('User not authenticated');
  
  return ref.read(userServiceProvider).getPrivacySettings(user.id);
});

// Shareable users for current user
final shareableUsersProvider = FutureProvider<ShareableUsersResponse>((ref) async {
  return ref.read(userDiscoveryServiceProvider).getShareableUsers();
});

// Community statistics (anonymous)
final communityStatsProvider = FutureProvider.family<CommunityStats, (String, int)>(
  (ref, params) async {
    final (itemType, itemId) = params;
    return ref.read(ratingServiceProvider).getCommunityStats(itemType, itemId);
  },
);
```

## Testing & Validation

### Privacy Logic Testing

```dart
// test/utils/rating_visibility_test.dart
void main() {
  group('RatingVisibilityUtils Tests', () {
    late Rating ownRating;
    late Rating sharedRating;
    late Rating privateRating;
    late User currentUser;
    late User otherUser;

    setUp(() {
      currentUser = User(id: 1, displayName: 'Test User');
      otherUser = User(id: 2, displayName: 'Other User');
      
      ownRating = Rating(
        id: 1,
        userId: currentUser.id,
        grade: 5.0,
        note: 'Great!',
      );
      
      sharedRating = Rating(
        id: 2,
        userId: otherUser.id,
        grade: 4.0,
        note: 'Good',
        viewers: [currentUser], // Shared with current user
      );
      
      privateRating = Rating(
        id: 3,
        userId: otherUser.id,
        grade: 3.0,
        note: 'Okay',
        viewers: [], // Not shared
      );
    });

    test('user can see their own ratings', () {
      expect(
        RatingVisibilityUtils.isRatingVisibleToUser(ownRating, currentUser.id),
        isTrue,
      );
    });

    test('user can see ratings shared with them', () {
      expect(
        RatingVisibilityUtils.isRatingVisibleToUser(sharedRating, currentUser.id),
        isTrue,
      );
    });

    test('user cannot see private ratings from others', () {
      expect(
        RatingVisibilityUtils.isRatingVisibleToUser(privateRating, currentUser.id),
        isFalse,
      );
    });
  });
}
```

---

**This privacy model provides a comprehensive, user-friendly approach to managing personal taste preferences while enabling selective social sharing. The implementation prioritizes user control and transparency while maintaining the app's core philosophy of building personal reference lists.**

## Recent Enhancements (September 2025)

### **Progressive Item Loading in Privacy Settings**

The privacy settings screen now features an innovative progressive loading system:

#### **Smart Data Loading**
- **Immediate Display**: Shows localized fallbacks ("fromage #1") instantly
- **Background Enhancement**: Loads missing item data automatically
- **Real Names**: Updates to show actual item names ("Cheddar (Hard)")
- **Multi-Item Ready**: Supports cheese, wine, beer, coffee with minimal code changes

#### **Type Differentiation**
- **Minimal Type Badges**: Small [FROMAGE] badges for visual differentiation
- **Neutral Styling**: Subtle, non-distracting design
- **Localized**: Automatically adapts to French/English
- **Future-Proof**: Ready for multiple item types

#### **Direct Sharing Access**
- **Context Preservation**: Manage sharing without leaving privacy settings
- **Full Functionality**: Complete sharing dialog integration
- **Real-time Updates**: Changes reflected immediately
- **Better UX**: No navigation friction for privacy management

### **Widget Architecture Improvements**

#### **Modular Components**
- **Settings Widget Library**: Reusable components for consistent UI
- **Reduced Duplication**: Common patterns extracted to widgets
- **Better Maintainability**: Settings changes in one location
- **Enhanced Testing**: Individual components can be unit tested

#### **Clean Screen Architecture**
- **Focused Screens**: Business logic separated from UI components
- **Simplified Files**: Settings screens reduced from 1400+ to ~350 lines
- **Reusable Patterns**: Components work across multiple settings screens
- **Consistent Styling**: Unified design language throughout settings
