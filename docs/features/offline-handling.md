# Offline Handling System

**Production-Ready Fullscreen Offline Experience - September 2025**

À la carte features a sophisticated offline handling system that provides clear communication and seamless recovery when connectivity issues occur. The system follows a fullscreen approach where users receive professional messaging when the app cannot function properly due to connectivity issues.

## 🏗️ Architecture Overview

### **Design Philosophy**

À la carte's offline handling is built on the principle of **clear binary states**:
- **App works fully** (online) - All features available
- **App explains why it can't work** (offline) - Professional fullscreen messaging

This eliminates confusing partial functionality where some features work and others don't.

### **Three-State Connectivity Model**

```dart
enum ConnectivityState {
  online,           // Network + API both accessible → Normal app
  networkOffline,   // No network connection → "No Internet Connection" screen  
  serverOffline,    // Network OK, API unreachable → "Server Unavailable" screen
}
```

**State Transitions:**
- `networkOffline` ↔ `online` - Platform connectivity changes
- `online` ↔ `serverOffline` - À la carte server availability changes
- Direct jumps possible when both network and server status change

## 🔧 Technical Implementation

### **Core Components**

#### **1. ApiService - Unified Connectivity Monitoring**
```dart
abstract class ApiService {
  // Connectivity monitoring state
  static ConnectivityState _state = ConnectivityState.online;
  static final Connectivity _connectivity = Connectivity();
  static Timer? _serverCheckTimer;
  static final StreamController<ConnectivityState> _stateController;
  
  // Public interface
  static bool get isOnline => _state == ConnectivityState.online;
  static Stream<ConnectivityState> get connectivityStream;
  
  // Monitoring methods
  static void startConnectivityMonitoring();
  static Future<void> checkConnectivityAfterTimeout();
}
```

**Key Features:**
- **Platform-native detection** - Uses `connectivity_plus` for instant network change notifications
- **API-specific validation** - Health checks validate À la carte server specifically  
- **Reactive timeout detection** - Only checks connectivity when API calls actually fail
- **Periodic server monitoring** - 30-second health checks when server unreachable but network available

#### **2. FullscreenOfflineScreen - Professional User Messaging**
```dart
class FullscreenOfflineScreen extends ConsumerWidget {
  final ConnectivityState connectivityState;
  
  // Provides context-aware messaging:
  // - Different titles and descriptions per connectivity state
  // - Localized content (French/English)
  // - Retry functionality with immediate connectivity check
  // - Professional design matching app theme
}
```

**Visual Design:**
- **Status-colored circular icon** with app branding
- **Clear title and description** explaining the exact issue
- **Retry button** in status color for immediate action
- **Card-based layout** consistent with app design language

#### **3. ConnectivityProvider - Simple Stream Provider**
```dart
final connectivityStateProvider = StreamProvider<ConnectivityState>((ref) {
  return ApiService.connectivityStream;
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStateProvider).when(
    data: (state) => state == ConnectivityState.online,
    loading: () => true,  // Assume online while loading
    error: (_, __) => false, // Assume offline on error
  );
});
```

### **App-Level Integration**

#### **MaterialApp Builder Pattern**
```dart
// In main.dart - protects ALL screens automatically
MaterialApp.router(
  routerConfig: ref.watch(appRouterProvider),
  builder: (context, child) {
    return connectivityState.when(
      data: (state) {
        if (state == ConnectivityState.online) {
          return child ?? const SizedBox.shrink(); // Normal app
        } else {
          return FullscreenOfflineScreen(connectivityState: state); // Offline overlay
        }
      },
      loading: () => child ?? const Center(child: CircularProgressIndicator()),
      error: (_, __) => const FullscreenOfflineScreen(
        connectivityState: ConnectivityState.networkOffline,
      ),
    );
  },
)
```

**Benefits:**
- **Universal coverage** - Every screen automatically protected
- **No boilerplate** - Individual screens don't need offline handling
- **Consistent UX** - Same offline experience everywhere
- **Simple routing** - Router completely disabled when offline

## 🔄 Reactive Connectivity Detection

### **Detection Strategy**

**1. Platform Connectivity Monitoring**
```dart
static Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
  final hasNetworkConnection = results.any((result) => result != ConnectivityResult.none);
  
  if (!hasNetworkConnection) {
    _updateState(ConnectivityState.networkOffline);
    return;
  }
  
  // Network available - check if API is reachable
  await _checkApiReachability();
}
```

**2. API Health Validation**
```dart
static Future<void> _checkApiReachability() async {
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);
    
    final request = await client.getUrl(Uri.parse('${ApiConfig.baseUrl}/health'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      _updateState(ConnectivityState.online);
    } else {
      _updateState(ConnectivityState.serverOffline);
    }
  } catch (e) {
    _updateState(ConnectivityState.serverOffline);
  }
}
```

**3. Timeout-Triggered Checks**
```dart
// In API response handling
on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError) {
    // Only check connectivity when API calls actually fail
    checkConnectivityAfterTimeout();
  }
}
```

