import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Provider for global app state management
final appProvider = StateNotifierProvider<AppNotifier, AppState>(
  (ref) => AppNotifier(),
);

/// Global app state
class AppState {
  final bool isFirstLaunch;
  final bool isDarkMode;
  final String? globalError;
  final Map<String, dynamic> settings;

  const AppState({
    this.isFirstLaunch = true,
    this.isDarkMode = false,
    this.globalError,
    this.settings = const {},
  });

  AppState copyWith({
    bool? isFirstLaunch,
    bool? isDarkMode,
    String? globalError,
    Map<String, dynamic>? settings,
  }) {
    return AppState(
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      globalError: globalError,
      settings: settings ?? this.settings,
    );
  }
}

/// Notifier for global app state
class AppNotifier extends StateNotifier<AppState> {
  AppNotifier() : super(const AppState()) {
    _initializeApp();
  }

  /// Initialize the app
  Future<void> _initializeApp() async {
    await _loadSettings();
    state = state.copyWith(isFirstLaunch: false);
  }

  /// Load app settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme preference
      final isDarkMode = prefs.getBool('dark_mode') ?? false;

      // Load other settings
      final settings = <String, dynamic>{};
      // Add other settings as needed

      state = state.copyWith(isDarkMode: isDarkMode, settings: settings);
    } catch (e) {
      // Error loading settings - continue with defaults
    }
  }

  /// Dispose resources when app is closed
  @override
  void dispose() {
    super.dispose();
    ApiService.dispose();
  }
  
  /// Toggle dark mode theme
  Future<void> toggleDarkMode() async {
    final newDarkMode = !state.isDarkMode;
    state = state.copyWith(isDarkMode: newDarkMode);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', newDarkMode);
    } catch (e) {
      // Error saving preference - not critical
    }
  }

  /// Set dark mode explicitly
  Future<void> setDarkMode(bool isDark) async {
    if (state.isDarkMode == isDark) return;
    
    state = state.copyWith(isDarkMode: isDark);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', isDark);
    } catch (e) {
      // Error saving preference - not critical
    }
  }

  /// Set global error message
  void setGlobalError(String error) {
    state = state.copyWith(globalError: error);
  }

  /// Clear global error
  void clearGlobalError() {
    state = state.copyWith(globalError: null);
  }

  /// Update app setting
  Future<void> updateSetting(String key, dynamic value) async {
    final updatedSettings = Map<String, dynamic>.from(state.settings);
    updatedSettings[key] = value;
    
    state = state.copyWith(settings: updatedSettings);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save settings based on type
      if (value is String) {
        await prefs.setString('setting_$key', value);
      } else if (value is bool) {
        await prefs.setBool('setting_$key', value);
      } else if (value is int) {
        await prefs.setInt('setting_$key', value);
      } else if (value is double) {
        await prefs.setDouble('setting_$key', value);
      }
    } catch (e) {
      // Error saving setting - not critical
    }
  }

  /// Get app setting value
  T? getSetting<T>(String key) {
    return state.settings[key] as T?;
  }
}

/// Computed provider for current theme mode
final themeProvider = Provider<bool>((ref) {
  final appState = ref.watch(appProvider);
  return appState.isDarkMode;
});

/// Computed provider for checking if app is ready
final appReadyProvider = Provider<bool>((ref) {
  final appState = ref.watch(appProvider);
  return !appState.isFirstLaunch;
});

/// Provider for global error state
final globalErrorProvider = Provider<String?>((ref) {
  final appState = ref.watch(appProvider);
  return appState.globalError;
});
