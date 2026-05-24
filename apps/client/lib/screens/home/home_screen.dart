import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/rating_provider.dart';
import '../../providers/schema_provider.dart';
import '../../providers/dynamic_item_provider.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';
import '../../utils/appbar_helper.dart';
import '../../utils/item_provider_helper.dart';
import '../../utils/schema_icon_utils.dart';
import '../../routes/route_names.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasLoadedSchemas = false;
  bool _hasLoadedStats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    if (_hasLoadedSchemas) return;
    final schemaState = ref.read(schemaProvider);
    if (schemaState.schemas.isEmpty && !schemaState.isLoading) {
      _hasLoadedSchemas = true;
      ref.read(schemaProvider.notifier).loadSchemas();
    }
  }

  void _loadTypeStats() {
    if (_hasLoadedStats) return;
    final schemaState = ref.read(schemaProvider);
    for (final schema in schemaState.schemas) {
      if (schema.isActive) {
        ref.read(dynamicItemProvider.notifier).loadTypeStats(schema.name);
      }
    }
    _hasLoadedStats = true;
  }

  void _navigateToItemType(BuildContext context, String itemType) {
    GoRouter.of(context).go('${RouteNames.itemType}/$itemType');
  }

  @override
  Widget build(BuildContext context) {
    ref.read(ratingListenerProvider);

    final schemaState = ref.watch(schemaProvider);
    final dynamicItemState = ref.watch(dynamicItemProvider);
    final ratingState = ref.watch(ratingProvider);

    if (schemaState.schemas.isEmpty &&
        !schemaState.isLoading &&
        !_hasLoadedSchemas) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hasLoadedSchemas = true;
        ref.read(schemaProvider.notifier).loadSchemas();
      });
    }

    if (schemaState.schemas.isNotEmpty && !_hasLoadedStats) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTypeStats();
      });
    }

    final activeSchemas = schemaState.schemas.where((s) => s.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('À la carte'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: AppBarHelper.buildStandardActions(
          context,
          ref,
          showUserProfile: true,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(schemaProvider.notifier).refreshSchemas();
          _hasLoadedStats = false;
          _loadTypeStats();
          await ref.read(ratingProvider.notifier).refreshRatings();
        },
        child: schemaState.isLoading && activeSchemas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : schemaState.error != null && activeSchemas.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text('Failed to load item types'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(schemaProvider.notifier).loadSchemas(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppConstants.screenPadding,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.yourPreferenceLists,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        ...activeSchemas.map((schema) {
                          final stats = dynamicItemState.typeStats(schema.name);
                          final totalItems =
                              stats?['total_items'] as int? ?? 0;
                          final userRatedCount =
                              stats?['user_rated_count'] as int? ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppConstants.spacingM,
                            ),
                            child: _buildSchemaCard(
                              context,
                              schema.name,
                              schema.displayName,
                              schema.icon,
                              schema.color,
                              totalItems,
                              userRatedCount,
                            ),
                          );
                        }),
                        if (activeSchemas.isEmpty && !schemaState.isLoading)
                          _buildComingSoonCard(
                            context,
                            context.l10n.moreCategoriesTitle,
                            Icons.add_box,
                            Colors.grey,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSchemaCard(
    BuildContext context,
    String itemType,
    String displayName,
    String iconName,
    String colorHex,
    int totalItems,
    int myRatings,
  ) {
    final icon = SchemaIconUtils.getIcon(iconName);
    final color = SchemaIconUtils.parseColor(colorHex);

    return Card(
      child: InkWell(
        onTap: () => _navigateToItemType(context, itemType),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: AppConstants.cardPadding,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
                child: Icon(icon, size: AppConstants.iconXL, color: color),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      context.l10n.itemsAvailable(totalItems),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      context.l10n.inYourList(myRatings),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard(
    BuildContext context,
    String displayName,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
              ),
              child: Icon(icon, size: AppConstants.iconXL, color: Colors.grey),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXS),
                  Text(
                    context.l10n.moreCategoriesSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.lock_outline, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}