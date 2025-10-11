import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../flutter_gen/gen_l10n/app_localizations.dart';
import '../../routes/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../utils/appbar_helper.dart';
import '../../utils/localization_utils.dart';

/// Screen for completing user profile setup after OAuth authentication
class DisplayNameSetupScreen extends ConsumerStatefulWidget {
  const DisplayNameSetupScreen({super.key});

  @override
  ConsumerState<DisplayNameSetupScreen> createState() =>
      _DisplayNameSetupScreenState();
}

class _DisplayNameSetupScreenState
    extends ConsumerState<DisplayNameSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _discoverable = true;
  bool _isCheckingAvailability = false;
  bool? _isNameAvailable; // Track availability state instead of message content
  String? _availabilityError; // Track error state separately
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    // Pre-populate with generated display name if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && user.fullName.isNotEmpty) {
        // Generate suggested display name
        final parts = user.fullName.split(' ');
        if (parts.length >= 2) {
          final firstName = parts.first;
          final lastInitial = parts.last.substring(0, 1).toUpperCase();
          _displayNameController.text = '$firstName $lastInitial.';
          // Check availability of the pre-populated name
          _checkAvailabilityDebounced(_displayNameController.text);
        } else {
          _displayNameController.text = parts.first;
          _checkAvailabilityDebounced(_displayNameController.text);
        }
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    // Listen for profile completion
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !next.needsProfileSetup) {
        // Profile completed - go to home
        context.go(RouteNames.home);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.completeYourProfile),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: AppBarHelper.buildStandardActions(
          context,
          ref,
          showUserProfile: false, // No user profile on profile setup screen
        ),
        automaticallyImplyLeading: false, // Can't go back once authenticated
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const SizedBox(height: 40),
              Icon(
                Icons.person_add,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.welcomeToAlacarte,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (authState.user != null)
                Text(
                  context.l10n.hiUserSetupProfile(authState.user!.fullName.split(' ').first),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 40),

              // Error display
              if (authState.error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Display name field
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: context.l10n.displayName,
                  helperText: context.l10n.displayNameFieldHelper,
                  suffixIcon: _isCheckingAvailability
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isNameAvailable != null
                      ? Icon(
                          _isNameAvailable!
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: _isNameAvailable!
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        )
                      : null,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.displayNameRequired;
                  }
                  if (value.trim().length < 2) {
                    return context.l10n.displayNameTooShort;
                  }
                  if (value.trim().length > 50) {
                    return context.l10n.displayNameTooLong;
                  }
                  return null;
                },
                onChanged: _onDisplayNameChanged,
                // Remove onTapOutside to prevent unnecessary API calls
              ),

              // Availability message display
              if (_isNameAvailable != null || _availabilityError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _availabilityError ?? (
                      _isNameAvailable!
                        ? context.l10n.displayNameAvailable
                        : context.l10n.displayNameTaken
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _availabilityError != null
                        ? Theme.of(context).colorScheme.error
                        : _isNameAvailable!
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Privacy settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.privacySettingsTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(context.l10n.discoverableByOthers),
                        subtitle: Text(context.l10n.discoverabilityHelper),
                        value: _discoverable,
                        onChanged: (value) {
                          // Only update the toggle state, don't trigger display name check
                          setState(() {
                            _discoverable = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Complete profile button
              FilledButton.icon(
                onPressed: _canCompleteProfile() && !authState.isLoading
                    ? _completeProfile
                    : null,
                icon: authState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  authState.isLoading
                      ? context.l10n.settingUpProfile
                      : context.l10n.completeProfile,
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 24),

              // Privacy note
              Container(
                padding: const EdgeInsets.all(16),
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
                          Icons.privacy_tip_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                        context.l10n.yourPrivacyMatters,
                        style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(
                        color: Theme.of(
                        context,
                        ).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.privacyExplanation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canCompleteProfile() {
    return _displayNameController.text.trim().isNotEmpty &&
        _displayNameController.text.trim().length >= 2 &&
        _isNameAvailable == true &&
        !_isCheckingAvailability;
  }

  /// Handle display name input changes with debouncing
  void _onDisplayNameChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Clear availability state while typing
    if (_isNameAvailable != null || _availabilityError != null) {
      setState(() {
        _isNameAvailable = null;
        _availabilityError = null;
      });
    }

    // Only set timer if the value is long enough to check
    if (value.trim().length >= 2) {
      // Set new timer for 1 second delay
      _debounceTimer = Timer(const Duration(seconds: 1), () {
        _checkAvailabilityDebounced(value);
      });
    }
  }

  /// Check availability with proper debouncing
  Future<void> _checkAvailabilityDebounced(String displayName) async {
    if (displayName.trim().length < 2) {
      setState(() {
        _isNameAvailable = null;
        _availabilityError = null;
        _isCheckingAvailability = false;
      });
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
      _isNameAvailable = null;
      _availabilityError = null;
    });

    try {
      final isAvailable = await ref
          .read(authProvider.notifier)
          .isDisplayNameAvailable(displayName.trim());

      if (mounted && _displayNameController.text.trim() == displayName.trim()) {
        setState(() {
          _isCheckingAvailability = false;
          _isNameAvailable = isAvailable;
          _availabilityError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
          _isNameAvailable = null;
          _availabilityError = context.l10n.couldNotCheckAvailability;
        });
      }
    }
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate() || !_canCompleteProfile()) {
      return;
    }

    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();

    // Complete profile
    await ref
        .read(authProvider.notifier)
        .completeProfile(_displayNameController.text.trim(), _discoverable);
  }
}
