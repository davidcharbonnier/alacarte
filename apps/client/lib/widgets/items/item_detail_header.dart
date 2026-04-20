import 'package:flutter/material.dart';
import '../../models/rateable_item.dart';
import '../../models/dynamic_item.dart';
import '../../utils/constants.dart';
import '../../utils/localization_utils.dart';
import '../items/item_image.dart';

class ItemDetailHeader extends StatelessWidget {
  final RateableItem item;
  final VoidCallback? onEditPressed;

  const ItemDetailHeader({super.key, required this.item, this.onEditPressed});

  DynamicItem get _dynamicItem => item as DynamicItem;

  String _getBadgeText(BuildContext context) {
    final primaryField = _dynamicItem.schema?.primaryField;
    if (primaryField != null) {
      final value = _dynamicItem.fieldValues[primaryField.key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return _dynamicItem.schemaName;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _dynamicItem.imageUrl;
    final detailFields = _dynamicItem.detailFields;

    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    _getBadgeText(context),
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: AppConstants.fontS,
                    ),
                  ),
                ),
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
            ...detailFields
                .where((field) => !field.isDescription)
                .map(
                  (field) => _buildDetailRow(
                    context,
                    field.label,
                    field.value,
                    field.icon,
                  ),
                ),
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
            ...detailFields
                .where((field) => field.isDescription)
                .map((field) => _buildDescriptionField(context, field)),
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
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: AppConstants.spacingS),
          ],
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Expanded(
            child: isBooleanField
                ? Row(
                    children: [
                      Icon(
                        isYes
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
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
