import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../routes/route_names.dart';
import '../common/loading_screen.dart';
import '../../services/api_service.dart';
import '../../utils/localization_utils.dart';

/// App initialization screen that handles authentication check and routing
/// Shows beautiful loading screen while determining where to route the user
class AppInitializationScreen extends ConsumerStatefulWidget {
  const AppInitializationScreen({super.key});

  @override
  ConsumerState<AppInitializationScreen> createState() => _AppInitializationScreenState();
}

class _AppInitializationScreenState extends ConsumerState<AppInitializationScreen> {
  String? loadingMessage;
  bool hasCompleted = false;
  bool hasInitialized = false;
  
  @override
  void initState() {
    super.initState();
    // Start with initial loading message - will be localized in build()
    loadingMessage = null; // Will use default from LoadingScreen
    
    // Show extended message after 2 seconds if still loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !hasCompleted) {
        setState(() {
          loadingMessage = 'settingUpPreferenceHub'; // Key for localization
        });
      }
    });
    
    // Show connectivity message after 4 seconds if still loading
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !hasCompleted) {
        setState(() {
          loadingMessage = 'verifyingAccount'; // Key for localization
        });
      }
    });
    
    // Use a simple timer check every 500ms to see if auth is ready
    _startAuthCheck();
  }
  
  void _startAuthCheck() {
    int attempts = 0;
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      attempts++;
      
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (hasCompleted) {
        timer.cancel();
        return;
      }
      
      // Force completion after 20 attempts (10 seconds)
      if (attempts > 20) {
        if (kDebugMode) print('🆘 Timer timeout after 20 attempts (10s), forcing completion');
        timer.cancel();
        final currentAuth = ref.read(authProvider);
        _handleAuthStateComplete(currentAuth);
        return;
      }
      
      final authState = ref.read(authProvider);
      final connectivityState = ref.read(connectivityStateProvider);
      
      // If offline, let main.dart handle it (but treat null as potentially online)
      if (connectivityState.value != ConnectivityState.online && connectivityState.value != null) {
        return;
      }
      
      // If auth is ready, proceed
      if (!authState.isLoading) {
        timer.cancel();
        _handleAuthStateComplete(authState);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Monitor connectivity state - if offline, let main.dart show offline screen
    final connectivityState = ref.watch(connectivityStateProvider);
    
    // If offline, don't process anything - let main.dart show offline screen
    final isOffline = connectivityState.value != ConnectivityState.online;
    if (isOffline && !hasCompleted && connectivityState.value != null) {
      return LoadingScreen(message: context.l10n.checkingConnection);
    }
    
    return LoadingScreen(message: _getLocalizedMessage(context, loadingMessage));
  }
  
  String? _getLocalizedMessage(BuildContext context, String? messageKey) {
    if (messageKey == null) return null;
    
    switch (messageKey) {
      case 'settingUpPreferenceHub':
        return context.l10n.settingUpPreferenceHub;
      case 'verifyingAccount':
        return context.l10n.verifyingAccount;
      case 'workingOffline':
        return context.l10n.workingOffline;
      case 'profileSetupRequired':
        return context.l10n.profileSetupRequired;
      case 'readyWelcomeBack':
        return context.l10n.readyWelcomeBack;
      case 'signInRequired':
        return context.l10n.signInRequired;
      case 'preparingPreferences':
        return context.l10n.preparingPreferences;
      default:
        return messageKey; // Fallback to the key itself
    }
  }
  
  void _handleAuthStateComplete(AuthState authState) {
    if (hasCompleted) return;
    hasCompleted = true;
    
    // Even if isLoading is true, we proceed if we have enough info to make a decision
    if (authState.isAuthenticated) {
      if (authState.needsProfileSetup) {
        // Authenticated but needs profile completion
        setState(() {
          loadingMessage = 'profileSetupRequired';
        });
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            context.go(RouteNames.displayNameSetup);
          }
        });
      } else {
        // Fully authenticated and profile complete
        setState(() {
          loadingMessage = 'readyWelcomeBack';
        });
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            context.go(RouteNames.home);
          }
        });
      }
    } else {
      // Not authenticated - needs to sign in
      setState(() {
        loadingMessage = 'signInRequired';
      });
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          context.go(RouteNames.auth);
        }
      });
    }
  }
}
