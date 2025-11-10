import 'package:flutter/material.dart';
import '../../models/rateable_item.dart';
import '../../models/cheese_item.dart';
import '../../models/gin_item.dart';
import '../../models/wine_item.dart';
import '../../models/coffee_item.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';
import '../items/item_image.dart';

/// Reusable header component for any item type detail display
class ItemDetailHeader extends StatelessWidget {
  final RateableItem item;
  final VoidCallback? onEditPressed;

  const ItemDetailHeader({super.key, required this.item, this.onEditPressed});

  /// Get the badge text based on item type
  String _getBadgeText() {
    switch (item.itemType) {
      case 'cheese':
        return item.categories['type'] ?? 'Unknown';
      case 'gin':
        return item.categories['profile'] ?? 'Unknown';
      case 'wine':
        return item.categories['color'] ?? 'Unknown';
      case 'coffee':
        return item.categories['roast_level'] ?? 'Unknown';
      default:
        return item.categories['type'] ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get image URL based on item type
    String? imageUrl;
    if (item is CheeseItem) {
      imageUrl = (item as CheeseItem).imageUrl;
    } else if (item is GinItem) {
      imageUrl = (item as GinItem).imageUrl;
    } else if (item is WineItem) {
      imageUrl = (item as WineItem).imageUrl;
    } else if (item is CoffeeItem) {
      imageUrl = (item as CoffeeItem).imageUrl;
    }

    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item name and type (common to all items)
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(
                      color: AppConstants.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _getBadgeText(),
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: AppConstants.fontS,
                    ),
                  ),
                ),
                // Edit button
                if (onEditPressed != null) ...[
                  const SizedBox(width: AppConstants.spacingS),
                  IconButton(
                    onPressed: onEditPressed,
                    icon: const Icon(Icons.edit),
                    style: IconButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      foregroundColor: AppConstants.primaryColor,
                    ),
                    tooltip: context.l10n.editItemTooltip,
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Item-specific fields (from detailFields) - excluding description
            ...(() {
              if (item is CheeseItem) {
                return (item as CheeseItem).getLocalizedDetailFields(context);
              } else if (item is GinItem) {
                return (item as GinItem).getLocalizedDetailFields(context);
              } else if (item is WineItem) {
                return (item as WineItem).getLocalizedDetailFields(context);
              } else if (item is CoffeeItem) {
                return (item as CoffeeItem).getLocalizedDetailFields(context);
              }
              return item.detailFields;
            }())
                .where((field) => !field.isDescription)
                .map(
                  (field) {
                    // Special handling for tasting notes (coffee)
                    if (field.label == context.l10n.tastingNotesLabel && item is CoffeeItem) {
                      final coffeeItem = item as CoffeeItem;
                      if (coffeeItem.tastingNotes != null && coffeeItem.tastingNotes!.isNotEmpty) {
                        return _buildTastingNotesField(context, field.label, coffeeItem.tastingNotes!, field.icon);
                      }
                    }
                    return _buildDetailRow(context, field.label, field.value, field.icon);
                  },
                ),

            // Image display (centered, before description)
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingM),
              const Divider(),
              const SizedBox(height: AppConstants.spacingM),
              Center(
                child: ItemImageFull(
                  imageUrl: imageUrl,
                  itemType: item.itemType,
                  itemName: item.name,
                  maxHeight: 250,
                ),
              ),
            ],

            // Description field (if available)
            ...(() {
              if (item is CheeseItem) {
                return (item as CheeseItem).getLocalizedDetailFields(context);
              } else if (item is GinItem) {
                return (item as GinItem).getLocalizedDetailFields(context);
              } else if (item is WineItem) {
                return (item as WineItem).getLocalizedDetailFields(context);
              } else if (item is CoffeeItem) {
                return (item as CoffeeItem).getLocalizedDetailFields(context);
              }
              return item.detailFields;
            }())
                .where((field) => field.isDescription)
                .map(
                  (field) => _buildDescriptionField(context, field),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData? icon,
  ) {
    // Check if this is a boolean field (Yes/No or Oui/Non)
    final isYes = value == context.l10n.yes || value == 'Yes' || value == 'Oui';
    final isNo = value == context.l10n.no || value == 'No' || value == 'Non';
    final isBooleanField = isYes || isNo;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppConstants.iconS,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: AppConstants.spacingS),
          ],
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Expanded(
            child: isBooleanField
                ? Row(
                    children: [
                      Icon(
                        isYes ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: AppConstants.spacingXS),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                : Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(BuildContext context, DetailField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppConstants.spacingM),
        const Divider(),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          field.label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(field.value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildTastingNotesField(
    BuildContext context,
    String label,
    List<String> notes,
    IconData? icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppConstants.iconS,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: AppConstants.spacingS),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: notes.map((note) {
              return Chip(
                label: Text(
                  note,
                  style: const TextStyle(
                    fontSize: AppConstants.fontS,
                  ),
                ),
                backgroundColor: Colors.brown.shade50,
                side: BorderSide(
                  color: Colors.brown.shade200,
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXS,
                  vertical: 0,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