### **Performance Characteristics**

- **Zero overhead** on successful API calls - no preemptive connectivity checks
- **Instant detection** of network changes via platform APIs
- **Smart server validation** - only when network issues are detected
- **Minimal resource usage** - no polling while online; a 30-second check runs only while the server is unreachable

## 🚀 Automatic API Retry System

### **Authentication Retry Logic**

```dart
class AuthNotifier extends StateNotifier<AuthState> {
  /// Listen to connectivity changes and retry auth when coming back online
  void _listenToConnectivity() {
    _ref.listen<AsyncValue<ConnectivityState>>(connectivityStateProvider, (previous, next) {
      next.whenData((connectivityState) {
        if (connectivityState == ConnectivityState.online && 
            previous?.value != ConnectivityState.online) {
          _handleConnectivityRestored();
        }
      });
    });
  }

  /// Always revalidate user when connectivity is restored
  Future<void> _handleConnectivityRestored() async {
    if (state.isAuthenticated && state.token != null) {
      await _validateTokenWithBackend(state.token!);
    }
  }
}
```

**Retry Behavior:**
- **Automatic user revalidation** when connectivity returns
- **Fresh authentication state** ensures tokens haven't expired
- **Seamless data loading** - user profile and content appear automatically
- **No manual refresh needed** - everything happens in the background

### **Future Enhancement: Universal API Retry**

The current implementation handles authentication retry. Future enhancements could extend this pattern to other providers:

```dart
// Example: Rating provider with connectivity retry
class RatingNotifier extends StateNotifier<RatingState> {
  void _listenToConnectivity() {
    _ref.listen(connectivityStateProvider, (previous, next) {
      if (isConnectivityRestored(previous, next)) {
        _retryFailedOperations(); // Retry any failed rating operations
      }
    });
  }
}
```

## 🌍 Localization Support

### **User-Facing Messages**

All offline screen content is fully localized with natural language for both supported locales:

#### **English Messages**
```dart
"noInternetConnectionTitle": "No Internet Connection"
"noInternetConnectionDescription": "À la carte needs an internet connection to sync your ratings and preferences. Please check your network settings and try again."

"serverUnavailableTitle": "Server Unavailable"  
"serverUnavailableDescription": "À la carte server is temporarily unavailable. This might be due to maintenance or a temporary issue. We'll keep trying to reconnect."

"connectedTitle": "Connected"
"connectionRestoredDescription": "Connection restored! You can now use all features of À la carte."
```

#### **French Messages**
```dart
"noInternetConnectionTitle": "Pas de Connexion Internet"
"noInternetConnectionDescription": "À la carte a besoin d'une connexion internet pour synchroniser vos évaluations et préférences. Veuillez vérifier vos paramètres réseau et réessayer."

"serverUnavailableTitle": "Serveur Indisponible"
"serverUnavailableDescription": "Le serveur d'À la carte est temporairement indisponible. Cela pourrait être dû à une maintenance ou un problème temporaire. Nous continuons d'essayer de nous reconnecter."

"connectedTitle": "Connecté"  
"connectionRestoredDescription": "Connexion rétablie ! Vous pouvez maintenant utiliser toutes les fonctionnalités d'À la carte."
```

### **Localization Implementation**

```dart
// FullscreenOfflineScreen uses context-aware localization
String _getTitle(BuildContext context) {
  switch (connectivityState) {
    case ConnectivityState.networkOffline:
      return context.l10n.noInternetConnectionTitle;
    case ConnectivityState.serverOffline:
      return context.l10n.serverUnavailableTitle;
    case ConnectivityState.online:
      return context.l10n.connectedTitle;
  }
}
```

**Localization Benefits:**
- **Professional French terminology** for technical concepts
- **Context-appropriate messaging** for different connectivity issues
- **Cultural adaptation** - natural phrasing for each language
- **Consistent tone** with the rest of the application

## 🐛 Debug Logging

### **Comprehensive Connectivity Logging**

The offline system provides detailed logging to help developers understand connectivity behavior:

#### **App Startup Logging**
```bash
🔍 Checking initial connectivity...
📱 Platform connectivity results: [ConnectivityResult.wifi]
🌍 Network available - checking API reachability...
🎧 Testing API reachability: http://localhost:8080/health
📊 API health check response: 200
✅ API server reachable - going online
🟢 🌐 Connected to À la carte - app fully functional
```

#### **Connectivity Change Logging**
```bash
🔄 Handling connectivity change: [ConnectivityResult.none]
🚫 Network unavailable - going offline
📡 Connectivity state changed: online → networkOffline
🔴 🚫 No network connection - showing offline screen
```

#### **Server Monitoring Logging**
```bash
⏰ Starting periodic server checking (30s intervals)
🔄 Periodic server reachability check...
🎧 Testing API reachability: http://localhost:8080/health
🟠 API server unreachable: Connection refused - server offline
📡 Connectivity state changed: online → serverOffline
🟠 ☁️ Server unreachable - showing server unavailable screen
```

