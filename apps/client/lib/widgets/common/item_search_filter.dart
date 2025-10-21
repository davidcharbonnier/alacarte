import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/rateable_item.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';

/// Generic search and filter interface that adapts to any item type
class ItemSearchAndFilter extends ConsumerStatefulWidget {
  final String itemType;
  final Function(String) onSearchChanged;
  final Function(String, String?) onFilterChanged;
  final Function() onClearFilters;
  final Map<String, List<String>> availableFilters;
  final Map<String, String> activeFilters;
  final String currentSearchQuery;
  final int totalItems;
  final int filteredItems;
  final bool isPersonalListTab; // New property to determine context

  const ItemSearchAndFilter({
    super.key,
    required this.itemType,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClearFilters,
    required this.availableFilters,
    required this.activeFilters,
    required this.currentSearchQuery,
    required this.totalItems,
    required this.filteredItems,
    this.isPersonalListTab = false,
  });

  @override
  ConsumerState<ItemSearchAndFilter> createState() =>
      _ItemSearchAndFilterState();
}

class _ItemSearchAndFilterState extends ConsumerState<ItemSearchAndFilter> {
  final _searchController = TextEditingController();
  bool _isFiltersExpanded = false; // Add collapsible state

  // Add getter for easier access
  bool get isPersonalListTab => widget.isPersonalListTab;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.currentSearchQuery;

    // Auto-expand filters if there are active filters
    _isFiltersExpanded = widget.activeFilters.isNotEmpty;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      widget.currentSearchQuery.isNotEmpty || widget.activeFilters.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar with filter toggle
            _buildSearchBarWithFilterToggle(),

