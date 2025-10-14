import 'package:flutter/material.dart';
import '../../models/rateable_item.dart';
import '../../models/cheese_item.dart';
import '../../models/gin_item.dart';
import '../../models/wine_item.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';

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
      default:
        return item.categories['type'] ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3),
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
                      backgroundColor: AppConstants.primaryColor.withOpacity(
                        0.1,
                      ),
                      foregroundColor: AppConstants.primaryColor,
                    ),
                    tooltip: context.l10n.editItemTooltip,
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Item-specific fields (from detailFields)
            ...(() {
              if (item is CheeseItem) {
                return (item as CheeseItem).getLocalizedDetailFields(context);
              } else if (item is GinItem) {
                return (item as GinItem).getLocalizedDetailFields(context);
              } else if (item is WineItem) {
                return (item as WineItem).getLocalizedDetailFields(context);
              }
              return item.detailFields;
            }())
                .map(
                  (field) => field.isDescription
                      ? _buildDescriptionField(context, field)
                      : _buildDetailRow(
                          context,
                          field.label,
                          field.value,
                          field.icon,
                        ),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: AppConstants.spacingS),
          ],
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: isBooleanField
                ? Row(
                    children: [
                      Icon(
                        isYes ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
}
