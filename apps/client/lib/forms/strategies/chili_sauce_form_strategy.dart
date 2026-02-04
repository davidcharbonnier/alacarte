import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../models/chili_sauce_item.dart';
import '../../providers/item_provider.dart';
import '../../utils/localization_utils.dart';
import 'item_form_strategy.dart';
import 'form_field_config.dart';

/// Form strategy implementation for Chili Sauce items
class ChiliSauceFormStrategy extends ItemFormStrategy<ChiliSauceItem> {
  @override
  String get itemType => 'chili-sauce';

  @override
  List<FormFieldConfig> getFormFields() {
    return [
      // Name field - common to all items but with chili-sauce-specific hint
      FormFieldConfig.text(
        key: 'name',
        labelBuilder: (context) => context.l10n.name,
        hintBuilder: (context) => context.l10n.enterChiliSauceName,
        icon: Icons.label,
        required: true,
      ),

      // Brand field - optional for chili sauce
      FormFieldConfig.text(
        key: 'brand',
        labelBuilder: (context) => context.l10n.brandLabel,
        hintBuilder: (context) => context.l10n.enterBrand,
        icon: Icons.business,
        required: false,
      ),

      // Spice Level field - required dropdown for chili sauce
      FormFieldConfig.dropdown(
        key: 'spice_level',
        labelBuilder: (context) => context.l10n.spiceLevelLabel,
        hintBuilder: (context) => context.l10n.selectSpiceLevel,
        options: [
          DropdownOption(
            value: 'Mild',
            labelBuilder: (context) => context.l10n.spiceLevelMild,
          ),
          DropdownOption(
            value: 'Medium',
            labelBuilder: (context) => context.l10n.spiceLevelMedium,
          ),
          DropdownOption(
            value: 'Hot',
            labelBuilder: (context) => context.l10n.spiceLevelHot,
          ),
          DropdownOption(
            value: 'Extra Hot',
            labelBuilder: (context) => context.l10n.spiceLevelExtraHot,
          ),
          DropdownOption(
            value: 'Extreme',
            labelBuilder: (context) => context.l10n.spiceLevelExtreme,
          ),
        ],
        required: true,
      ),

      // Chilis field - optional text field for chili types used
      FormFieldConfig.text(
        key: 'chilis',
        labelBuilder: (context) => context.l10n.chilisLabel,
        hintBuilder: (context) => context.l10n.enterChilis,
        icon: Icons.grass,
        required: false,
      ),

      // Description field - common to all items (optional)
      FormFieldConfig.multiline(
        key: 'description',
        labelBuilder: (context) => context.l10n.description,
        hintBuilder: (context) => context.l10n.enterDescription,
        helperTextBuilder: (context) => context.l10n.optionalFieldHelper(500),
        maxLines: 3,
        maxLength: 500,
      ),
    ];
  }

  @override
  Map<String, TextEditingController> initializeControllers(
    ChiliSauceItem? initialItem,
  ) {
    return {
      'name': TextEditingController(text: initialItem?.name ?? ''),
      'brand': TextEditingController(text: initialItem?.brand ?? ''),
      'spice_level': TextEditingController(
        text: initialItem?.spiceLevel.displayName ?? 'Medium',
      ),
      'chilis': TextEditingController(text: initialItem?.chilis ?? ''),
      'description': TextEditingController(
        text: initialItem?.description ?? '',
      ),
    };
  }

  @override
  ChiliSauceItem buildItem(
    Map<String, TextEditingController> controllers,
    int? itemId,
  ) {
    final spiceLevelString = controllers['spice_level']!.text.trim();
    final spiceLevel = _parseSpiceLevel(spiceLevelString);

    return ChiliSauceItem(
      id: itemId,
      name: controllers['name']!.text.trim(),
      brand: controllers['brand']!.text.trim().isNotEmpty
          ? controllers['brand']!.text.trim()
          : null,
      spiceLevel: spiceLevel,
      chilis: controllers['chilis']!.text.trim().isNotEmpty
          ? controllers['chilis']!.text.trim()
          : null,
      description: controllers['description']!.text.trim().isNotEmpty
          ? controllers['description']!.text.trim()
          : null,
    );
  }

  /// Parse spice level from string
  SpiceLevel _parseSpiceLevel(String value) {
    switch (value.toLowerCase()) {
      case 'mild':
        return SpiceLevel.mild;
      case 'medium':
        return SpiceLevel.medium;
      case 'hot':
        return SpiceLevel.hot;
      case 'extra hot':
      case 'extra_hot':
        return SpiceLevel.extraHot;
      case 'extreme':
        return SpiceLevel.extreme;
      default:
        return SpiceLevel.medium;
    }
  }

  @override
  StateNotifierProvider<ItemProvider<ChiliSauceItem>, ItemState<ChiliSauceItem>>
  getProvider() {
    return chiliSauceItemProvider;
  }

  @override
  List<String> validate(BuildContext context, ChiliSauceItem chiliSauce) {
    final errors = <String>[];

    if (chiliSauce.name.trim().isEmpty) {
      errors.add(context.l10n.itemNameRequired('Chili Sauce'));
    } else if (chiliSauce.name.trim().length < 2) {
      errors.add(context.l10n.itemNameTooShort('Chili Sauce'));
    } else if (chiliSauce.name.trim().length > 100) {
      errors.add(context.l10n.itemNameTooLong('Chili Sauce'));
    }

    if (chiliSauce.description != null && chiliSauce.description!.length > 500) {
      errors.add(context.l10n.descriptionTooLong);
    }

    return errors;
  }
}
