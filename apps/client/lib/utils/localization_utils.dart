import 'package:flutter/material.dart';
import 'package:alc_client/flutter_gen/gen_l10n/app_localizations.dart';

/// Extension to easily access AppLocalizations in any widget
extension LocalizationExtension on BuildContext {
  /// Get the current AppLocalizations instance
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Get the current locale
  Locale get locale => Localizations.localeOf(this);

  /// Check if current locale is French
  bool get isFrench => locale.languageCode == 'fr';

  /// Check if current locale is English
  bool get isEnglish => locale.languageCode == 'en';
}

/// Utility class for handling localized item type names
class ItemTypeLocalizer {
  /// Get localized name for item type
  static String getLocalizedItemType(BuildContext context, String itemType) {
    final l10n = context.l10n;

    switch (itemType.toLowerCase()) {
      case 'cheese':
        return l10n.cheese;
      case 'gin':
        return l10n.gin;
      case 'wine':
        return l10n.wine;
      default:
        // Fallback to capitalized item type if no translation exists
        return itemType.isNotEmpty
            ? '${itemType[0].toUpperCase()}${itemType.substring(1)}'
            : itemType;
    }
  }

  /// Get localized plural form (if needed in the future)
  static String getLocalizedItemTypePlural(
    BuildContext context,
    String itemType,
  ) {
    // For now, just add 's' for English or return same for French
    // This can be expanded with proper plural rules later
    final localized = getLocalizedItemType(context, itemType);

    if (context.isEnglish && !localized.endsWith('s')) {
      return '${localized}s';
    }

    return localized;
  }

  /// Get localized "All [ItemType]s" text
  static String getAllItemsText(BuildContext context, String itemType) {
    final localizedType = getLocalizedItemType(context, itemType);
    return context.l10n.allItems(localizedType);
  }

  /// Get localized "My [ItemType] List" text
  static String getMyItemListText(BuildContext context, String itemType) {
    final localizedType = getLocalizedItemType(context, itemType);
    return context.l10n.myItemList(localizedType);
  }

  /// Get localized "Add [ItemType]" text
  static String getAddItemText(BuildContext context, String itemType) {
    final localizedType = getLocalizedItemType(context, itemType);
    return context.l10n.addItem(localizedType);
  }
}
