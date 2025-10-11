# Notification System Standards and Implementation

**Last Updated**: January 2025  
**Status**: Production-Ready - NotificationHelper Implemented

## Overview

The A la carte app features a unified notification system that provides consistent, professional user feedback across all features. This document covers the notification design standards, implementation patterns, and localization requirements.

## Notification Design Standards

### Visual Design System

#### Unified Success Notification Style
All success notifications use the floating design with check circle icons:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
    backgroundColor: Colors.green,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(milliseconds: 2000),
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
);
```

#### Error Notification Style
Error notifications maintain consistency with appropriate warning colors:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(errorMessage),
    backgroundColor: AppConstants.warningColor,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
);
```

### Design Specifications

#### Success Notifications
- **Icon**: `Icons.check_circle` (24px, white)
- **Background**: `Colors.green`
- **Text**: White, FontWeight.w600
- **Duration**: 2000ms (2 seconds)
- **Behavior**: Floating with 16px margins
- **Shape**: Rounded corners (8px radius)

#### Error Notifications  
- **Background**: `AppConstants.warningColor` (consistent app error color)
- **Text**: White, standard weight
- **Duration**: 3000ms (3 seconds, longer for errors)
- **Behavior**: Floating with 16px margins
- **Shape**: Rounded corners (8px radius)

#### Loading Notifications
- **Background**: `Colors.blue` or theme primary
- **Duration**: 30 seconds (for long operations)
- **Dismissible**: Can be cleared manually when operation completes

## Implementation Patterns

### Sharing Operation Notifications

#### 1. Rating Sharing (Item Details)
**Location**: `lib/widgets/items/my_rating_section.dart`

**Messages**:
```dart
// Share with new users
message = context.l10n.shareRatingSuccess;
// "Rating shared successfully!"

// Unshare from users  
message = context.l10n.ratingUnsharedFromUsers(removeFromUserIds.length);
// "Rating unshared from X users" (with proper pluralization)

// Mixed operations
message = context.l10n.sharingPreferencesUpdated;
// "Sharing preferences updated successfully"
```

#### 2. Privacy Settings Sharing
**Location**: `lib/screens/settings/privacy_settings_screen.dart`

**Uses same messages** with identical styling for consistency across interfaces.

### Settings Update Notifications

#### 1. Discoverable Toggle
```dart
// Enable discoverability
context.l10n.discoverabilityEnabled
// "You are now discoverable for sharing"

// Disable discoverability
context.l10n.discoverabilityDisabledWithExplanation  
// "You are no longer discoverable. Existing shared ratings remain accessible."
```

#### 2. Profile Updates
```dart
// Display name update
context.l10n.displayNameUpdated
// "Display name updated successfully"

// Account deletion
context.l10n.accountDeleted
// "Account deleted successfully"
```

### Bulk Operation Notifications

#### 1. Make All Ratings Private
```dart
// Loading state
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(context.l10n.makingRatingsPrivate),
    duration: const Duration(seconds: 30),
  ),
);

// Success state
context.l10n.allRatingsMadePrivate
// "All ratings are now private"
```

#### 2. Remove User from All Shares
```dart
// Loading state
context.l10n.removingUserFromShares(userName)
// "Removing Alice from shares..."

// Success state  
context.l10n.userRemovedFromShares(userName, ratingsAffected)
// "Alice removed from 5 ratings"
```

## Localization Requirements

### Complete Bilingual Support

All notification messages must be available in both English and French:

#### English Messages (app_en.arb)
```json
{
  "shareRatingSuccess": "Rating shared successfully!",
  "ratingUnsharedFromUsers": "Rating unshared from {count} {count, plural, =1{user} other{users}}",
  "sharingPreferencesUpdated": "Sharing preferences updated successfully",
  "discoverabilityEnabled": "You are now discoverable for sharing",
  "discoverabilityDisabledWithExplanation": "You are no longer discoverable. Existing shared ratings remain accessible."
}
```

