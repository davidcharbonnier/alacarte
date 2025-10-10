# Router Architecture and Navigation Best Practices

## Overview

The A la carte app uses Go Router with a sophisticated authentication-aware routing system that provides stable navigation while preventing unwanted redirects during state updates. This document covers the router architecture, navigation patterns, and best practices for maintaining stable routing behavior.

## Router Architecture

### Core Design Principles

#### 1. Targeted State Watching
Instead of watching entire provider states, the router uses focused selectors to prevent unnecessary rebuilds:

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  // Only watch specific auth properties that matter for routing
  final isAuthenticated = ref.watch(authProvider.select((state) => state.isAuthenticated));
  final needsProfileSetup = ref.watch(authProvider.select((state) => state.needsProfileSetup));
  final hasUser = ref.watch(authProvider.select((state) => state.user != null));
  
  // Router only rebuilds when these specific values change
  return GoRouter(/* ... */);
});
```

#### 2. Stable Redirect Logic
The redirect function is designed to only trigger on meaningful authentication state changes:

```dart
redirect: (context, state) {
  final currentLocation = state.uri.path;
  
  // Clear authentication flow
  if (!isAuthenticated) {
    if (currentLocation == RouteNames.auth) return null;
    return RouteNames.auth;
  }
  
  // Profile setup flow
  if (hasUser && needsProfileSetup) {
    if (currentLocation == RouteNames.displayNameSetup) return null;
    return RouteNames.displayNameSetup;
  }
  
  // Authenticated users accessing auth screens -> redirect to app
  if (currentLocation == RouteNames.auth || 
      currentLocation == RouteNames.displayNameSetup) {
    return RouteNames.home;
  }
  
  return null; // No redirect needed for authenticated users in app
}
```

### Why This Architecture Works

#### Problem Solved
**Before**: Router watched entire `authProvider` state, causing rebuilds when:
- User profile updates (display name, discoverable setting)
- Rating state changes
- Any auth-related data modification

**After**: Router only watches specific authentication flags, preventing rebuilds during:
- Settings updates
- Profile modifications
- Non-authentication-related state changes

#### Benefits
- **Stable navigation**: Settings screens stay active during updates
- **Better performance**: Fewer router rebuilds
- **Predictable behavior**: Navigation only changes for actual auth state transitions
- **Maintainable code**: Clear separation between routing concerns and data updates

## Navigation Patterns

### Safe Navigation Helper

The app uses `SafeNavigation` utility for crash-proof navigation with smart fallbacks:

```dart
// Context-aware navigation methods
SafeNavigation.goBack(context);                              // Smart back with fallback
SafeNavigation.goBackFromRatingCreation(context, itemType, itemId); // To item detail
SafeNavigation.goBackToItemDetail(context, itemType, itemId);       // Specific item
SafeNavigation.goBackToItemType(context, itemType);                // To item list
SafeNavigation.goBackToHub(context);                               // To home screen
```

#### Key Features
- **Automatic fallback routes** when `pop()` is not available
- **Context-aware routing** based on current screen and user intent
- **Error handling** with graceful degradation
- **Deep link support** consistent across entry points
- **Cross-platform compatibility** for web, desktop, mobile

### Navigation Flow Patterns

#### 1. Authentication Flow
```
/auth → (OAuth) → /setup? → /home
```
- Users start at authentication screen
- Optional profile setup if incomplete
- Redirect to main app when ready

#### 2. Main App Navigation
```
/home → /items/:type → /items/:type/:id → /rating/create/:type/:id
  ↓         ↓              ↓                      ↓
Settings  Item List    Item Detail          Rating Creation
```

#### 3. Settings Navigation
```
/home → /settings → /privacy
  ↓        ↓           ↓
 App   User Settings Privacy Controls
```

## Common Navigation Issues and Solutions

### Issue 1: Unwanted Redirects During Settings Updates

#### Problem
Updating user settings (like discoverable toggle) caused navigation away from settings screen.

#### Root Cause
Router was watching entire `authProvider` state, so any user object update triggered router rebuild.

#### Solution
```dart
// Before (problematic)
final authState = ref.watch(authProvider);

// After (stable)
final isAuthenticated = ref.watch(authProvider.select((state) => state.isAuthenticated));
final needsProfileSetup = ref.watch(authProvider.select((state) => state.needsProfileSetup));
final hasUser = ref.watch(authProvider.select((state) => state.user != null));
```

### Issue 2: Navigation Crashes on Edge Cases

#### Problem
Direct navigation or browser back button could cause navigation crashes.

#### Solution
Use `SafeNavigation` helper with fallback logic:

```dart
// Instead of direct GoRouter calls
GoRouter.of(context).pop(); // Can crash if no previous route

