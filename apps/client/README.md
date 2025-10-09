# A la carte

[![📱 Android CI/CD Pipeline](https://github.com/davidcharbonnier/alacarte-client/actions/workflows/android-release.yml/badge.svg)](https://github.com/davidcharbonnier/alacarte-client/actions/workflows/android-release.yml)

**Your personal rating and preference hub**

A la carte is a sophisticated rating platform designed to help you curate and discover your preferences across various categories. Starting with cheese ratings, the app is built with extensibility in mind to support additional item categories in the future.

## 🎯 Project Vision

A la carte enables users to:
- **Build personal reference lists** of rated items for future reference
- **Rate and review** items with personal notes and scores
- **Receive shared ratings** from others to expand your reference list
- **Track** your rating history and personal preferences
- **Discover** new items through secondary discovery features

### **🚀 Google OAuth Authentication System**

A la carte features a production-ready Google OAuth authentication system that provides secure user authentication across all platforms:

#### **Architecture Components**
```dart
AuthScreen                     # Clean Google OAuth interface
  ├── Native Google sign-in UI (Android/Web)
  ├── Error handling with user-friendly messages
  ├── Loading states with proper feedback
  └── Automatic navigation to profile setup or main app

AuthService                    # Google OAuth integration
  ├── Real Google Sign-In with google_sign_in package
  ├── Cross-platform token management (serverClientId approach)
  ├── Backend token exchange with complete error handling
  └── Secure sign-out with proper cleanup

AuthProvider                   # OAuth state management
  ├── JWT token storage with automatic refresh
  ├── User profile management with Google data
  ├── Profile completion workflow integration
  └── Connectivity-aware authentication validation
```

#### **Authentication Flow**
1. **🔐 Google OAuth** - Native sign-in UI with Google accounts
2. **🔄 Token Exchange** - Frontend sends Google tokens to backend API
3. **✅ Backend Validation** - Real Google tokeninfo API validation + profile extraction
4. **🎫 JWT Generation** - Backend returns application JWT for API access
5. **👤 Profile Setup** - Display name configuration with privacy controls
6. **🏠 App Access** - Authenticated access to all A la carte features

#### **Cross-Platform OAuth Strategy**
- **Web App**: Direct web client OAuth with redirect flow
- **Android App**: Native Google sign-in with serverClientId for backend compatibility
- **Backend**: Single validation logic using web client ID for all platforms
- **Security**: Real Google token validation with audience verification

#### **OAuth Configuration**
```dart
// Centralized configuration in app_config.dart
static const String googleWebClientId = 'your-web-client-id.apps.googleusercontent.com';

// Cross-platform Google Sign-In setup
GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: AppConfig.googleWebClientId, // Backend compatibility
)
```

#### **Developer Benefits**
- **Production Security**: Real Google OAuth with enterprise-grade token validation
- **Clean Architecture**: Zero mock code, single OAuth flow
- **Complete Profile Data**: Names, avatars, email from Google accounts
- **Cross-Platform**: Same authentication experience on web and mobile
- **Error Handling**: Clear error messages and graceful failure recovery
- **Privacy Ready**: OAuth-based user accounts with privacy controls

### **🌐 Fullscreen Offline Handling System**

A la carte features a sophisticated offline handling system that provides clear communication and seamless recovery when connectivity issues occur:

#### **Architecture Components**
```dart
ApiService                  # Unified connectivity monitoring
  ├── Platform connectivity detection (connectivity_plus)
  ├── API health validation (/health endpoint)
  ├── Reactive timeout detection (API call failures)
  └── Periodic server checking (30s when server unreachable)

FullscreenOfflineScreen     # Professional offline messaging
  ├── Context-aware messaging (network vs server issues)
  ├── Localized content (French/English)
  ├── Retry functionality with immediate connectivity check
  └── Professional design matching app theme

ConnectivityProvider        # Simple stream provider
  ├── Three-state connectivity model
  ├── Automatic app-level routing control
  └── Background connectivity monitoring
```

#### **Three-State Connectivity Model**
1. **🟢 Online** - Network + API both accessible → Normal app functionality
2. **🔴 Network Offline** - No network connection → "No Internet Connection" screen
3. **🟠 Server Offline** - Network OK, API unreachable → "Server Unavailable" screen

#### **Reactive Connectivity Detection**
- **Platform-native monitoring** - Uses connectivity_plus for instant network change detection
- **API-specific validation** - Health checks validate A la carte server specifically
- **Timeout-triggered checks** - Only checks connectivity when API calls actually fail
- **Periodic validation** - 30-second checks when network available but server unreachable

#### **App-Level Protection**
```dart
// In main.dart - protects ALL screens automatically
MaterialApp.router(
  builder: (context, child) {
    return connectivityState.when(
      data: (state) => state == ConnectivityState.online 
          ? child  // Normal app
          : FullscreenOfflineScreen(state), // Offline overlay
      // ...
    );
  },
)
```

#### **Automatic API Retry System**
```dart
// Auth provider listens to connectivity restoration
void _listenToConnectivity() {
  _ref.listen(connectivityStateProvider, (previous, next) {
    if (next.value == ConnectivityState.online && 
        previous?.value != ConnectivityState.online) {
      // Automatically revalidate user when connectivity returns
      _handleConnectivityRestored();
    }
  });
}
```

#### **User Experience Benefits**
- **Universal Coverage** - Every screen automatically protected
- **Clear Communication** - Professional messaging explaining connectivity issues
- **Automatic Recovery** - Failed API calls retry when connectivity returns
- **No Failed Operations** - Users never see timeout errors or broken functionality
- **Seamless Restoration** - Normal app functionality resumes immediately

#### **Localized Offline Experience**

**English Messages:**
- **"No Internet Connection"** - Network troubleshooting guidance
- **"Server Unavailable"** - Maintenance/server issue explanation
- **"Connected"** - Positive confirmation when restored

**French Messages:**
- **"Pas de Connexion Internet"** - Native French technical terminology
- **"Serveur Indisponible"** - Professional server status messaging
- **"Connecté"** - Natural French confirmation

#### **Debug Logging**
```bash
# Comprehensive connectivity logging
🔍 Checking initial connectivity...
📱 Platform connectivity results: [ConnectivityResult.wifi]
🌍 Network available - checking API reachability...
🎧 Testing API reachability: http://localhost:8080/api/health
📊 API health check response: 200
✅ API server reachable - going online
🟢 🌐 Connected to A la carte - app fully functional

# Automatic retry logging
⚡ API timeout detected - triggering immediate connectivity check
🔄 Connectivity restored - will revalidate user authentication
✅ User revalidation successful
```

#### **Technical Implementation**
- **No per-screen connectivity checks** - App-level protection eliminates complexity
- **Reactive detection only** - Connectivity checked when API calls actually fail
- **Efficient monitoring** - Platform-native detection with minimal overhead
- **Smart retry logic** - Failed operations automatically retry when online

#### **Developer Benefits**
- **Zero boilerplate** - No offline handling needed in individual screens
- **Clean architecture** - Single source of truth for app availability
- **Easy debugging** - Comprehensive logging shows exact connectivity flow
- **Simple testing** - Binary online/offline scenarios only

**Performance Characteristics:**
- **Zero overhead** on successful API calls
- **Instant detection** of network changes via platform APIs
- **Smart validation** - Only checks server when network issues detected
- **Minimal resource usage** - No constant connectivity polling

## 🚀 Performance Optimizations

A la carte implements sophisticated performance optimizations to ensure efficient resource usage and fast user experience:

### **📋 Service-Level Caching**

#### **Intelligent API Response Caching**
```dart
// CheeseItemService with 5-minute TTL cache
class CheeseItemService {
  ApiResponse<List<CheeseItem>>? _cachedResponse;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  Future<ApiResponse<List<CheeseItem>>> getAllItems() async {
    // Return cached data if still valid
    if (_isValidCache()) return _cachedResponse!;
    
    // Fetch fresh data and cache result
    final response = await handleListResponse(...);
    _cacheResponse(response);
    return response;
  }
}
```

#### **Cache Benefits**
- **Eliminated Duplicate API Calls**: Reduced from 3+ calls to 1 call per session
- **Filter Options Performance**: Types and origins extracted from cached data
- **Automatic Invalidation**: Cache cleared when data is modified
- **Memory Efficient**: Only successful responses are cached

### **🔄 Provider Loading Guards**

#### **Smart Loading State Management**
```dart
class ItemState<T> {
  final bool hasLoadedOnce; // Prevents redundant loading
  
  // Provider only loads if never loaded before
  if (!state.isLoading && !state.hasLoadedOnce) {
    await loadItems(); // Single load per provider instance
  }
}
```

#### **Lazy Loading Pattern**
- **Constructor Optimization**: Providers don't auto-load data on creation
- **On-Demand Loading**: Data loaded only when screens explicitly request it
- **Duplicate Prevention**: `hasLoadedOnce` flag prevents redundant API calls
- **Refresh Capability**: Separate `refreshItems()` method for user-initiated updates

### **🌐 Network Efficiency**

#### **Connectivity Debouncing**
```dart
// Prevents duplicate health checks from Android connectivity events
static Timer? _debounceTimer;

static Future<void> _handleConnectivityChange(results) async {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    _processConnectivityChange(results);
  });
}
```

#### **Network Optimization Benefits**
- **Reduced Health Checks**: Android's duplicate connectivity events debounced
- **Smart State Handling**: Null connectivity treated as "potentially online"
- **Efficient Monitoring**: Only check server when platform indicates network changes
- **Resource Conservation**: No constant polling or redundant validation

### **📊 Community Statistics Caching (October 2025)**

#### **Riverpod Provider-Based Caching**
```dart
// Community stats provider with automatic caching
final communityStatsProvider = FutureProvider.family<Map<String, dynamic>, CommunityStatsParams>(
  (ref, params) async {
    final apiService = ref.watch(apiServiceProvider);
    final response = await apiService.getCommunityStats(params.itemType, params.itemId);
    
    // Direct type checking pattern (documented best practice)
    if (response is ApiSuccess<Map<String, dynamic>>) {
      return response.data;
    } else if (response is ApiError<Map<String, dynamic>>) {
      throw Exception('Failed to load community stats: ${response.message}');
    }
    
    throw Exception('Unexpected loading state');
  },
);
```

#### **Implementation Benefits**
- **Zero Duplicate API Calls**: Riverpod caches results per (itemType, itemId) pair automatically
- **Eliminated FutureBuilder Anti-Pattern**: No more futures recreated on every rebuild
- **Automatic Cache Management**: Provider handles caching and lifecycle
- **Manual Invalidation**: `ref.invalidate(communityStatsProvider)` clears cache on refresh
- **Reusable Across App**: Same provider used in item lists and detail screens
- **Proper Error Handling**: AsyncValue handles loading/error/data states

#### **Performance Impact**
- **Before**: N API calls per scroll (FutureBuilder recreated futures)
- **After**: 1 API call per unique item (provider caches results)
- **Cache Lifetime**: Persists across navigation within app session
- **Cache Invalidation**: Only on explicit pull-to-refresh

#### **Architecture Pattern**
```dart
// Item List Screen
Widget _buildCommunityRatingsSummary(int itemId) {
  final statsAsync = ref.watch(
    communityStatsProvider(
      CommunityStatsParams(itemType: widget.itemType, itemId: itemId),
    ),
  );
  
  return statsAsync.when(
    data: (stats) => _buildBadge(stats.totalRatings, stats.averageRating),
    loading: () => _buildLoadingBadge(),
    error: (e, s) => _buildErrorBadge(),
  );
}

// Item Detail Screen - RatingSummaryCard
final statsAsync = ref.watch(
  communityStatsProvider(
    CommunityStatsParams(itemType: itemType, itemId: item.id!),
  ),
);
```

#### **Extension Helper**
```dart
// Convenient extension for accessing stats
extension CommunityStatsExtension on Map<String, dynamic> {
  int get totalRatings => (this['total_ratings'] as int?) ?? 0;
  double get averageRating => (this['average_rating'] as num?)?.toDouble() ?? 0.0;
}
```

### **📊 Performance Metrics**

#### **Before Optimizations**
- Startup API calls: 3+ duplicate `/api/cheese/all` requests
- Connectivity checks: 2+ duplicate health check calls
- Form validation: Delayed button state updates
- Loading time: 1200ms+ with potential infinite loading

#### **After Optimizations**
- Startup API calls: 1 single `/api/cheese/all` request
- Connectivity checks: 1 debounced health check
- Form validation: Real-time button state updates
- Loading time: ~600ms average startup
- Community stats: 1 API call per unique item (provider-cached)

#### **User Experience Improvements**
- **50% faster startup**: Reduced average initialization time
- **Zero duplicate requests**: Eliminated redundant network traffic
- **Responsive forms**: Immediate validation feedback
- **Professional loading**: Smooth transitions without UI flashes
- **Efficient community stats**: No duplicate API calls on scroll/rebuild

### **🔧 Future Enhancement Opportunities**

#### **Advanced Caching Strategy**
- **Offline Persistence**: Extend community stats caching to SharedPreferences/SQLite for offline viewing
- **Batch Loading**: Single API call for all community stats per item type (further optimization)
- **Intelligent Refresh**: Smart cache invalidation based on user actions (e.g., after rating)
- **Progressive Loading**: Critical data first, supplementary data second

#### **Real-Time Features**
- **WebSocket Integration**: Live updates with cache synchronization
- **Optimistic Updates**: Immediate UI updates with background validation
- **Conflict Resolution**: Handle simultaneous edits across devices
- **Performance Monitoring**: Metrics for API patterns and user flows

## 🏗️ Architecture Overview

### **Multi-Project Setup**
- **Frontend** (this repository): Flutter app with web, desktop, and mobile support
- **Backend**: Go REST API with MySQL database (separate repository)
- **Philosophy**: Profile-based access (no complex authentication), personal reference lists

### **Technical Architecture Philosophy**

A la carte follows **Clean Architecture** principles with a **Generic Design Pattern** that enables infinite extensibility without code rewrites:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  📱 Screens (HomeScreen, ItemTypeScreen, UserSelection)    │
│  🧩 Widgets (Reusable UI components)                       │
│  🗺️ Routes (Go Router with type-safe navigation)           │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                   APPLICATION LAYER                         │
│  🔄 Providers (Riverpod state management)                  │
│     • Generic: ItemProvider<T>, ItemState<T>               │
│     • Concrete: CheeseItemProvider, [FutureItemProviders]   │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                   DOMAIN LAYER                              │
│  📋 Models (Data structures and business logic)            │
│     • Abstract: RateableItem interface                     │
│     • Concrete: CheeseItem, [FutureItemImplementations]    │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                INFRASTRUCTURE LAYER                         │
│  🌐 Services (API communication and data persistence)      │
│  ⚙️ Config (Environment and API configuration)             │
│  🛠️ Utils (Extensions, constants, helpers)                 │
└─────────────────────────────────────────────────────────────┘
```

### **Frontend Architecture**
```
lib/
├── 📋 models/           # Generic RateableItem interface + implementations
├── 🔄 providers/        # Riverpod state management (generic + specific)
│   ├── app_initialization_provider.dart  # Async startup logic
│   ├── user_selection_provider.dart      # Enhanced with init errors
│   └── item_provider.dart               # Generic item management
├── 🌐 services/         # API services with type-safe endpoints
├── 🖥️ screens/          # Multi-level navigation with initialization
│   ├── initialization/  # App startup screens
│   ├── home/           # Reference hub dashboard
│   ├── items/          # Item type screens + detail views
│   ├── settings/       # Settings and privacy management screens
│   └── user/           # Profile management with error handling
├── 🧩 widgets/          # Reusable components (forms, cards, error banners)
│   ├── common/         # Shared UI components
│   ├── rating/         # Rating-specific widgets
│   └── settings/       # Settings widget library (NEW)
├── 🗺️ routes/          # Go Router with async initialization routing
├── ⚙️ config/          # Environment and API configuration
└── 🛠️ utils/           # Constants, extensions, and helpers
```

## 🚀 Developer Onboarding Guide

### **Understanding the Codebase**

#### **1. Start Here: Core Concepts**
Before diving into code, understand these fundamental concepts:

- **Personal Reference Lists**: Users build curated lists of items they've rated + items shared with them
- **Generic Architecture**: One codebase supports unlimited item types starting with cheese
- **Profile-Based**: No authentication - users select profiles to access their personal lists
- **Discovery Secondary**: Exploration features help users find new items to add to their lists

#### **2. Key Files to Understand First**
```
📋 lib/models/rateable_item.dart                    # The foundation - generic item interface
🧧 lib/models/cheese_item.dart                      # Concrete implementation example
🔄 lib/providers/item_provider.dart                 # Generic state management pattern
🚀 lib/providers/app_initialization_provider.dart   # NEW: Async startup logic
📱 lib/screens/home/home_screen.dart                # Two-level dashboard entry point
🏗️ lib/screens/initialization/                     # NEW: App startup screens
🌐 lib/services/item_service.dart                   # API communication pattern
🗺️ lib/routes/app_router.dart                       # Updated: Async routing system
```

#### **3. Architecture Deep Dive**

##### **Generic Item System (The Core Innovation)**
```dart
// This is the magic - one interface, infinite implementations
abstract class RateableItem {
  String get itemType;        // 'cheese', 'future_category'
  String get displayTitle;    // UI presentation
  String get searchableText;  // For filtering/search
  Map<String, String> get categories; // For advanced filtering
  Map<String, dynamic> toJson();     // API communication
}

// Adding a new item type is just:
class NewCategoryItem implements RateableItem {
  // Implement interface + category-specific fields
  @override
  String get itemType => 'new_category';
  // ... category-specific fields
}
```

**Why This Works:**
- **Zero Refactoring**: All screens, providers, services work automatically
- **Type Safety**: Generics ensure compile-time correctness
- **Maintainability**: Changes to core logic benefit all item types

##### **State Management Pattern**
```dart
// Generic provider that works with any RateableItem
class ItemProvider<T extends RateableItem> extends StateNotifier<ItemState<T>> {
  Future<void> loadItems() { /* Generic logic */ }
  Future<void> createItem(T item) { /* Generic logic */ }
  // All CRUD operations work with any item type
}

// Concrete providers are simple specializations
final cheeseItemProvider = StateNotifierProvider<CheeseItemProvider, ItemState<CheeseItem>>(
  (ref) => CheeseItemProvider(ref.read(cheeseItemServiceProvider)),
);

// Adding new category providers follows the same pattern
// final newCategoryProvider = StateNotifierProvider<NewCategoryProvider, ItemState<NewCategoryItem>>(...);
```

##### **Two-Level Dashboard Architecture**
```
HomeScreen (Reference Hub)
├── Welcome + User Profile
├── Item Type Cards (Cheese: 45 items, More categories coming soon)
└── Coming Soon Cards (Additional categories)
    ↓ [User clicks "Cheese"]
ItemTypeScreen (Cheese Focus)
├── Tab 1: "All Cheeses" (Discovery - browse all available)
├── Tab 2: "My Cheese List" (Personal - my ratings + shared)
└── FloatingActionButton: "Add Cheese"
```

##### **App Initialization & Navigation Pattern**
```dart
// Async app initialization with robust error handling
class AppRouter {
  // Always start with initialization for async user loading
  initialLocation: RouteNames.initialization,
  
  // Simplified route guards after initialization handles complexity
  redirect: (context, state) {
    if (!hasSelectedUser && isProtectedRoute) {
      return RouteNames.userSelection;
    }
  }
}

// Initialization flow with offline support
AppInitializationProvider:
  ├── Load saved user from SharedPreferences
  ├── Validate with backend (if online) or trust locally (if offline)
  └── Route Decision:
      ├── Valid User → HomeScreen (seamless UX)
      ├── No User → UserSelectionScreen (clean)
      └── Error/Corruption → UserSelectionScreen + Error Banner
```

**App Startup Flow:**
- **All users** start with async initialization screen (~500ms)
- **Returning users with valid profiles** → Direct to home screen
- **First-time users** → Guided to profile creation
- **Profile corruption/errors** → User selection with clear error messages
- **Offline mode** → Trusts saved data, full app functionality

### **Adding a New Item Type: Step-by-Step**

**UPDATED October 2025:** After the Strategy Pattern refactoring, adding item types with full CRUD is easier than ever!

**Time Estimate: ~50 minutes for complete implementation**

For a **detailed step-by-step guide**, see:
- **[📋 Complete Guide →](docs/adding-new-item-types.md)** - Full implementation details
- **[✅ Quick Checklist →](docs/new-item-type-checklist.md)** - Fast reference checklist
- **[🏗️ Form Strategy Pattern →](docs/form-strategy-pattern.md)** - CRUD form implementation

#### **Quick Overview:**

1. **Create Model** (~10 min) - Implement `RateableItem` interface
2. **Create Service** (~10 min) - Extend `ItemService<T>` with caching
3. **Register Provider** (~5 min) - Add to `item_provider.dart`
4. **Create Form Strategy** (~10 min) - Define form fields and validation
5. **Register Strategy** (~1 min) - Add to `ItemFormStrategyRegistry`
6. **Create Form Screens** (~2 min) - Create/Edit screen wrappers
7. **Update Helpers** (~5 min) - Add to `ItemProviderHelper` and `ItemTypeHelper`
8. **Add Routes** (~2 min) - Register create/edit routes
9. **Update Home Screen** (~2 min) - Add item type card
10. **Add Localization** (~5 min) - French/English strings

**Total: ~52 minutes from start to fully working CRUD!**

#### **What Works Automatically:**

Thanks to the generic architecture and Strategy Pattern:

✅ **Item listing** - Both "All Items" and "My List" tabs  
✅ **Item details** - Complete information display  
✅ **Rating system** - Full CRUD for ratings  
✅ **Sharing** - Share ratings with other users  
✅ **Community stats** - Aggregate rating display  
✅ **Navigation** - All routing and safe navigation  
✅ **Offline support** - Connectivity handling  
✅ **Search & filtering** - If enabled for the type  
✅ **Theme support** - Light/dark mode  
✅ **Localization** - French/English switching  

**The Strategy Pattern eliminates form duplication - you just configure fields once!**

### **Development Workflow**

#### **Local Development Setup**
```bash
# 1. Backend first (separate repo)
cd ../rest-api
go run main.go  # Starts on localhost:8080

# 2. Frontend
cd client
flutter run -d linux  # No CORS issues!
```

**Note**: The app now features **async initialization** for optimal user experience:
- **First-time setup**: You'll see an initialization screen, then be guided to create a user profile
- **Returning users**: The app will validate your saved profile and route you directly to your home screen
- **Offline mode**: If offline, the app trusts your saved profile and provides full functionality
- **Error recovery**: Profile corruption or server issues are handled gracefully with clear error messages

#### **Testing New Features**
```bash
# 1. Hot reload for UI changes
# Press 'r' in terminal or save files with hot reload enabled

# 2. Provider state testing
# Use Riverpod Inspector (Flutter Inspector → Riverpod tab)

# 3. API testing
# Check browser network tab or use Postman with backend
```

#### **Navigation Best Practices**
All navigation in the app uses the `SafeNavigation` helper to prevent navigation crashes and ensure consistent user experience:

```dart
// Safe back navigation with fallbacks
SafeNavigation.goBack(context);

// Context-aware navigation methods
SafeNavigation.goBackFromRatingCreation(context, itemType, itemId); // Always to item detail
SafeNavigation.goBackToItemDetail(context, itemType, itemId);       // To specific item detail
SafeNavigation.goBackToItemType(context, itemType);                // To item type list  
SafeNavigation.goBackToHub(context);                               // To home screen
SafeNavigation.goBackToUserSelection(context);                     // To user selection

// Traditional navigation (avoid)
GoRouter.of(context).pop(); // ❌ Can cause crashes
GoRouter.of(context).go('/some-route'); // ❌ No fallback handling

// Safe navigation (recommended)
SafeNavigation.goBackToItemType(context, 'cheese'); // ✅ Always works
```

**Navigation Safety Features:**
- **Automatic fallback routes** when pop() is not available
- **Context-aware routing** based on current screen and user intent
- **Error handling** with graceful degradation to logical screens
- **Deep link support** - consistent behavior regardless of entry point
- **Cross-platform compatibility** - works on web, desktop, mobile
- **Zero navigation crashes** - comprehensive try-catch protection

**Key Navigation Flows:**
- **Rating Creation**: Always returns to item detail screen (shows new rating)
- **Item Detail**: Returns to item type list (cheese list, etc.)
- **Item Type**: Returns to home hub
- **User Management**: Returns to user selection
- **Settings**: Context-aware return to appropriate parent screen

**Implementation Notes:**
- All screens updated to use SafeNavigation methods
- FormScaffold supports custom back navigation via `onBack` parameter
- Navigation logic centralized in `/lib/utils/safe_navigation.dart`
- Backwards compatible - existing navigation still works

#### **User Switching & Data Sync**
The app features intelligent user switching with automatic data synchronization:

```dart
// Smart user switching with connectivity awareness
await userSelectionProvider.selectUser(newUser);
// Automatically:
// - Online: Refreshes user-specific data, preserves cache
// - Offline: Clears user data, shows appropriate messaging
// - Reactive: Ongoing sync when connectivity changes

// Provider reactions to user changes
ref.listen(selectedUserIdProvider, (previous, next) {
  if (previous != next) {
    // Automatic data refresh based on connectivity
    loadDataForNewUser(next);
  }
});
```

**Data Management Strategy:**
- **User-Specific Data**: Ratings, personal lists - refreshed on user switch
- **General Data**: Item catalogs, app config - preserved across switches
- **Offline Handling**: Clear messaging, no failed loading states
- **Performance**: Only refreshes necessary data, smart caching

#### **Code Organization Rules**
- **Models**: Pure data classes with business logic methods
- **Providers**: State management, no UI logic
- **Services**: API communication, no state management
- **Screens**: UI composition, minimal business logic
- **Widgets**: Reusable UI components

#### **Form Development Pattern**
All forms in the app use the standardized `FormScaffold` pattern for consistency:

```dart
// Standard form structure with real-time validation
FormScaffold(
  title: 'Create Rating',
  isLoading: providerState.isLoading,
  onCancel: () => GoRouter.of(context).pop(),
  onSubmit: _submitForm,
  submitButtonText: context.l10n.saveRating,
  isSubmitEnabled: _isFormValid, // Updates in real-time
  connectivityMessage: context.l10n.offlineFormMessage,
  child: Column(
    children: [
      // Form fields here
      StarRatingInput(...),
      TextField(...),
    ],
  ),
)
```

**FormScaffold Benefits:**
- **Consistent Layout**: Standard app bar, connectivity banner, action buttons
- **Real-Time Validation**: Submit buttons enable/disable immediately as users type
- **Loading State Management**: Overlay with loading indicator (manual control)
- **Responsive Design**: Automatic width constraints and safe areas
- **Accessibility**: Proper focus management and screen reader support
- **Error Integration**: Works seamlessly with provider error states
- **Localized Experience**: All validation messages and button states support French/English

**Enhanced Form Validation:**
- **Change Detection**: Forms track modifications to warn about unsaved changes
- **Immediate Feedback**: Button states update instantly when validation conditions are met
- **setState Optimization**: All form field changes trigger proper widget rebuilds
- **Input Sanitization**: Validation checks trimmed content, not raw input

### **Debugging Guide**

#### **Common Issues**
1. **"Provider not found"** → Check provider registration in main.dart
2. **"API call fails"** → Verify backend is running on localhost:8080
3. **"Navigation doesn't work"** → Check route names match in route_names.dart
4. **"State not updating"** → Ensure you're using `.notifier` for mutations
5. **"Always showing offline"** → Check backend `/health` endpoint is responding
6. **"App stuck on initialization screen"** → Check connectivity state returning null instead of online
7. **"Form button stays disabled"** → Ensure form change listeners call setState() for real-time validation
8. **"Duplicate API calls"** → Check if providers auto-load in constructor vs lazy loading
9. **"Loading screen localization errors"** → Run `flutter gen-l10n` after adding new .arb keys

#### **ApiResponse when() Method Pattern**
One of the most common patterns in the codebase is handling `ApiResponse<T>` objects. Here's the correct way to handle them:

**❌ Wrong - Extension methods not always available:**
```dart
// This may cause "isSuccess not defined" errors
if (response.isSuccess) {
  final data = response.dataOrNull!;
}
```

**✅ Correct - Direct type checking:**
```dart
// Always works - direct type checking
if (response is ApiSuccess<List<User>>) {
  final users = response.data;  // Direct property access
  // Process users...
} else if (response is ApiError<List<User>>) {
  final errorMessage = response.message;  // Direct property access
  // Handle error...
}
```

**✅ Alternative - Using when() method:**
```dart
// Pattern matching approach
response.when(
  success: (data, message) {
    // Handle success case
  },
  error: (message, statusCode, errorCode, details) {
    // Handle error case
  },
  loading: () {
    // Handle loading case
  },
);
```

**Why This Matters:**
- **Type Safety**: Direct type checking is always available
- **No Import Issues**: Doesn't depend on extension method availability
- **Clear Intent**: Explicitly shows which response type you're handling
- **Consistent Pattern**: Works the same way throughout the codebase

#### **Debug Tools**
- **Flutter Inspector**: Widget tree and state inspection
- **Riverpod Inspector**: Provider state and dependencies
- **Network Tab**: API call debugging
- **VS Code Extensions**: Flutter, Dart, Riverpod
- **Connectivity Console**: Check `ApiService` logs for connectivity events

#### **Connectivity Debugging**
```dart
// Check current connectivity status
print('Is online: ${ApiService.isOnline}');

// Monitor connectivity changes
ApiService.connectivityStream.listen((isOnline) {
  print('Connectivity changed: $isOnline');
});

// Manual health check
final healthResponse = await apiService.healthCheck();
print('Health check result: ${healthResponse.isSuccess}');
```

### **Testing Strategy**
```dart
// 1. Unit tests for models
test('CheeseItem should serialize correctly', () {
  final cheese = CheeseItem(name: 'Cheddar', type: 'Hard');
  expect(cheese.toJson()['Name'], 'Cheddar');
});

// 2. Provider tests
testWidgets('ItemProvider should load items', (tester) async {
  final container = ProviderContainer(
    overrides: [cheeseItemServiceProvider.overrideWith(MockCheeseService())]
  );
  // Test provider behavior
});

// 3. Widget tests
testWidgets('HomeScreen should show item type cards', (tester) async {
  await tester.pumpWidget(TestApp());
  expect(find.text('Cheese'), findsOneWidget);
});
```

### **Performance Considerations**
- **Lazy Loading**: Providers load data on first access
- **Caching**: Services cache API responses automatically
- **Memory**: Generic providers share code, reducing memory footprint
- **Build Optimization**: Use `const` constructors everywhere possible

### **Next Steps for New Developers**
1. **Run the app** and click through the user flow
2. **Read the core files** listed in "Key Files" section
3. **Try adding a simple new item type** following the step-by-step guide
4. **Implement a missing feature** from the roadmap
5. **Ask questions** - the architecture is designed to be discoverable



#### **Generic Item System**
```dart
// Abstract interface for all rateable items
abstract class RateableItem {
  String get itemType;  // 'cheese', 'future_category', etc.
  String get displayTitle;
  Map<String, dynamic> toJson();
  // ... extensible interface
}

// Concrete implementations
class CheeseItem implements RateableItem { ... }
// Additional item types can be added easily
```

**Benefits:**
- **Single codebase** supports unlimited item types
- **Type-safe** with compile-time guarantees  
- **Zero refactoring** needed to add new categories

#### **Two-Level Dashboard System**
1. **Reference Hub** - Overview of all item types with statistics
2. **Item Type Screens** - Dedicated views per category (cheese, additional categories)
   - "All Items" tab - Community discovery
   - "My List" tab - Personal rated items

#### **Personal Reference List Focus**
1. **User's Rated Items** - Your personal ratings with notes and scores
2. **Shared Ratings** - Items others have shared with you
3. **Combined Reference** - Complete personal list for future reference
   - "What did I think of this cheese?"
   - "What cheeses did my friend recommend?"
   - "Which items should I buy again?"

#### **Discovery Features** (Secondary)
- Browse all available items in the platform
- See community statistics and trends
- Find new items to potentially rate

### **🔄 Offline-Aware User Switching**

A la carte features intelligent user switching that maintains data consistency across connectivity states:

#### **Smart Data Management**
```dart
// Connectivity-aware user switching
UserSelectionProvider:
  ├── Online Switch → Refresh user-specific data (ratings)
  ├── Offline Switch → Clear user data, preserve general data
  └── Reactive Listeners → Automatic sync when connectivity changes

RatingProvider:
  ├── Online → Load new user's ratings via API
  ├── Offline → Clear with appropriate messaging
  └── Auto-refresh → When connectivity restored
```

#### **Behavior by Connectivity State**

**Online User Switch:**
- User switches → Immediate UI update
- Smart refresh → Loads new user's ratings
- Cache preservation → Keeps general data (cheese list)
- Reactive sync → Ongoing automatic updates

**Offline User Switch:**
- User switches → Immediate UI update  
- Data clearing → Removes previous user's ratings
- Offline messaging → Clear feedback about limitations
- Cache preservation → General data still available

**Return Online After Switch:**
- Connectivity restored → Automatic detection
- Reactive refresh → Listeners trigger data reload
- Data sync → Current user's data loads automatically

#### **Data Classification**

**User-Specific Data** (refreshed on switch):
- Personal ratings and notes
- Shared ratings visible to user
- User's reference lists
- Rating statistics

**General Data** (preserved across switches):
- Item catalogs (cheese list, etc.)
- App configuration and preferences
- Connectivity state
- UI theme and language settings

#### **Performance Benefits**
- **Reduced Network Usage** → Only refreshes necessary data
- **Smart Caching** → Preserves non-user-specific data
- **Immediate Feedback** → No waiting for failed offline requests
- **Consistent UX** → Same behavior regardless of connectivity

#### **Error Handling**
- **Clear Messaging** → "Offline - Rating data not available for this user"
- **No Loading Spinners** → Immediate feedback instead of hanging states
- **Graceful Degradation** → Core app functionality remains available
- **Retry Capability** → Manual refresh available when back online

A la carte includes a comprehensive connectivity monitoring system to ensure users understand when they're online or offline:

#### **Real-time Monitoring**
- **Automatic health checks** every 30 seconds to backend `/health` endpoint
- **Connection state tracking** with immediate UI updates
- **Graceful offline handling** with cached data fallbacks

#### **Offline Handling**
- **Fullscreen offline mode** when connectivity is lost
- **Professional messaging** with network vs server issue differentiation
- **Automatic retry** when connectivity returns
- **Localized content** in French and English

#### **Offline Behavior**
- **API calls gracefully fail** with clear error messages
- **Cached data displayed** when available
- **User actions queued** for when connection returns (future enhancement)
- **Clear feedback** about what works offline vs online

## 🚀 Current Implementation Status

### **✅ Completed Features**

#### **Core Platform Complete**
- **Generic Architecture** - Extensible for multiple item types with zero refactoring
- **State Management** - Complete Riverpod setup with generic providers
- **Navigation** - Go Router with route guards and type-safe routing
- **API Integration** - Services connecting to Go REST API backend
- **Two-Level Dashboard** - Hub overview + item-type specific screens
- **Item Detail Views** - Generic detail screens that adapt to any item type
- **Profile System** - User selection and switching without authentication
- **Responsive Design** - Works on desktop, web, and mobile
- **Advanced Search & Filtering** - Complete implementation with mobile-optimized collapsible interface

#### **OAuth Authentication System (Production Ready)**
- **Google OAuth Integration** - Production-ready OAuth flow with JWT token management
- **Mock OAuth for Development** - Test authentication without Google dependency
- **Profile Completion Workflow** - Display name setup with privacy controls
- **JWT Token Storage** - Secure token management with automatic refresh
- **Authentication Middleware** - Seamless integration with existing API calls
- **Privacy-First Model** - User discovery controls and private-by-default ratings

#### **Privacy Settings System (Production Ready - September 2025)**
- **Comprehensive Privacy Dashboard** - Complete privacy management interface with sharing overview
- **Progressive Item Loading** - Smart loading of missing item data with visual feedback
- **Discovery Settings Control** - Toggle user discoverability for sharing dialogs
- **Bulk Privacy Actions (IMPLEMENTED)** - Make all ratings private and remove users from all shares
- **Individual Rating Management** - Full list display with item type filtering (no 5-item limit)
- **Real User Avatars** - Actual profile pictures in all privacy dialogs
- **Item Type Filtering** - Clean FilterChip system ready for multiple item types
- **Privacy Analytics** - Real-time sharing statistics and recipient tracking
- **Context-Safe Implementation** - Robust dialog handling preventing BuildContext errors
- **Complete Localization** - Full French/English support for all privacy features

#### **Enhanced User Interface & Navigation**
- **Clean App Bar Design** - Streamlined interface with connectivity status and user profile only
- **Modular Settings System** - Refactored settings with reusable widget components
- **User Settings Screen** - Comprehensive settings with app preferences, profile management, and account controls
- **Privacy Settings Screen** - Dedicated privacy management with progressive loading and type differentiation
- **Inline Profile Editing** - Modern inline display name editing with smooth transitions
- **Profile Dropdown Menu** - Elegant user menu with settings access and sign-out functionality
- **Settings Widget Library** - Reusable components for consistent settings UI across the app
- **Removed UI Clutter** - Language switcher and theme toggle moved to dedicated settings screen

### **🔄 Current Capabilities**
- **Google OAuth Authentication** - Secure authentication with JWT tokens and profile completion
- **Mock OAuth for Development** - Test-friendly authentication without Google dependency
- **Comprehensive User Settings** - Unified settings screen with app preferences, profile management, and account controls
- **Inline Profile Editing** - Modern inline display name editing with smooth animations and transitions
- **Clean App Bar Interface** - Streamlined design with connectivity status and user profile dropdown
- **User Profile Management** - Display name setup with privacy controls and discoverability settings
- **Async App Initialization** - Seamless startup with offline support and error recovery
- **Personal Reference Lists** - View your rated items and shared ratings with advanced filtering
- **Item Detail Views** - Rich individual item screens with enhanced community statistics
- **Rating CRUD Operations** - Complete rating creation, editing, and deletion with validation
- **Item CRUD Operations** - Create and edit cheese entries with inline form design and full validation
- **Advanced Sharing System** - Share/unshare ratings with users who completed their profiles
- **Enhanced Sharing Dialog** - Clean interface with complete profile filtering
- **Community Statistics Caching** - Riverpod provider-based caching eliminates duplicate API calls
- **Optimized Community Statistics** - Single API endpoint for anonymous aggregate rating data
- **Advanced Search & Filtering System** - Comprehensive filtering with mobile-optimized collapsible interface
- **Context-Aware Filtering** - Different filter types per tab (discovery vs personal list management)
- **Smart Filter Persistence** - Universal filters persist across tabs, tab-specific filters auto-clear
- **Connectivity Awareness** - Real-time online/offline status with contextual messaging
- **Error Handling** - Graceful profile corruption recovery with localized error messages
- **Safe Navigation** - Crash-proof navigation with smart fallbacks and deep link support
- **Theme Switching** - Light/dark mode toggle available on all screens
- **Complete Internationalization** - Full French/English support including all filtering interface
- **Cross-Platform** - Runs on Linux (development), Web (production target), Android (future)
- **Fullscreen Offline Handling** - Professional offline messaging with automatic API retry when connectivity returns

### **📦 Ready for Next Phase**
- **Production OAuth Deployment** - Migrate from mock OAuth to production Google OAuth
- **Enhanced Privacy Controls** - Advanced sharing permissions and audit trails
- **Item Deletion** - Delete cheese entries with proper validation and safety checks
- **Quick Sharing Actions** - One-click sharing buttons directly in item lists
- **Sharing Status Indicators** - Visual indicators showing which ratings are shared/private

## 💱 Advanced Sharing System

A la carte features a sophisticated rating sharing system that allows users to selectively share their personal ratings with specific users or make them private.

### **🔄 Sharing Features**

#### **Smart Sharing Dialog**
- **Current State Visualization** - Pre-checked boxes show who currently has access
- **Selective Control** - Check/uncheck specific users to share or unshare
- **"Make Private" Button** - Instantly unshare from all users with one click
- **Change Detection** - Button only enabled when there are actual changes
- **Batch Operations** - Share with multiple users or unshare from multiple users simultaneously

#### **Sharing Logic**
```dart
// Enhanced sharing with both share and unshare operations
shareRating(shareWithUserIds, removeFromUserIds) {
  // Add new viewers
  for (userId in shareWithUserIds) {
    await ratingService.shareRating(ratingId, [userId]);
  }
  
  // Remove specific viewers  
  for (userId in removeFromUserIds) {
    await ratingService.unshareRatingFromUser(ratingId, userId);
  }
}
```

#### **Backend Integration**
- **Enhanced API Endpoints** - Preload viewer information with ratings
- **Selective Unsharing** - `PUT /rating/:id/hide` with specific `ViewerID`
- **Efficient Data Loading** - Viewer information included in rating responses
- **Polymorphic Support** - Works with any item type (cheese, future categories)

#### **UX Excellence**
- **Contextual Feedback** - Different success messages based on actions taken
- **Error Handling** - Partial success scenarios handled gracefully
- **Localized Interface** - Full French/English support
- **Safe Navigation** - Consistent behavior across all sharing workflows

### **🔒 Privacy Controls**

**Three Sharing States:**
1. **Private** - Only the author can see the rating
2. **Selectively Shared** - Specific users have access
3. **Make Private** - Remove access from all users at once

**Smart State Management:**
- **Initial State Loading** - Dialog shows current sharing status
- **Change Calculation** - App determines what needs to be shared/unshared
- **Atomic Operations** - All changes processed together for consistency

### **📊 Data Architecture**

**Rating Model with Viewers:**
```dart
class Rating {
  final dynamic viewers; // List<User> when populated
  
  // Check if rating is visible to user
  bool isVisibleToUser(int userId) {
    return authorId == userId || 
           (viewers as List).any((v) => v['id'] == userId);
  }
}
```

**Backend Model (Go/GORM):**
```go
type Rating struct {
    gorm.Model
    Grade    float32
    Note     string
    AuthorID int
    Author   User `gorm:"foreignKey:AuthorID"`
    ItemID   int
    Viewers  []User `gorm:"many2many:rating_viewers"`
    ItemType string
}
```

### **📝 Usage Examples**

**Example Sharing Workflows:**

1. **Share with new users:**
   - Open sharing dialog → Check "Emma" and "David" → Save Changes
   - Result: "Rating shared successfully!"

2. **Unshare from specific user:**
   - Open sharing dialog → Uncheck "Emma" → Save Changes  
   - Result: "Rating unshared from 1 user"

3. **Make completely private:**
   - Open sharing dialog → Click "Make Private" → Save Changes
   - Result: "Rating unshared from 3 users"

4. **Mixed operations:**
   - Check "Alice", uncheck "Bob" → Save Changes
   - Result: "Sharing preferences updated successfully"

**Error Scenarios:**
- **Partial failures** - "Shared with 2 of 3 users" when some operations fail
- **Network issues** - Clear error messages with retry options
- **Permission errors** - "You can only share your own ratings"

The sharing system seamlessly integrates with the existing app architecture and maintains the same professional polish and user experience standards throughout.

## 📱 User Settings & Profile Management

A la carte features a comprehensive settings system that centralizes all user preferences and account management in one elegant interface.

### **✨ Settings Features**

#### **Unified Settings Screen**
- **Single page approach** - All settings organized in logical sections within one card
- **App Preferences** - Dark mode toggle and language selection (FR/EN)
- **Profile Management** - Inline display name editing with real-time validation
- **Privacy Controls** - Discoverability settings for sharing functionality
- **Account Management** - Secure account deletion with multi-step confirmation

#### **Modern Inline Editing**
- **Contextual editing** - Edit display name directly in the profile section
- **Smooth transitions** - AnimatedSwitcher provides professional animations
- **Smart validation** - Only makes API calls when values actually change
- **Immediate feedback** - Real-time success/error messages

### **🎨 Design Philosophy**

#### **Clean App Bar Architecture**
```dart
// Streamlined app bar design
AppBar(
  actions: [
    ConnectivityBadge(),        // Connection status
    UserProfileDropdown(),      // Settings access + sign out
  ],
)
```

#### **Benefits of Centralized Settings**
- **Reduced app bar clutter** - Only essential navigation elements
- **Logical organization** - All preferences in one discoverable location
- **Better mobile experience** - More touch-friendly with proper spacing
- **Professional appearance** - Clean, focused interface design

### **🔄 Settings Navigation Flow**
```
Any Screen → Profile Picture → "Settings" → Comprehensive Settings Screen
                                          │
                                    Back Button
                                          │
                                    Hub (Home Screen)
```

### **🛠️ Technical Implementation**

#### **State Management**
```dart
// Inline editing state providers
final _isEditingDisplayNameProvider = StateProvider<bool>((ref) => false);
final _displayNameControllerProvider = StateProvider<TextEditingController>((ref) => TextEditingController());

// Smart state transitions
EditMode: [Avatar] [Text Field] [Save] [Cancel]
DisplayMode: [Avatar] Name + Email [Edit]
```

#### **API Integration**
- **PATCH /api/user/me** - RESTful user profile updates
- **Change detection** - Prevents unnecessary API calls
- **Error handling** - Graceful degradation for missing backend features
- **Immediate UI updates** - Optimistic updates with rollback on error

### **📱 Settings Categories**

**App Preferences:**
- Dark Mode toggle (instant theme switching)
- Language selection (FR/EN with elegant dual-button selector)

**Profile & Account:**
- Profile picture display with initials fallback
- Inline display name editing with validation
- Discoverability toggle for sharing controls
- Secure account deletion with warning dialogs

**About:**
- App version information
- Privacy policy with detailed information about data handling

The settings system provides users with complete control over their A la carte experience while maintaining the app's clean, professional design language.

## 🧀 Item CRUD Management

A la carte features comprehensive item management capabilities that allow users to create and edit cheese entries (and future item types) with a professional, localized interface.

### **✨ Item Management Features**

#### **Create New Items**
- **Accessible from "All Items" tab** - Add button only appears during discovery/browsing
- **Inline card design** - Single card with header, divider, and form fields
- **Full validation** - Required fields with localized error messages
- **Change detection** - Warns before abandoning unsaved work
- **Smart navigation** - Returns to appropriate screen after creation

#### **Edit Existing Items**
- **Contextual edit button** - Located in item header (not AppBar) for better UX
- **Pre-populated forms** - All existing data loaded automatically
- **Flexible type handling** - Text field accepts any cheese type, not limited to dropdown
- **Unsaved changes protection** - Prevents accidental data loss
- **Direct navigation** - Returns to item detail after successful edit

### **🎨 Design Philosophy**

#### **Inline Form Design**
```dart
// Single card matching item detail screen style
Card(
  child: Column(
    children: [
      // Header with icon + title + subtitle
      Row(children: [icon, title, subtitle]),
      Divider(),
      // Form fields with consistent spacing
      ...formFields,
    ],
  ),
)
```

#### **Benefits of Inline Design**
- **Visual consistency** - Matches item detail screen structure
- **Familiar UX** - Users recognize the pattern from other screens
- **Better focus** - Single card keeps attention on the form
- **Scalable design** - Works well for simple and complex forms
- **Mobile-friendly** - Compact layout optimized for smaller screens

### **🌍 Complete Localization**

**Form Elements:**
- **Dynamic titles** - "Modifier Fromage" vs "Edit Cheese"
- **Field hints** - "ex: Mou, Dur, Mi-dur, Bleu" vs "e.g. Soft, Hard, Semi-soft, Blue"
- **Helper text** - "Optionnel - jusqu'à 500 caractères"
- **Error messages** - Context-aware validation with item type
- **Dialog text** - Unsaved changes warnings in both languages

**Smart Parameterization:**
```dart
// Localization strings adapt to item type
context.l10n.editItemType(localizedItemType)  // "Edit Cheese" / "Modifier Fromage"
context.l10n.itemCreated(localizedItemType)   // "Cheese created!" / "Fromage créé!"
context.l10n.enterItemName(itemType)          // "Enter cheese name" / "Entrer le nom du fromage"
```

### **🏗️ Generic Architecture**

#### **Reusable Components**
```dart
// Form fields work for any item type
ItemNameField(itemType: 'cheese')     // Validates cheese names
ItemNameField(itemType: 'wine')       // Will validate wine names
ItemPropertyField(labelText: 'Origin') // Generic property field
ItemDescriptionField()                 // Universal description field
```

#### **Type-Safe Form Screens**
```dart
// Generic screen handles any item type
GenericItemFormScreen<CheeseItem>(itemType: 'cheese')
GenericItemFormScreen<WineItem>(itemType: 'wine')  // Future

// Item-specific screens provide type safety
CheeseCreateScreen()  // Uses GenericItemFormScreen<CheeseItem>
CheeseEditScreen()    // Loads data then shows form
```

### **🛠️ Technical Implementation**

#### **Form Logic**
- **Change detection** - Tracks modifications to warn about unsaved changes
- **Form validation** - Real-time validation with localized error messages
- **Loading states** - Overlay during API operations with proper feedback
- **Error handling** - Clear error display with retry options
- **Safe navigation** - Context-aware routing back to source screens

#### **Backend Integration**
- **Enhanced API endpoints** - Preload viewer information for sharing context
- **Validation layer** - Client-side validation before API calls
- **Error mapping** - API errors translated to user-friendly messages
- **Success feedback** - Immediate confirmation with next steps

### **📋 Usage Examples**

**Creating a New Cheese:**
1. Browse "All Items" tab → Click "Add Cheese" FAB
2. Fill form: Name, Type, Origin, Producer, Description (optional)
3. Validation checks → Submit → Success message
4. Navigate to cheese list with new entry visible

**Editing Existing Cheese:**
1. View cheese detail → Click edit button in header
2. Form pre-populated with existing data
3. Modify fields → Change detection warns if navigating away
4. Save changes → Success message → Return to item detail

**User Experience Benefits:**
- **Contextual edit placement** - Edit button in item header, not AppBar
- **Smart FAB visibility** - Add button only on discovery tab, not personal lists
- **Flexible data entry** - Text field for type allows any value (French names, custom types)
- **Professional feedback** - Success/error messages match app's design language
- **Localized experience** - Complete French translation with natural phrasing

The item management system seamlessly extends the existing architecture while maintaining the same level of polish and user experience quality found throughout A la carte.

## 🌍 Internationalization

A la carte features an intelligent localization system with device locale detection and user preference management:

- **🇫🇷 French-first experience** - Natural French phrasing throughout
- **🇺🇸 English fallback** - Complete English support  
- **🤖 Device Locale Detection** - Automatically detects and uses device language on first launch
- **⚙️ User Override Control** - Three-option system: Auto/French/English in settings dialog
- **📱 100% coverage** - Every screen, widget, and interaction translated
- **🚀 Loading Screen Localization** - Startup messages fully localized with contextual icons
- **🎯 State-Based Validation** - Robust localization logic independent of string content

#### **Enhanced Locale System**

**Device Detection & User Preference:**
```dart
// Three-tier preference system
LocalePreference {
  auto,    // Follow device locale (fr_CA → French, en_US → English)
  french,  // Force French regardless of device
  english  // Force English regardless of device
}

// Cross-platform device detection
- Native (Android/iOS/Linux): Uses WidgetsBinding.instance.platformDispatcher.locales
- Web: Defaults to English (avoids platform import conflicts)
- Fallback: English for unsupported device locales
```

**Settings Interface:**
```
Display Language → Dialog:
○ Auto (French)    ← Shows detected device language
○ French           ← Force French
○ English          ← Force English
```

#### **Comprehensive Localization Coverage**

**App Initialization & Loading:**
- **English**: "Initializing A la carte..." → "Setting up your preference hub..." → "Ready! Welcome back."
- **French**: "Initialisation d'A la carte..." → "Configuration de votre centre de préférences..." → "Prêt ! Bon retour."
- **Status Icons**: Contextual icons (settings, account, check mark) match message content

**Profile Setup & Authentication:**
- **English**: "Complete Your Profile" → "Welcome to A la carte!" → "Hi David! Let's set up your profile."
- **French**: "Complétez Votre Profil" → "Bienvenue sur A la carte !" → "Salut David ! Configurons votre profil."
- **State-Based Validation**: Availability checks use boolean states, not string matching

**Form Validation & User Interaction:**
- Natural French cheese terminology ("Mou, Dur, Mi-dur, Bleu")
- Professional rating vocabulary in both languages
- Contextual offline messages with appropriate technical terms
- Real-time form validation with localized error messages
- State-based logic ensures consistent styling across languages

**Navigation & System Messages:**
- Connectivity status indicators ("En ligne" / "Online")
- Error recovery guidance in native language
- Settings and privacy controls with cultural context
- Success/failure notifications matching language preferences

#### **Technical Implementation**

**Robust Locale Detection:**
```dart
// Device locale mapping with fallback
Locale _mapToSupportedLocale(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'fr': return const Locale('fr');  // French variants
    case 'en': return const Locale('en');  // English variants
    default: return const Locale('en');    // Unsupported → English
  }
}
```

**Cross-Platform Compatibility:**
- No platform-specific imports that break builds
- Uses Flutter's standard APIs for locale detection
- Graceful fallbacks prevent crashes on any platform
- Consistent behavior across Web, Android, iOS, Linux

**State-Based Validation:**
- Form validation uses boolean states instead of string matching
- Availability checks work identically in French and English
- Icon and color logic independent of message content
- Maintainable across language additions

French users get a completely localized experience from device detection through all interactions, including:
- Native French technical terminology for connectivity states
- Professional cheese and rating vocabulary
- Culturally appropriate phrasing for privacy and sharing concepts
- Consistent use of formal vs informal address throughout the interface
- Device-aware language selection with clear user control

**📖 [Complete Internationalization Documentation →](docs/internationalization.md)**

## 🛠️ Development Setup

### **Prerequisites**
- Flutter 3.27+ with Dart 3.8+ (official installation recommended)
- Google Cloud Console project with OAuth clients configured
- **For Android**: Android Studio with Android SDK 36, NDK 27.0.12077973 + SHA-1 certificate fingerprint
- **For Desktop**: Linux/macOS/Windows for desktop development

### **Google OAuth Configuration**

1. **Google Cloud Console Setup**
   - Create Web application OAuth client for backend validation
   - Create Android application OAuth client for native mobile experience
   - Configure OAuth consent screen with email and profile scopes
   - See [Google OAuth Setup Guide](../GOOGLE_OAUTH_SETUP_GUIDE.md) for detailed steps

2. **Get your SHA-1 certificate fingerprint**
   ```bash
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
   ```

### **Installation**

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd alacarte-client
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   
   Create a `.env` file in the project root:
   ```bash
   # .env - Development configuration (gitignored)
   API_BASE_URL=https://alacarte-api-414358220433.northamerica-northeast1.run.app
   GOOGLE_CLIENT_ID=414358220433-utddgtujirv58gt6g33kb7jei3shih27.apps.googleusercontent.com
   APP_VERSION=1.0.0-dev
   ```
   
   **Note**: The `.env` file is gitignored and contains your local development configuration. Never commit this file.

4. **Generate localization files**
   ```bash
   flutter gen-l10n
   ```
   
   **Important**: Always run this command after:
   - Cloning the repository for the first time
   - Pulling updates that modify .arb files
   - Adding new localization keys yourself
   
   The app uses 400+ localized strings (loading messages, form validation, status indicators, etc.) and won't compile without generated localization files.

5. **Run the development server**
   ```bash
   # Linux desktop (recommended for development - no CORS issues)
   flutter run -d linux
   
   # Web (for production testing)
   flutter run -d web-server --web-port 3000
   
   # Android (with local network setup)
   flutter run -d android
   ```

### **Android Development**

For Android development, additional network configuration is required:

1. **Configure local network access**
   ```env
   # Update your .env file with your computer's IP
   API_BASE_URL=http://192.168.0.22:8080/api
   ```

2. **Ensure backend accepts network connections**
   ```bash
   # Backend should bind to all interfaces, not just localhost
   go run main.go  # Should listen on :8080, not localhost:8080
   ```

3. **Test network connectivity**
   ```bash
   # From Android device browser, verify:
   # http://192.168.0.22:8080/api/health
   ```

**See [Android Setup Guide](docs/android-setup.md) for complete configuration details.**

## 🚀 CI/CD Pipeline

A la carte features an automated CI/CD pipeline for Android builds using GitHub Actions:

### **✨ Automated Android Builds**

#### **Pre-release Builds (feat/* and fix/* branches)**
- **Trigger**: Pull requests from `feat/*` or `fix/*` branches
- **Output**: Debug APK with development configuration
- **Signing**: Default Android debug keystore (automatic)
- **Package**: `com.alacarte.alc_client.debug`
- **OAuth**: Development Google Cloud project
- **Distribution**: GitHub pre-release with APK download

#### **Production Builds (master branch)**
- **Trigger**: Push to master branch
- **Output**: Signed release APK with production configuration  
- **Signing**: Custom release keystore (production)
- **Package**: `com.alacarte.alc_client`
- **OAuth**: Production Google Cloud project
- **Distribution**: GitHub release with optimized APK

### **🔧 Environment Configuration**

The CI/CD pipeline uses environment variables for configuration management:

#### **Required GitHub Variables** (non-sensitive):
```
DEVELOPMENT_API_URL = https://alacarte-api-414358220433.northamerica-northeast1.run.app
DEVELOPMENT_GOOGLE_CLIENT_ID = 414358220433-utddgtujirv58gt6g33kb7jei3shih27.apps.googleusercontent.com
PRODUCTION_API_URL = [your production API URL]
PRODUCTION_GOOGLE_CLIENT_ID = [your production OAuth client ID]
```

#### **Required GitHub Secrets** (for production signing):
```
KEYSTORE_BASE64 = [base64 encoded release keystore]
KEYSTORE_PASSWORD = [your keystore password]
KEY_PASSWORD = [your key password]
KEY_ALIAS = release
```

### **🔑 Keystore Setup**

#### **Generate Release Keystore**
```bash
cd alacarte-client
keytool -genkey -v -keystore android/app/release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

#### **Encode for GitHub Secrets**
```bash
base64 -i android/app/release-keystore.jks | tr -d '\n'
# Copy output and add as KEYSTORE_BASE64 secret
```

### **⚙️ Version Management**

The pipeline uses GitVersion for semantic versioning:

- **feat: new feature** → Minor version bump (1.0.0 → 1.1.0)
- **fix: bug fix** → Patch version bump (1.0.0 → 1.0.1)  
- **feat!: breaking change** → Major version bump (1.0.0 → 2.0.0)

**Pre-release versions** include branch and build number:
- `v1.2.3-feat-android-workflow.1`
- `v1.2.4-fix-oauth-issue.2`

### **📦 Build Artifacts**

#### **Pre-release APKs**:
- Available on GitHub pre-releases
- Automatic PR comments with download links
- Debug builds for testing
- Uses development API and OAuth

#### **Production APKs**:
- Available on GitHub releases
- Signed with release keystore
- Optimized and minified
- Uses production API and OAuth

### **🏗️ Workflow Features**

- **Automatic versioning** with GitVersion semantic versioning
- **Environment-specific builds** (debug vs release)
- **Secure credential management** with GitHub secrets
- **Comprehensive changelogs** from conventional commits
- **APK size reporting** in release notes
- **PR automation** with status comments and download links
- **Build validation** with configuration checks

**See workflow file**: `.github/workflows/android-release.yml`

### **Development Workflow**

**Current Target: Linux Desktop**
- Fastest development cycle
- No CORS constraints with backend
- Full debugging capabilities
- Native performance

**Production Target: Web**
- Primary deployment platform
- PWA capabilities for mobile-like experience
- CORS configuration handled

**Android Target: Available**
- Native mobile app experience
- Full offline capabilities
- Local network development support
- Portrait-optimized mobile UI

## 📱 Platform Strategy

### **Phase 1: Web Application (Completed)** 
- **Target**: Desktop and mobile web browsers
- **Benefits**: Cross-platform, easy deployment, no app store approval
- **Status**: ✅ Production ready with PWA capabilities

### **Phase 2: Android Application (Completed)** 
- **Target**: Native Android app via Google Play Store
- **Benefits**: Better mobile UX, offline support, native integrations
- **Status**: ✅ Build configured, runs on devices
- **Network Setup**: Supports local development with network IP configuration

### **Phase 3: iOS Application (Future)**
- **Target**: Native iOS app via App Store
- **Dependencies**: Apple Developer Program, iOS-specific testing

## 🔧 Backend Integration

### **API Endpoints** (Go REST API)
```
Cheese Management:
  GET    /api/cheese/all     - List all cheeses
  GET    /api/cheese/:id     - Get cheese details
  POST   /api/cheese/new     - Create new cheese
  PUT    /api/cheese/:id     - Update cheese
  DELETE /api/cheese/:id     - Delete cheese

Rating System:
  POST   /api/rating/new              - Create rating
  GET    /api/rating/author/:id       - Get user's own ratings only
  GET    /api/rating/viewer/:id       - Get user's complete reference list (own + shared ratings) ⭐
  GET    /api/rating/cheese/:id       - Get all ratings for specific cheese
  PUT    /api/rating/:id/share        - Share rating with another user
  DELETE /api/rating/:id              - Delete rating

User Management:
  GET    /api/user/all       - List users (profiles)
  POST   /api/user/new       - Create user profile
  PUT    /api/user/:id       - Update user profile
  DELETE /api/user/:id       - Delete user profile
```

### **Data Models** (matching backend)
- **User**: Profile-based system, no authentication
- **Cheese**: Name, type, origin, producer, description
- **Rating**: Grade (float), note (string), sharing permissions
- **User Reference Lists**: Built from `/rating/viewer/:id` (own ratings + shared ratings)
- **Polymorphic Design**: Ratings work with any item type

## 🏃‍♂️ Running the App

### **Development Mode** (Recommended)
```bash
flutter run -d linux
```
- Hot reload enabled
- Full debugging
- No CORS issues with backend

### **Web Testing**
```bash
flutter run -d web-server --web-port 3000
```
- Test responsive design
- Verify PWA functionality
- Check cross-browser compatibility

### **Production Build**
```bash
# Web build
flutter build web --release

# Android build (future)
flutter build apk --release
```

## 🗺️ Project Roadmap

### **✅ Completed Features**

#### **Core Platform**
- ✅ **Generic Architecture** - Extensible design supporting multiple item types with zero refactoring
- ✅ **Riverpod State Management** - Complete reactive state management with generic providers
- ✅ **Go Router Navigation** - Type-safe routing with deep linking and safe navigation patterns
- ✅ **Async App Initialization** - Seamless startup with offline support and error recovery
- ✅ **Two-Level Dashboard** - Reference hub + item-specific screens
- ✅ **Cross-Platform Support** - Runs on Linux, Web, Android (future)

#### **User Experience**
- ✅ **Profile System** - User selection and switching with offline-aware data sync
- ✅ **Theme System** - Light/dark mode toggle available on all screens
- ✅ **Connectivity Awareness** - Real-time online/offline status with contextual messaging
- ✅ **Complete Internationalization** - Full French/English support
- ✅ **Responsive Design** - Mobile-first with collapsible interfaces
- ✅ **Safe Navigation** - Crash-proof navigation with smart fallbacks

#### **Rating Features**
- ✅ **Rating CRUD** - Create, edit, delete ratings with star picker and notes
- ✅ **Advanced Sharing System** - Share ratings with specific users or make private
- ✅ **Smart Sharing Dialog** - Intuitive interface with current sharing state visualization
- ✅ **Personal vs Shared Distinction** - Clear visual separation of own ratings and recommendations
- ✅ **Rating Display System** - Compact badges and detailed rating sections

#### **Item Management**
- ✅ **Cheese CRUD** - Create and edit cheese entries with inline form design
- ✅ **Item Detail Views** - Rich individual item screens with complete information
- ✅ **Generic Item Support** - Architecture ready for wine, beer, coffee, etc.

#### **Search & Discovery**
- ✅ **Advanced Filtering System** - Mobile-optimized collapsible filtering interface
- ✅ **Context-Aware Filtering** - Different filters per tab (discovery vs personal lists)
- ✅ **Smart Filter Persistence** - Universal filters persist, tab-specific filters auto-clear
- ✅ **Text Search** - Search items by name with real-time results

### **🔄 In Progress Features**

#### **Authentication Migration**
- 🔄 **Google OAuth Integration** - Migrating from profile system to secure OAuth
- 🔄 **Privacy Model Implementation** - Private-by-default ratings with explicit sharing
- 🔄 **Display Name System** - User-controlled identity for privacy protection
- 🔄 **User Discovery** - Selective user visibility for sharing dialogs

### **📋 Future Features**

#### **Core Platform Enhancements**
- ✅ **Community Stats Caching** - Riverpod provider eliminates duplicate API calls with automatic caching
- 📋 **Item Deletion** - Delete cheese entries with proper validation and safety checks
- 📋 **Enhanced Offline Support** - Local data persistence and sync capabilities
- 📋 **Real-time Updates** - WebSocket integration for live data updates

#### **User Experience**
- 📋 **Quick Sharing Actions** - One-click sharing buttons directly in item lists
- 📋 **Sharing Status Indicators** - Visual indicators showing which ratings are shared/private
- 📋 **Enhanced Mobile Experience** - Native mobile app optimizations
- 📋 **Progressive Web App** - PWA features for mobile web experience

#### **Item Categories**
- 📋 **Wine Rating System** - Complete wine rating with varietal-specific fields
- 📋 **Beer Rating System** - Beer ratings with style and brewery information
- 📋 **Coffee Rating System** - Coffee beans and brewing method ratings
- 📋 **Restaurant Rating System** - Restaurant and dish rating capabilities

#### **Social & Discovery**
- 📋 **Enhanced Discovery** - Recommendation algorithms based on user preferences
- 📋 **User Profiles** - Optional public profiles for users who want them
- 📋 **Activity Feeds** - See what friends are rating (opt-in)
- 📋 **Trending Items** - Popular items based on recent rating activity

#### **Analytics & Insights**
- 📋 **Personal Analytics** - Your rating trends and preference insights
- 📋 **Community Statistics** - Anonymous aggregate data for item insights
- 📋 **Recommendation Engine** - Suggest items based on your rating history
- 📋 **Export Features** - Data export for personal backup and analysis

#### **Platform Expansion**
- 📋 **Android Native App** - Full-featured mobile application
- 📋 **iOS Native App** - Native iOS experience
- 📋 **Desktop App Enhancements** - Native desktop features and integrations
- 📋 **API Documentation** - Interactive API docs for third-party integration

## 🏛️ Technical Decisions

### **Why Flutter?**
- **Single codebase** for web, desktop, and mobile
- **Excellent performance** with native compilation
- **Rich ecosystem** for UI components and state management
- **Future-proof** with strong Google backing

### **Why Riverpod?**
- **Type-safe** state management with compile-time guarantees
- **Excellent testing** support with provider overrides
- **Scalable architecture** for complex app state
- **Great developer experience** with clear documentation

### **Why Go Router?**
- **Declarative routing** with type-safe navigation
- **Deep linking** support for web URLs
- **Route guards** for conditional access
- **Nested routing** for complex navigation flows

### **Why Profile-Based Access?**
- **Personal Focus** - Each user builds their own reference list
- **Simplicity** - No authentication complexity for personal use
- **Flexibility** - Easy profile switching for family/shared use
- **Privacy** - No external accounts or data collection
- **Speed** - Instant access to your personal reference list

### **Why Smart Initial Routing?**
- **User Experience** - Returning users skip profile selection and go directly to content
- **Preserved Choice** - Users can still switch profiles via Settings → Switch Profile
- **Standard Pattern** - Common Flutter app pattern for conditional initial routes
- **Simple Implementation** - Uses `ref.read()` to avoid provider rebuild timing issues

## 🤝 Contributing

This is currently a personal project, but the architecture is designed for extensibility. Key areas for future contribution:

1. **New Item Categories** - Adding support for different types of rateable items
2. **UI Components** - Reusable widgets and enhanced designs  
3. **Platform Features** - iOS support, PWA enhancements
4. **Performance** - Optimization and caching improvements

## 📄 License

[Choose appropriate license - MIT, Apache 2.0, etc.]

---

**Built with ❤️ using Flutter & Dart**

*A la carte - Where your preferences matter*

## 📚 Documentation

### **System Architecture & Implementation**
- **[🔒 Authentication System](docs/authentication-system.md)** - Google OAuth implementation and JWT token management
- **[🛡️ Privacy Model](docs/privacy-model.md)** - Privacy-first sharing architecture and user controls
- **[⭐ Rating System](docs/rating-system.md)** - Complete CRUD rating functionality and sharing
- **[🏗️ Form Strategy Pattern](docs/form-strategy-pattern.md)** - Strategy Pattern for item CRUD forms
- **[🔍 Filtering System](docs/filtering-system.md)** - Advanced search and filtering implementation
- **[🤝 Sharing Implementation](docs/sharing-implementation.md)** - Collaborative rating sharing system
- **[⚙️ Settings System](docs/settings-system.md)** - Modular settings architecture and widget library
- **[🌍 Internationalization](docs/internationalization.md)** - French/English localization setup
- **[🌐 Offline Handling](docs/offline-handling.md)** - Fullscreen offline system with automatic API retry
- **[📱 Android Setup](docs/android-setup.md)** - Complete Android build configuration and development guide
- **[🔧 Android OAuth Setup](docs/android-oauth-setup.md)** - Android-specific OAuth configuration
- **[🔑 Google OAuth Setup](docs/google-oauth-setup.md)** - Complete Google OAuth setup guide
- **[🚀 CI/CD Pipeline](docs/ci-cd-pipeline.md)** - Automated Android builds with GitHub Actions
- **[🔄 Router Architecture](docs/router-architecture.md)** - Stable routing patterns and navigation best practices
- **[🔔 Notification System](docs/notification-system.md)** - Unified notification styles and localization standards

### **Developer Guides**
- **[🏗️ Architecture Overview](#🏗️-architecture-overview)** - Generic design patterns and extensibility
- **[👨‍💻 Developer Onboarding](#🚀-developer-onboarding-guide)** - Step-by-step development guide
- **[➕ Adding New Item Types](docs/adding-new-item-types.md)** - Complete guide for adding item types
- **[✅ Item Type Checklist](docs/new-item-type-checklist.md)** - Quick reference checklist
- **[📝 CI/CD Quick Setup](docs/ci-cd-quick-setup.md)** - Fast track guide for setting up the Android pipeline
- **[📦 Package Upgrade Planning](docs/package-upgrade-planning.md)** - Dependency management and upgrade strategy

## 🚀 Future Enhancement Opportunities

### **Performance Optimization - Advanced Caching**
The current implementation includes efficient provider-based caching for community statistics. Future enhancements could include:

**Batch Loading Strategy:**
- Single API call to load all community ratings for an item type (currently stats only)
- Extended TTL caching with offline persistence
- SQLite-based local storage for complete offline support
- Manual refresh controls for users

**Implementation Approach:**
```dart
// Enhanced RatingProvider with full offline persistence
class RatingState {
  final Map<String, Map<int, List<Rating>>> communityRatingsCache;
  final Map<String, DateTime> cacheTimestamps;
  
  // Batch loading method
  Future<void> loadCommunityRatingsForItemType(String itemType) async {
    // Single API call + local caching
  }
}

// Offline data persistence
class OfflineCache {
  static Future<void> cacheCheeseItems(List<CheeseItem> items) async;
  static Future<void> cacheUserRatings(int userId, List<Rating> ratings) async;
  static Future<List<CheeseItem>> getCachedCheeseItems() async;
}
```

**Benefits:**
- Complete offline functionality for browsing
- Instant display from persistent cache
- User control over data freshness
- Reduced network usage

**Data Caching Priorities:**
1. **High Priority**: Item lists, user's personal ratings
2. **Medium Priority**: Individual rating details, recently viewed items
3. **Low Priority**: Shared ratings, extended statistics

This enhancement would provide complete offline browsing capabilities while maintaining the current clean architecture.

---

## Recent Improvements - September 2025

### Community Stats Provider Implementation (October 2025)

#### **Riverpod Provider Architecture**
- **FutureProvider.family Pattern**: Proper state management for community statistics
- **Automatic Caching**: Stats cached per (itemType, itemId) pair throughout app session
- **Eliminated FutureBuilder Anti-pattern**: Replaced problematic FutureBuilder with provider
- **Direct Type Checking**: Uses documented ApiResponse pattern for type safety
- **Cache Invalidation**: Simple `ref.invalidate()` on pull-to-refresh

#### **Performance Improvements**
- **Zero Duplicate API Calls**: Provider caches results automatically on scroll/rebuild
- **App-wide Availability**: Stats accessible from any widget via provider
- **Efficient State Management**: AsyncValue handles loading/error/data states
- **Reduced Code Complexity**: Eliminated ~40 lines of FutureBuilder boilerplate per usage
- **Better UX**: No flickering or repeated loading states

#### **Technical Implementation**
- **Provider Location**: `lib/providers/community_stats_provider.dart`
- **Widget Updates**: `RatingSummaryCard` converted to ConsumerWidget
- **Screen Updates**: Both item list and detail screens use provider
- **Extension Methods**: Convenient accessors for stats data (totalRatings, averageRating)
- **Type Safety**: CommunityStatsParams class ensures proper provider family usage

#### **Developer Benefits**
- **Reusable Pattern**: Provider can be accessed from any screen
- **Clean Architecture**: Separation of data fetching from UI
- **Easy Testing**: Provider can be mocked for widget tests
- **Documented Pattern**: Follows ApiResponse direct type checking best practice
- **Scalable Design**: Ready for additional stat types without refactoring

### Android CI/CD Pipeline Implementation

#### **Automated Build System**
- **GitHub Actions Workflow**: Complete CI/CD pipeline for Android builds
- **Pre-release Automation**: Automatic debug APK generation for feat/* and fix/* branches
- **Production Releases**: Signed release APKs for master branch pushes
- **GitVersion Integration**: Semantic versioning with conventional commits
- **Environment Configuration**: Dotenv-based configuration with strict validation

#### **Configuration Management**
- **Dotenv Implementation**: Migrated from compile-time constants to environment variables
- **Strict Validation**: App fails fast with clear errors if configuration is missing
- **GitHub Secrets Integration**: Secure credential management for CI/CD
- **Build-Mode Detection**: Automatic dev/prod selection using kDebugMode
- **No Fallbacks**: Production-ready configuration without silent defaults

#### **Signing Strategy**
- **Debug Signing**: Default Android debug keystore for development builds
- **Release Signing**: Custom release keystore for production distribution
- **Package Separation**: .debug suffix for development, production package for releases
- **OAuth Isolation**: Separate OAuth clients for development and production
- **SHA-1 Management**: Different certificates for different environments

#### **Developer Experience**
- **Automatic Versioning**: GitVersion handles version bumps automatically
- **PR Automation**: Automatic comments with APK download links
- **Clear Documentation**: Comprehensive CI/CD pipeline documentation
- **Easy Setup**: Simple .env file for local development
- **Dynamic App Version**: Settings screen shows version from environment variables

### App Initialization & Performance Enhancements

#### **Beautiful Loading Screen Implementation**
- **Smooth OAuth Startup**: Eliminated brief login screen flashes during app initialization
- **Progressive Loading Messages**: Contextual messages from "Initializing A la carte..." to "Ready! Welcome back."
- **Full Localization**: Loading screen messages properly localized for French and English users
- **Timer-Based Detection**: Reliable 500ms polling system prevents initialization deadlocks
- **Connectivity-Aware Routing**: Smart handling of null connectivity states during startup

#### **Performance Optimizations Implemented**
- **Service-Level Caching**: 5-minute TTL cache eliminates duplicate API calls (3+ calls → 1 call)
- **Provider Loading Guards**: `hasLoadedOnce` flag prevents redundant data loading
- **Lazy Loading Pattern**: Providers load data on-demand instead of constructor auto-loading
- **Network Debouncing**: 500ms debounce prevents duplicate health checks from Android connectivity events
- **Form Validation Improvements**: Real-time button state updates with proper setState() calls

#### **User Experience Enhancements**
- **50% Faster Startup**: Reduced average initialization time from ~1200ms to ~600ms
- **Zero API Duplicates**: Eliminated redundant network requests during app startup
- **Responsive Form Validation**: Submit buttons enable/disable immediately as users type
- **Clean Debug Logging**: Removed debug noise while preserving essential error information
- **Professional Loading Experience**: Consistent loading screen styling across both languages
- **Enhanced Localization System**: Device locale detection with user preference override
- **State-Based Form Logic**: Robust validation logic independent of language content
- **Comprehensive Profile Setup**: Fully localized profile completion with availability checking

#### **Technical Architecture Improvements**
- **Robust Initialization Flow**: Timer-based auth checking works reliably across platforms
- **Enhanced Connectivity Handling**: Proper offline detection with fallback to fullscreen offline system
- **Optimized Provider Pattern**: Smart loading state management with cache-aware data fetching
- **Localized Status Indicators**: Loading messages use exact localization matching instead of string parsing
- **Cross-Platform Locale Detection**: Device locale detection without platform-specific imports
- **State-Based Form Validation**: Boolean logic replaces fragile string matching for UI states
- **Enhanced Settings Architecture**: Dialog-based language selection with comprehensive options

### Localization System Architecture

#### **Two-Layer Locale Management**
```dart
// User preference layer
LocalePreferenceNotifier {
  auto,    // Follow device locale
  french,  // Force French
  english  // Force English
}

// Actual locale implementation layer
LocaleNotifier {
  _setLocale(locale) // Updates MaterialApp locale
}
```

#### **Profile Setup Localization Enhancements**
- **Complete Profile Screen**: All text elements fully localized
- **Dynamic Availability Messages**: State-based validation with proper localization
- **Cultural Adaptation**: Informal greeting in French ("Salut David!") vs formal English
- **Cross-Language Consistency**: Icons and colors work identically regardless of language

#### **Settings UI Improvements**
- **Enhanced Language Selection**: Three-option dialog (Auto/French/English)
- **Device Locale Display**: Shows what "Auto" means ("Auto (French)")
- **Immediate Language Switching**: Changes apply instantly with preference persistence
- **Clean Architecture**: Removed deprecated FR/EN toggle widget

These improvements maintain full backward compatibility while significantly enhancing user experience and application performance across all supported platforms.