#### French Messages (app_fr.arb)
```json
{
  "shareRatingSuccess": "Évaluation partagée avec succès !",
  "ratingUnsharedFromUsers": "Évaluation non partagée avec {count} {count, plural, =1{utilisateur} other{utilisateurs}}",
  "sharingPreferencesUpdated": "Préférences de partage mises à jour avec succès",
  "discoverabilityEnabled": "Vous êtes maintenant découvrable pour le partage",
  "discoverabilityDisabledWithExplanation": "Vous n'êtes plus découvrable. Les évaluations partagées existantes restent accessibles."
}
```

### Message Parameterization

#### Count-Based Messages
Use ICU message format for proper pluralization:
```json
{
  "ratingsCount": "{count} {count, plural, =1{rating} other{ratings}}",
  "recipientsCount": "{count} {count, plural, =1{recipient} other{recipients}}"
}
```

#### User Name Interpolation
```json
{
  "removingUserFromShares": "Removing {userName} from shares...",
  "userRemovedFromShares": "{userName} removed from {count} {count, plural, =1{rating} other{ratings}}"
}
```

## Usage Guidelines

### When to Show Notifications

#### Always Show For:
- **User-initiated actions**: Settings changes, rating operations
- **State changes**: Authentication status, connectivity changes  
- **Bulk operations**: Mass privacy actions, data operations
- **Error conditions**: Failed operations, network issues

#### Never Show For:
- **Automatic background operations**: Connectivity monitoring, token refresh
- **Silent updates**: Cache updates, preloading
- **Navigation actions**: Screen transitions, back navigation

### Duration Guidelines

#### Success Notifications: 2 seconds
- Quick positive feedback
- Doesn't interfere with workflow
- Long enough to read and acknowledge

#### Error Notifications: 3 seconds  
- More time to read error details
- Allows user to understand what went wrong
- Provides time to plan next action

#### Loading Notifications: 30 seconds
- For long-running operations
- Manually dismissed when operation completes
- Prevents timeout confusion

## NotificationHelper Implementation

**Location**: `lib/utils/notification_helper.dart`  
**Status**: ✅ Production-Ready (January 2025)

The NotificationHelper class provides a centralized, reusable implementation of all notification patterns:

```dart
class NotificationHelper {
  /// Show success notification (green, check icon, 2s)
  static void showSuccess(BuildContext context, String message)
  
  /// Show error notification (warning color, dismissible, 3s)
  static void showError(BuildContext context, String message)
  
  /// Show loading notification (blue, spinner, 30s)
  static void showLoading(BuildContext context, String message)
  
  /// Show error with theme color (alternative)
  static void showErrorFromTheme(BuildContext context, String message)
}
```

### Implementation Benefits

**Code Quality**:
- ✅ **~200 lines removed**: Eliminated boilerplate across 8 files
- ✅ **Single line calls**: `NotificationHelper.showSuccess(context, message)`
- ✅ **Type-safe**: Static methods with clear signatures
- ✅ **Maintainable**: Update once, changes everywhere

**Coverage**:
- ✅ Rating CRUD (create, update, delete)
- ✅ Sharing operations (share, unshare)
- ✅ Privacy settings (discoverability, bulk actions)
- ✅ Profile management (display name updates)
- ✅ Account operations (deletion)

### Usage in Components

**Simple and consistent**:

```dart
// In any widget or screen
NotificationHelper.showSuccess(context, context.l10n.shareRatingSuccess);
NotificationHelper.showError(context, context.l10n.shareRatingError);
NotificationHelper.showLoading(context, context.l10n.processingRequest);
```