            // Collapsible filter section
            if (_isFiltersExpanded && widget.availableFilters.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingM),
              _buildFilterChips(),
            ],

            // Results summary (always show when there are active filters)
            if (_hasActiveFilters) ...[
              const SizedBox(height: AppConstants.spacingM),
              _buildResultsSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBarWithFilterToggle() {
    final activeFilterCount = widget.activeFilters.length;

    return Row(
      children: [
        // Search icon
        Icon(
          Icons.search,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          size: AppConstants.iconM,
        ),

        const SizedBox(width: AppConstants.spacingS),

        // Search field
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _getSearchHint(),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: widget.onSearchChanged,
          ),
        ),

        // Clear search button
        if (widget.currentSearchQuery.isNotEmpty)
          IconButton(
            onPressed: () {
              _searchController.clear();
              widget.onSearchChanged('');
            },
            icon: const Icon(Icons.clear),
            iconSize: AppConstants.iconM,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),

        // Filter toggle button (only show if filters are available)
        if (widget.availableFilters.isNotEmpty)
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isFiltersExpanded = !_isFiltersExpanded;
                  });
                },
                icon: Icon(
                  _isFiltersExpanded
                      ? Icons.filter_list
                      : Icons.filter_list_outlined,
                  color: activeFilterCount > 0
                      ? AppConstants.primaryColor
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
                iconSize: AppConstants.iconM,
                tooltip: _isFiltersExpanded
                    ? context.l10n.hideFilters
                    : context.l10n.showFilters,
              ),

              // Active filter count badge
              if (activeFilterCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      activeFilterCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

        // Clear all filters button (when filters are active)
        if (activeFilterCount > 0)
          IconButton(
            onPressed: widget.onClearFilters,
            icon: const Icon(Icons.filter_alt_off),
            iconSize: AppConstants.iconM,
            color: Theme.of(context).colorScheme.error,
            tooltip: context.l10n.clearAllFilters,
          ),
      ],
    );
  }

  String _getSearchHint() {
    // Use parameterized search hint with item type
    final localizedItemType = ItemTypeLocalizer.getLocalizedItemType(
      context,
      widget.itemType,
    );
    return context.l10n.searchItemsByName(localizedItemType.toLowerCase());
  }

  Widget _buildFilterChips() {
    final chips = <Widget>[];

    // Add filter chips for each available category
    for (final category in widget.availableFilters.entries) {
      final isActive = widget.activeFilters.containsKey(category.key);

      chips.add(
        FilterChip(
          label: Text(_getFilterChipLabel(category.key)),
          selected: isActive,
          onSelected: (selected) =>
              _showFilterDialog(category.key, category.value),
          selectedColor: AppConstants.primaryColor.withOpacity(0.2),
          checkmarkColor: AppConstants.primaryColor,
        ),
      );
    }

    // Add rating-based filters
    chips.addAll(_buildRatingFilters());

    return Wrap(
      spacing: AppConstants.spacingS,
      runSpacing: AppConstants.spacingS,
      children: chips,
    );
  }

  List<Widget> _buildRatingFilters() {
    if (widget.isPersonalListTab) {
      // Personal list tab: filter by rating source
      return [
        FilterChip(
          label: Text(context.l10n.myRatingsFilter),
          selected: widget.activeFilters['rating_source'] == 'personal',
          onSelected: (selected) {
            widget.onFilterChanged(
              'rating_source',
              selected ? 'personal' : null,
            );
          },
          selectedColor: AppConstants.primaryColor.withOpacity(0.2),
          checkmarkColor: AppConstants.primaryColor,
        ),
        FilterChip(
          label: Text(context.l10n.recommendationsFilter),
          selected: widget.activeFilters['rating_source'] == 'recommendations',
          onSelected: (selected) {
            widget.onFilterChanged(
              'rating_source',
              selected ? 'recommendations' : null,
            );
          },
          selectedColor: AppConstants.primaryColor.withOpacity(0.2),
          checkmarkColor: AppConstants.primaryColor,
        ),
      ];
    } else {
      // All items tab: filter by rating existence
      return [
        FilterChip(
          label: Text(context.l10n.ratedFilter),
          selected: widget.activeFilters['rating_status'] == 'has_ratings',
          onSelected: (selected) {
            widget.onFilterChanged(
              'rating_status',
              selected ? 'has_ratings' : null,
            );
          },
          selectedColor: AppConstants.primaryColor.withOpacity(0.2),
          checkmarkColor: AppConstants.primaryColor,
        ),
        FilterChip(
          label: Text(context.l10n.unratedFilter),
          selected: widget.activeFilters['rating_status'] == 'no_ratings',
          onSelected: (selected) {
            widget.onFilterChanged(
              'rating_status',
              selected ? 'no_ratings' : null,
            );
          },
          selectedColor: AppConstants.primaryColor.withOpacity(0.2),
          checkmarkColor: AppConstants.primaryColor,
        ),
      ];
    }
  }

  String _getFilterChipLabel(String categoryKey) {
    return _getLocalizedCategoryName(categoryKey);
  }

  String _getLocalizedCategoryName(String categoryKey) {
    switch (categoryKey.toLowerCase()) {
      case 'type':
        return context.l10n.type;
      case 'origin':
        return context.l10n.origin;
      case 'producer':
        return context.l10n.producer;
      case 'profile':
        return context.l10n.profileLabel;
      case 'color':
        return context.l10n.colorLabel;
      case 'country':
        return context.l10n.country;
      case 'region':
        return context.l10n.region;
      case 'roaster':
        return context.l10n.roasterLabel;
      case 'processing_method':
        return context.l10n.processingMethodLabel;
      case 'roast_level':
        return context.l10n.roastLevelLabel;
      default:
        return categoryKey;
    }
  }

  void _showFilterDialog(String categoryKey, List<String> options) {
    showDialog(
      context: context,
      builder: (context) => _FilterSelectionDialog(
        categoryKey: categoryKey,
        categoryName: _getLocalizedCategoryName(categoryKey),
        options: options,
        currentValue: widget.activeFilters[categoryKey],
        onChanged: (value) => widget.onFilterChanged(categoryKey, value),
      ),
    );
  }

  Widget _buildResultsSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        context.l10n.showingResults(widget.filteredItems, widget.totalItems),
        style: TextStyle(
          color: AppConstants.primaryColor,
          fontSize: AppConstants.fontS,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Dialog for selecting filter values
class _FilterSelectionDialog extends StatelessWidget {
  final String categoryKey;
  final String categoryName;
  final List<String> options;
  final String? currentValue;
  final Function(String?) onChanged;

  const _FilterSelectionDialog({
    required this.categoryKey,
    required this.categoryName,
    required this.options,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: AppConstants.cardPadding,
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: AppConstants.primaryColor),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Text(
                      context.l10n.filterBy(categoryName),
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

            // Options list
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingS,
                ),
                children: [
                  // "All" option
                  ListTile(
                    title: Text(context.l10n.allFilterOption),
                    leading: Radio<String?>(
                      value: null,
                      groupValue: currentValue,
                      onChanged: (value) {
                        onChanged(value);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),

                  // Individual options
                  ...options.map(
                    (option) => ListTile(
                      title: Text(option),
                      leading: Radio<String?>(
                        value: option,
                        groupValue: currentValue,
                        onChanged: (value) {
                          onChanged(value);
                          Navigator.of(context).pop();
                        },
                      ),
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
}
