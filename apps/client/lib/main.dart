import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:alc_client/flutter_gen/gen_l10n/app_localizations.dart';
import 'routes/app_router.dart';
import 'providers/app_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/rating_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'services/api_service.dart';
import 'screens/common/fullscreen_offline_screen.dart';


void main() async {
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Start connectivity monitoring after binding is initialized
  ApiService.startConnectivityMonitoring();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize reactive listeners for automatic data synchronization
    ref.read(ratingListenerProvider);
    
    // Initialize auth provider for OAuth authentication
    ref.read(authProvider);
    
    // Initialize locale preference system
    ref.read(localePreferenceProvider);
    
    final isDarkMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    
    // Watch connectivity state for fullscreen offline mode
    final connectivityState = ref.watch(connectivityStateProvider);
    
    return MaterialApp.router(
      title: 'A la carte',
      debugShowCheckedModeBanner: false,
      
      // Enhanced localization configuration with device locale detection
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      
      // Router configuration
      routerConfig: ref.watch(appRouterProvider),
      
      // Use builder to intercept routing when offline
      builder: (context, child) {
        return connectivityState.when(
          data: (state) {
            if (state == ConnectivityState.online) {
              return child ?? const SizedBox.shrink();
            } else {
              return FullscreenOfflineScreen(connectivityState: state);
            }
          },
          loading: () => child ?? const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const FullscreenOfflineScreen(
            connectivityState: ConnectivityState.networkOffline,
          ),
        );
      },
    );
  }
}