**Example in context**:
```dart
// Success after operation
if (success) {
  NotificationHelper.showSuccess(context, context.l10n.ratingCreated);
}

// Error handling
if (error != null) {
  NotificationHelper.showError(context, error);
}

// Loading for long operations
NotificationHelper.showLoading(context, context.l10n.makingRatingsPrivate);
// ... perform operation ...
ScaffoldMessenger.of(context).clearSnackBars(); // Dismiss when done
NotificationHelper.showSuccess(context, context.l10n.allRatingsMadePrivate);
```

## Cross-Platform Considerations

### Mobile Optimization
- **Floating behavior**: Better on mobile than fixed snackbars
- **Proper margins**: 16px provides touch-friendly spacing
- **Readable duration**: 2-3 seconds optimal for mobile reading speed

### Desktop Compatibility
- **Same design works**: Floating notifications work well on desktop
- **Keyboard accessibility**: Can be dismissed with Escape key
- **Multi-window support**: Notifications stay within app window

### Web Compatibility
- **Responsive design**: Notifications adapt to browser width
- **PWA integration**: Works in installed web apps
- **Cross-browser**: Consistent appearance across browsers

## Quality Assurance

### Notification Testing Checklist

#### Visual Consistency
- [ ] All success notifications have green background with check icon
- [ ] All error notifications have warning color background
- [ ] Floating behavior works across all platforms
- [ ] Text is readable in both light and dark themes
- [ ] Icons are properly sized (24px) and white colored

#### Localization Coverage
- [ ] All notification messages exist in both English and French
- [ ] Pluralization works correctly for count-based messages
- [ ] Parameter interpolation works (user names, counts)
- [ ] French messages use natural phrasing, not literal translations

#### Functional Testing
- [ ] Notifications appear for all user actions
- [ ] Durations are appropriate (2s success, 3s error)
- [ ] Multiple notifications handle properly (no overlap)
- [ ] Notifications clear appropriately
- [ ] Loading notifications dismiss when operations complete

### Error Scenarios Testing
- [ ] Network errors show appropriate messages
- [ ] API failures provide actionable feedback
- [ ] Partial failures (some operations succeed) handle correctly
- [ ] Offline operations provide clear guidance

## Migration from Previous Notification Styles

### Before: Manual Boilerplate (Deprecated)
```dart
// Old pattern - don't use anymore
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: TextStyle(...))),
      ],
    ),
    backgroundColor: Colors.green,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(milliseconds: 2000),
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
); // 17 lines of boilerplate!
```

### After: NotificationHelper (Current)
```dart
// Current pattern - use everywhere
NotificationHelper.showSuccess(context, context.l10n.operationSuccess); // 1 line!
NotificationHelper.showError(context, context.l10n.operationError);
```

### Migration Status

✅ **Fully migrated** (January 2025) - All manual notifications replaced with NotificationHelper

**Files updated**:
- `lib/widgets/items/my_rating_section.dart`
- `lib/widgets/settings/profile_info_widget.dart`
- `lib/screens/rating/rating_create_screen.dart`
- `lib/screens/rating/rating_edit_screen.dart`
- `lib/screens/settings/privacy_settings_screen.dart`
- `lib/screens/settings/user_settings_screen.dart`

**Code reduction**: ~200 lines of boilerplate eliminated

## Benefits of Unified System

### User Experience
- **Professional appearance**: Consistent, polished design across app
- **Clear visual hierarchy**: Success (green) vs error (red) distinction
- **Improved readability**: Icons provide immediate context
- **Better accessibility**: Proper contrast and timing

### Developer Experience
- **Reduced boilerplate**: Helper methods eliminate repetitive code
- **Consistent behavior**: Same notification patterns everywhere
- **Easy maintenance**: Central styling that can be updated globally
- **Quality assurance**: Standardized testing checklist

### Internationalization
- **Complete coverage**: All user feedback properly localized
- **Natural phrasing**: French messages sound natural, not translated
- **Parameter handling**: Proper pluralization and interpolation
- **Maintainability**: Centralized message management

This notification system provides a professional, consistent user experience that enhances the overall quality and polish of the A la carte application.
