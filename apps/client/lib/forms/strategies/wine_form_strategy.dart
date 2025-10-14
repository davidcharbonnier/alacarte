import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wine_item.dart';
import '../../providers/item_provider.dart';
import '../../utils/localization_utils.dart';
import 'item_form_strategy.dart';
import 'form_field_config.dart';

/// Form strategy implementation for Wine items
class WineFormStrategy extends ItemFormStrategy<WineItem> {
  @override
  String get itemType => 'wine';

  @override
  List<FormFieldConfig> getFormFields() {
    return [
      // Name field - required
      FormFieldConfig.text(
        key: 'name',
        labelBuilder: (context) => context.l10n.name,
        hintBuilder: (context) => context.l10n.enterWineName,
        icon: Icons.label,
        required: true,
      ),

      // Color field - required (Rouge, Blanc, Rosé, Mousseux, Orange)
      FormFieldConfig.text(
        key: 'color',
        labelBuilder: (context) => context.l10n.colorLabel,
        hintBuilder: (context) => context.l10n.enterColor,
        helperTextBuilder: (context) => context.l10n.colorHint,
        icon: Icons.palette,
        required: true,
      ),

      // Country field - required
      FormFieldConfig.text(
        key: 'country',
        labelBuilder: (context) => context.l10n.country,
        hintBuilder: (context) => context.l10n.enterCountry,
        icon: Icons.public,
        required: true,
      ),

      // Producer field - optional
      FormFieldConfig.text(
        key: 'producer',
        labelBuilder: (context) => context.l10n.producer,
        hintBuilder: (context) => context.l10n.enterProducer,
        icon: Icons.business,
      ),

      // Region field - optional
      FormFieldConfig.text(
        key: 'region',
        labelBuilder: (context) => context.l10n.region,
        hintBuilder: (context) => context.l10n.enterRegion,
        icon: Icons.location_on,
      ),

      // Grape varieties field - optional
      FormFieldConfig.text(
        key: 'grape',
        labelBuilder: (context) => context.l10n.grapeLabel,
        hintBuilder: (context) => context.l10n.enterGrape,
        helperTextBuilder: (context) => context.l10n.grapeHint,
        icon: Icons.nature,
      ),

      // Designation field - optional
      FormFieldConfig.text(
        key: 'designation',
        labelBuilder: (context) => context.l10n.designationLabel,
        hintBuilder: (context) => context.l10n.enterDesignation,
        helperTextBuilder: (context) => context.l10n.designationHint,
        icon: Icons.verified,
      ),

      // Alcohol field - optional
      FormFieldConfig.text(
        key: 'alcohol',
        labelBuilder: (context) => context.l10n.alcoholLabel,
        hintBuilder: (context) => context.l10n.enterAlcohol,
        icon: Icons.percent,
      ),

      // Sugar field - optional
      FormFieldConfig.text(
        key: 'sugar',
        labelBuilder: (context) => context.l10n.sugarLabel,
        hintBuilder: (context) => context.l10n.enterSugar,
        icon: Icons.bubble_chart,
      ),

      // Organic field - optional (text field instead of checkbox)
      FormFieldConfig.text(
        key: 'organic',
        labelBuilder: (context) => context.l10n.organicLabel,
        hintBuilder: (context) => 'true/false',
        icon: Icons.eco,
      ),

      // Description field - optional
      FormFieldConfig.multiline(
        key: 'description',
        labelBuilder: (context) => context.l10n.description,
        hintBuilder: (context) => context.l10n.enterDescription,
        helperTextBuilder: (context) => context.l10n.optionalFieldHelper(1000),
        maxLines: 3,
        maxLength: 1000,
      ),
    ];
  }

  @override
  Map<String, TextEditingController> initializeControllers(
    WineItem? initialItem,
  ) {
    return {
      'name': TextEditingController(text: initialItem?.name ?? ''),
      'color': TextEditingController(text: initialItem?.color ?? ''),
      'country': TextEditingController(text: initialItem?.country ?? ''),
      'producer': TextEditingController(text: initialItem?.producer ?? ''),
      'region': TextEditingController(text: initialItem?.region ?? ''),
      'grape': TextEditingController(text: initialItem?.grape ?? ''),
      'designation': TextEditingController(text: initialItem?.designation ?? ''),
      'alcohol': TextEditingController(
        text: initialItem?.alcohol != null && initialItem!.alcohol > 0
            ? initialItem.alcohol.toString()
            : '',
      ),
      'sugar': TextEditingController(
        text: initialItem?.sugar != null && initialItem!.sugar > 0
            ? initialItem.sugar.toString()
            : '',
      ),
      'organic': TextEditingController(
        text: initialItem?.organic == true ? 'true' : 'false',
      ),
      'description': TextEditingController(
        text: initialItem?.description ?? '',
      ),
    };
  }

  @override
  WineItem buildItem(
    Map<String, TextEditingController> controllers,
    int? itemId,
  ) {
    return WineItem(
      id: itemId,
      name: controllers['name']!.text.trim(),
      color: controllers['color']!.text.trim(),
      country: controllers['country']!.text.trim(),
      producer: controllers['producer']!.text.trim(),
      region: controllers['region']!.text.trim(),
      grape: controllers['grape']!.text.trim(),
      designation: controllers['designation']!.text.trim(),
      alcohol: double.tryParse(controllers['alcohol']!.text.trim()) ?? 0.0,
      sugar: double.tryParse(controllers['sugar']!.text.trim()) ?? 0.0,
      organic: controllers['organic']!.text.trim() == 'true',
      description: controllers['description']!.text.trim(),
    );
  }

  @override
  StateNotifierProvider<ItemProvider<WineItem>, ItemState<WineItem>>
      getProvider() {
    return wineItemProvider;
  }

  @override
  List<String> validate(BuildContext context, WineItem wine) {
    final errors = <String>[];

    if (wine.name.trim().isEmpty) {
      errors.add(context.l10n.itemNameRequired('Wine'));
    } else if (wine.name.trim().length < 2) {
      errors.add(context.l10n.itemNameTooShort('Wine'));
    } else if (wine.name.trim().length > 200) {
      errors.add(context.l10n.itemNameTooLong('Wine'));
    }

    if (wine.color.trim().isEmpty) {
      errors.add(context.l10n.colorRequired);
    }

    if (wine.country.trim().isEmpty) {
      errors.add(context.l10n.countryRequired);
    }

    if (wine.description.isNotEmpty && wine.description.length > 1000) {
      errors.add(context.l10n.descriptionTooLong);
    }

    return errors;
  }
}