#### **Automatic Retry Logging**
```bash
⚡ API timeout detected - triggering immediate connectivity check
🔄 User triggered connection retry from offline screen
🔄 Connectivity restored - will revalidate user authentication
🔄 Connectivity restored - revalidating user authentication
✅ User revalidation successful
```

### **Log Categories**

- **🔍 Detection** - Initial connectivity checks and platform monitoring
- **📡 State Changes** - Connectivity state transitions with before/after states
- **⚡ Reactive Checks** - API timeout triggered connectivity validation
- **🔄 Recovery** - Automatic retry and restoration logging
- **⏰ Monitoring** - Periodic server health check activity

## 🧪 Testing the Offline System

### **Manual Testing Scenarios**

#### **1. App Startup Offline**
```bash
# Test: Start app while backend is stopped
# Expected: Fullscreen "Server Unavailable" screen
# Restore: Start backend → App automatically returns to normal
```

#### **2. Network Disconnection**
```bash
# Test: Disconnect from WiFi while using app
# Expected: Fullscreen "No Internet Connection" screen  
# Restore: Reconnect WiFi → App automatically returns to normal
```

#### **3. Server Shutdown During Usage**
```bash
# Test: Stop backend while browsing items
# Expected: Next API call triggers "Server Unavailable" screen
# Restore: Restart backend → User revalidation + normal app returns
```

#### **4. Authentication Retry**
```bash
# Test: Start offline → Come online
# Expected: Automatic /api/user/me call + profile button appears
# Verify: Check console for "User revalidation successful"
```

### **Debugging Offline Issues**

#### **Common Debug Steps**
1. **Check console logs** - Look for connectivity state change messages
2. **Verify backend health** - Ensure `/health` endpoint responds with 200
3. **Test platform connectivity** - Check if device has actual internet access
4. **Monitor API calls** - Look for timeout patterns that trigger offline mode

#### **Expected Log Patterns**

**Successful Offline Recovery:**
```bash
🟠 ☁️ Server unreachable - showing server unavailable screen
📊 API health check response: 200  
📡 Connectivity state changed: serverOffline → online
🟢 🌐 Connected to À la carte - app fully functional
🔄 Connectivity restored - revalidating user authentication
✅ User revalidation successful
```

**Network Connectivity Issues:**
```bash
🔄 Handling connectivity change: [ConnectivityResult.none]
🚫 Network unavailable - going offline
🔴 🚫 No network connection - showing offline screen
```

## 🚀 Implementation Benefits

### **For Users**
- **Never see failed API calls** - Fullscreen protection prevents confusion
- **Clear understanding** of connectivity issues with professional messaging  
- **Automatic recovery** - No manual refresh needed when connectivity returns
- **Localized experience** - Native language support for technical explanations

### **For Developers**
- **Zero boilerplate** - No offline handling needed in individual screens
- **Clean architecture** - Single source of truth for app availability
- **Easy debugging** - Comprehensive logging shows exact connectivity flow
- **Simple testing** - Binary online/offline scenarios eliminate edge cases

### **For Maintenance**
- **Centralized logic** - All connectivity handling in one place
- **Consistent behavior** - Same offline experience across all features
- **Easy updates** - Changes to offline messaging affect entire app
- **Performance optimized** - Minimal overhead on normal app operation

## 🔮 Future Enhancements

### **Offline Data Persistence**
```dart
// Potential future enhancement
class OfflineCache {
  static Future<void> cacheUserRatings(List<Rating> ratings);
  static Future<void> cacheCheeseItems(List<CheeseItem> items);
  static Future<List<Rating>> getCachedRatings();
  
  // Enable viewing cached data while offline
}
```

### **Operation Queuing**
```dart
// Potential future enhancement  
class OfflineOperationQueue {
  static Future<void> queueRatingCreation(Rating rating);
  static Future<void> queueRatingUpdate(int id, Rating rating);
  static Future<void> processPendingOperations(); // When online
}
```

### **Partial Functionality Mode**
Instead of fullscreen blocking, could implement:
- **View-only mode** for cached data
- **Local editing** with sync when online
- **Conflict resolution** for offline changes

However, the current fullscreen approach provides the clearest user experience for À la carte's collaborative nature.

## 📋 Best Practices

### **For Screen Development**
- **No offline handling needed** - App-level protection covers everything
- **Focus on core functionality** - Let connectivity system handle edge cases
- **Use normal API calls** - Timeout detection and retry happen automatically

### **For Provider Development**
- **Add connectivity listeners** for automatic retry (see AuthNotifier example)
- **Handle API errors gracefully** - Let connectivity system detect timeouts
- **Implement retry methods** for failed operations when connectivity returns

### **For API Integration**
- **Use ApiService.handleResponse()** - Automatic timeout detection and error handling
- **No preemptive connectivity checks** - Let API calls happen naturally
- **Trust the connectivity system** - Failed calls trigger appropriate offline mode

The offline handling system provides a robust, user-friendly foundation that scales with your app's growth while maintaining excellent performance and user experience.
