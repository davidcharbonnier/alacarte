import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale preference options
enum LocalePreference {
  auto,   // Follow device locale
  french, // Force French
  english // Force English
}

/// Provider for managing app locale with device detection
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Provider for locale preference (auto/french/english)
final localePreferenceProvider = StateNotifierProvider<LocalePreferenceNotifier, LocalePreference>((ref) {
  return LocalePreferenceNotifier(ref);
});

/// State notifier for managing locale preference
class LocalePreferenceNotifier extends StateNotifier<LocalePreference> {
  static const String _preferenceKey = 'user_locale_preference';
  final Ref _ref;
  
  LocalePreferenceNotifier(this._ref) : super(LocalePreference.auto) {
    _loadPreference();
  }
  
  /// Load saved preference from SharedPreferences
  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final preferenceString = prefs.getString(_preferenceKey);
    
    if (preferenceString != null) {
      state = LocalePreference.values.firstWhere(
        (p) => p.name == preferenceString,
        orElse: () => LocalePreference.auto,
      );
    }
    
    // Update the actual locale based on preference
    _updateLocaleBasedOnPreference();
  }
  
  /// Set locale preference and update actual locale
  Future<void> setPreference(LocalePreference preference) async {
    state = preference;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, preference.name);
    
    _updateLocaleBasedOnPreference();
  }
  
  /// Update actual locale based on current preference
  void _updateLocaleBasedOnPreference() {
    final localeNotifier = _ref.read(localeProvider.notifier);
    
    switch (state) {
      case LocalePreference.auto:
        final deviceLocale = _getDeviceLocale();
        localeNotifier._setLocale(deviceLocale);
        break;
      case LocalePreference.french:
        localeNotifier._setLocale(const Locale('fr'));
        break;
      case LocalePreference.english:
        localeNotifier._setLocale(const Locale('en'));
        break;
    }
  }
  
  /// Get device locale with proper mapping
  Locale _getDeviceLocale() {
    try {
      if (kIsWeb) {
        // Web: Default to English for now (avoids platform import issues)
        return const Locale('en');
      } else {
        // Native: Use Flutter's built-in locale detection
        // This works without importing dart:io directly
        final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
        final deviceLocales = platformDispatcher.locales;
        
        if (deviceLocales.isNotEmpty) {
          final primaryLocale = deviceLocales.first;
          return _mapToSupportedLocale(primaryLocale.languageCode);
        }
        
        // Fallback if no locales found
        return const Locale('en');
      }
    } catch (e) {
      // Fallback to English on any detection failure
      return const Locale('en');
    }
  }
  
  /// Map device locale variants to supported locales
  Locale _mapToSupportedLocale(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'fr':
        return const Locale('fr');
      case 'en':
        return const Locale('en');
      default:
        // Fallback to English for unsupported locales
        return const Locale('en');
    }
  }
  
  /// Get current effective locale (what the app is actually using)
  Locale getCurrentEffectiveLocale() {
    return _ref.read(localeProvider);
  }
  
  /// Get device locale for display purposes
  Locale getDeviceLocale() {
    return _getDeviceLocale();
  }
}

/// State notifier for managing actual app locale
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr')); // Default to French while loading
  
  /// Internal method to set locale (called by LocalePreferenceNotifier)
  void _setLocale(Locale locale) {
    state = locale;
  }
  
  /// Get available locales
  static List<Locale> get supportedLocales => [
    const Locale('fr'), // French (primary)
    const Locale('en'), // English (fallback)
  ];
  
  /// Check if current locale is French
  bool get isFrench => state.languageCode == 'fr';
  
  /// Check if current locale is English  
  bool get isEnglish => state.languageCode == 'en';
}
