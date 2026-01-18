import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../models/rating.dart';
import '../../models/api_response.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';

/// Dialog for sharing/unsharing a rating with users
class ShareRatingDialog extends ConsumerStatefulWidget {
  final Rating rating;
  final Function(List<int> shareWithUserIds, List<int> removeFromUserIds)
  onShare;
  final List<int>? currentlySharedWith; // Pre-selected users

  const ShareRatingDialog({
    super.key,
    required this.rating,
    required this.onShare,
    this.currentlySharedWith,
  });

  @override
  ConsumerState<ShareRatingDialog> createState() => _ShareRatingDialogState();
}

class _ShareRatingDialogState extends ConsumerState<ShareRatingDialog> {
  List<User> _allUsers = [];
  List<int> _selectedUserIds = [];
  List<int> _initiallySharedWith = []; // Track original state
  bool _isLoadingUsers = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    // Pre-fill with currently shared users if provided
    if (widget.currentlySharedWith != null) {
      _selectedUserIds = List<int>.from(widget.currentlySharedWith!);
      _initiallySharedWith = List<int>.from(widget.currentlySharedWith!);
    }
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _loadError = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getShareableUsers();

      response.when(
        success: (data, _) {
          // The backend returns {"previous_connections": [], "discoverable": []}
          // Handle potential null values safely
          final previousConnectionsData = data['previous_connections'] as List?;
          final discoverableData = data['discoverable'] as List?;

          final previousConnections = (previousConnectionsData ?? [])
              .map(
                (userData) => User.fromJson(userData as Map<String, dynamic>),
              )
              .toList();
          final discoverableUsers = (discoverableData ?? [])
              .map(
                (userData) => User.fromJson(userData as Map<String, dynamic>),
              )
              .toList();

          // Combine both lists
          _allUsers = [...previousConnections, ...discoverableUsers];

          // Sort alphabetically by display name (A to Z, case-insensitive)
          _allUsers.sort((a, b) {
            final nameA = a.displayName.isNotEmpty ? a.displayName : a.fullName;
            final nameB = b.displayName.isNotEmpty ? b.displayName : b.fullName;
            return nameA.toLowerCase().compareTo(nameB.toLowerCase());
          });
        },
        error: (message, statusCode, errorCode, details) {
          _loadError = message;
        },
        loading: () {
          // Keep loading state
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  void _toggleUserSelection(int? userId) {
    if (userId == null) return;

    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  bool get _hasChanges {
    // Compare current selection with initial state
    if (_selectedUserIds.length != _initiallySharedWith.length) return true;

    for (final userId in _selectedUserIds) {
      if (!_initiallySharedWith.contains(userId)) return true;
    }

    for (final userId in _initiallySharedWith) {
      if (!_selectedUserIds.contains(userId)) return true;
    }

    return false;
  }

  void _makePrivate() {
    setState(() {
      _selectedUserIds.clear();
    });
  }

  void _saveChanges() {
    if (_hasChanges) {
      // Calculate which users to share with (newly selected)
      final shareWithUserIds = _selectedUserIds
          .where((userId) => !_initiallySharedWith.contains(userId))
          .toList();

      // Calculate which users to remove (previously selected but now unselected)
      final removeFromUserIds = _initiallySharedWith
          .where((userId) => !_selectedUserIds.contains(userId))
          .toList();

      widget.onShare(shareWithUserIds, removeFromUserIds);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog header
            Padding(
              padding: AppConstants.cardPadding,
              child: Row(
                children: [
                  Icon(
                    Icons.share,
                    color: AppConstants.primaryColor,
                    size: AppConstants.iconM,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      context.l10n.shareRatingWith,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Instructions
            Padding(
              padding: AppConstants.cardPadding,
              child: Text(
                context.l10n.selectUsersToShare,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),

            // Make Private button (if currently shared with anyone)
            if (_initiallySharedWith.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _makePrivate,
                    icon: const Icon(Icons.lock_outline),
                    label: Text(context.l10n.makePrivate),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),

            if (_initiallySharedWith.isNotEmpty)
              const SizedBox(height: AppConstants.spacingM),

            // User list
            Expanded(child: _buildUserList()),

            const Divider(height: 1),

            // Action buttons
            Padding(
              padding: AppConstants.cardPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.cancel),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  ElevatedButton(
                    onPressed: _hasChanges ? _saveChanges : null,
                    child: Text(
                      _hasChanges
                          ? context.l10n.saveChanges
                          : context.l10n.noChanges,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoadingUsers) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppConstants.spacingM),
              Text(context.l10n.loadingUsers),
            ],
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: AppConstants.iconXL,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                _loadError!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextButton(
                onPressed: _loadUsers,
                child: Text(context.l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (_allUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off,
                size: AppConstants.iconXL,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                context.l10n.noUsersAvailable,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      itemCount: _allUsers.length,
      itemBuilder: (context, index) {
        final user = _allUsers[index];
        final userId = user.id;

        // Skip users with null or invalid IDs
        // ignore: unnecessary_null_comparison
        if (userId == null) {
          return const SizedBox.shrink();
        }

        final isSelected = _selectedUserIds.contains(userId);

        // ignore: sort_child_properties_last
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) => _toggleUserSelection(userId),
            title: Text(
              user.displayName.isNotEmpty ? user.displayName : user.fullName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: kDebugMode
                ? Text('ID: $userId') // Debug info only in development
                : null, // No sensitive info in production
            secondary: _buildUserAvatar(user, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildUserAvatar(User user, bool isSelected) {
    final avatarUrl = user.avatar;
    final userName = user.displayName.isNotEmpty
        ? user.displayName
        : user.fullName;

    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: isSelected
            ? AppConstants.primaryColor.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback will be handled by child
        },
        child: avatarUrl.isEmpty
            ? Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: isSelected
                      ? AppConstants.primaryColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        // Add selection indicator overlay
        foregroundColor: isSelected ? AppConstants.primaryColor : null,
      );
    } else {
      // Fallback to initials with selection state
      return CircleAvatar(
        backgroundColor: isSelected
            ? AppConstants.primaryColor
            : Theme.of(context).colorScheme.outline,
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