// Use safe navigation
SafeNavigation.goBack(context); // Always has fallback
```

### Issue 3: Inconsistent Navigation Behavior

#### Problem
Different screens had different back button behaviors.

#### Solution
Standardized navigation patterns:

```dart
// Rating creation always returns to item detail
SafeNavigation.goBackFromRatingCreation(context, itemType, itemId);

// Item detail returns to item type list
SafeNavigation.goBackToItemType(context, itemType);

// Settings return to hub
SafeNavigation.goBackToHub(context);
```

## Best Practices

### 1. Provider Watching in Routers
```dart
// ✅ Good: Watch specific values only
final isAuthenticated = ref.watch(authProvider.select((state) => state.isAuthenticated));

// ❌ Avoid: Watching entire provider state
final authState = ref.watch(authProvider);
```

### 2. State Updates in Settings
```dart
// ✅ Good: Isolated state updates
Consumer(
  builder: (context, ref, child) {
    final user = ref.watch(authProvider.select((state) => state.user));
    return Switch(
      value: user?.discoverable ?? false,
      onChanged: (value) => _updateSetting(context, ref, value),
    );
  },
);

// ❌ Avoid: Direct state watching that triggers rebuilds
```

### 3. Navigation Error Handling
```dart
// ✅ Good: Safe navigation with fallbacks
SafeNavigation.goBackToItemType(context, 'cheese');

// ❌ Avoid: Direct navigation without error handling
GoRouter.of(context).go('/items/cheese');
```

### 4. Conditional Redirects
```dart
// ✅ Good: Clear, minimal redirect logic
if (!isAuthenticated) {
  return currentLocation == RouteNames.auth ? null : RouteNames.auth;
}

// ❌ Avoid: Complex nested conditions that cause unexpected redirects
```

## Router Provider Architecture

### Provider Dependencies
```dart
appRouterProvider depends on:
├── authProvider.select(isAuthenticated)
├── authProvider.select(needsProfileSetup)  
└── authProvider.select(hasUser)

// Does NOT depend on:
├── authProvider.user.displayName
├── authProvider.user.discoverable
├── ratingProvider
└── itemProvider
```

### State Change Handling
- **Authentication changes**: Full router rebuild (necessary)
- **Profile setup changes**: Full router rebuild (necessary)
- **User data changes**: No router rebuild (stable)
- **Settings updates**: No router rebuild (stable)
- **Rating updates**: No router rebuild (stable)

## Testing Navigation

### Unit Testing Navigation Logic
```dart
testWidgets('Router should not redirect during settings updates', (tester) async {
  // Set up authenticated state
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith((ref) => MockAuthNotifier()..setAuthenticated()),
    ],
  );
  
  // Navigate to settings
  final router = container.read(appRouterProvider);
  router.go('/settings');
  
  // Update user setting
  container.read(authProvider.notifier).updateDiscoverable(true);
  
  // Should still be on settings screen
  expect(router.routerDelegate.currentConfiguration.uri.path, '/settings');
});
```

### Manual Testing Checklist
- [ ] Settings toggle doesn't navigate away
- [ ] Back navigation works from all screens
- [ ] Deep links work correctly
- [ ] Browser back button behaves properly
- [ ] Authentication flow redirects appropriately
- [ ] No navigation crashes on edge cases

## Migration Guide

### From Basic Router to Stable Router

#### 1. Identify Problematic Provider Watching
Look for routers that watch entire provider states:
```dart
// Find patterns like this
final someState = ref.watch(someProvider);
```

#### 2. Replace with Targeted Selectors
```dart
// Replace with specific value watching
final specificValue = ref.watch(someProvider.select((state) => state.specificField));
```

#### 3. Test Navigation Stability
- Verify settings updates don't cause unwanted navigation
- Test all navigation flows still work correctly
- Check that authentication redirects still function

#### 4. Update Navigation Calls
Replace direct GoRouter calls with SafeNavigation where appropriate:
```dart
// Before
GoRouter.of(context).pop();

// After  
SafeNavigation.goBack(context);
```

This router architecture provides a stable, predictable navigation experience while maintaining all necessary authentication and security controls.
