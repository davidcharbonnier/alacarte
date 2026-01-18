import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../models/coffee_item.dart';
import '../../providers/item_provider.dart';
import '../../utils/localization_utils.dart';
import 'item_form_strategy.dart';
import 'form_field_config.dart';

/// Form strategy implementation for Coffee items
class CoffeeFormStrategy extends ItemFormStrategy<CoffeeItem> {
  @override
  String get itemType => 'coffee';

  @override
  List<FormFieldConfig> getFormFields() {
    return [
      // Name field - required
      FormFieldConfig.text(
        key: 'name',
        labelBuilder: (context) => context.l10n.name,
        hintBuilder: (context) => context.l10n.enterCoffeeName,
        icon: Icons.label,
        required: true,
      ),

      // Roaster field - required
      FormFieldConfig.text(
        key: 'roaster',
        labelBuilder: (context) => context.l10n.roasterLabel,
        hintBuilder: (context) => context.l10n.enterRoaster,
        icon: Icons.local_cafe,
        required: true,
      ),

      // Country field - optional
      FormFieldConfig.text(
        key: 'country',
        labelBuilder: (context) => context.l10n.countryLabel,
        hintBuilder: (context) => context.l10n.enterCountry,
        icon: Icons.public,
        required: false,
      ),

      // Region field - optional
      FormFieldConfig.text(
        key: 'region',
        labelBuilder: (context) => context.l10n.regionLabel,
        hintBuilder: (context) => context.l10n.enterRegion,
        icon: Icons.location_on,
        required: false,
      ),

      // Farm field - optional
      FormFieldConfig.text(
        key: 'farm',
        labelBuilder: (context) => context.l10n.farmLabel,
        hintBuilder: (context) => context.l10n.enterFarm,
        icon: Icons.agriculture,
        required: false,
      ),

      // Altitude field - optional
      FormFieldConfig.text(
        key: 'altitude',
        labelBuilder: (context) => context.l10n.altitudeLabel,
        hintBuilder: (context) => context.l10n.enterAltitude,
        helperTextBuilder: (context) => context.l10n.altitudeHelper,
        icon: Icons.terrain,
        required: false,
      ),

      // Species dropdown - optional
      FormFieldConfig.dropdown(
        key: 'species',
        labelBuilder: (context) => context.l10n.speciesLabel,
        hintBuilder: (context) => context.l10n.selectSpecies,
        options: [
          DropdownOption(
            value: '',
            labelBuilder: (context) => context.l10n.notSpecified,
          ),
          DropdownOption(value: 'Arabica', labelBuilder: (_) => 'Arabica'),
          DropdownOption(value: 'Robusta', labelBuilder: (_) => 'Robusta'),
          DropdownOption(value: 'Libérica', labelBuilder: (_) => 'Libérica'),
          DropdownOption(value: 'Excelsa', labelBuilder: (_) => 'Excelsa'),
        ],
        icon: Icons.eco,
        required: false,
      ),

      // Variety field - optional
      FormFieldConfig.text(
        key: 'variety',
        labelBuilder: (context) => context.l10n.varietyLabel,
        hintBuilder: (context) => context.l10n.enterVariety,
        helperTextBuilder: (context) => context.l10n.varietyHelper,
        icon: Icons.category,
        required: false,
      ),

      // Processing Method dropdown - optional
      FormFieldConfig.dropdown(
        key: 'processing_method',
        labelBuilder: (context) => context.l10n.processingMethodLabel,
        hintBuilder: (context) => context.l10n.selectProcessingMethod,
        options: [
          DropdownOption(
            value: '',
            labelBuilder: (context) => context.l10n.notSpecified,
          ),
          DropdownOption(
            value: 'Lavé',
            labelBuilder: (context) => context.l10n.processWashed,
          ),
          DropdownOption(
            value: 'Nature',
            labelBuilder: (context) => context.l10n.processNatural,
          ),
          DropdownOption(value: 'Honey', labelBuilder: (_) => 'Honey'),
          DropdownOption(
            value: 'Anaérobie',
            labelBuilder: (context) => context.l10n.processAnaerobic,
          ),
          DropdownOption(
            value: 'Macération Carbonique',
            labelBuilder: (context) => context.l10n.processCarbonicMaceration,
          ),
          DropdownOption(
            value: 'Décortiqué Humide',
            labelBuilder: (context) => context.l10n.processWetHulled,
          ),
          DropdownOption(
            value: 'Nature Dépulpé',
            labelBuilder: (context) => context.l10n.processPulpedNatural,
          ),
        ],
        icon: Icons.settings,
        required: false,
      ),

      // Decaffeinated checkbox
      FormFieldConfig.checkbox(
        key: 'decaffeinated',
        labelBuilder: (context) => context.l10n.decaffeinatedLabel,
        helperTextBuilder: (context) => context.l10n.decaffeinatedHelper,
      ),

      // Roast Level dropdown - optional
      FormFieldConfig.dropdown(
        key: 'roast_level',
        labelBuilder: (context) => context.l10n.roastLevelLabel,
        hintBuilder: (context) => context.l10n.selectRoastLevel,
        options: [
          DropdownOption(
            value: '',
            labelBuilder: (context) => context.l10n.notSpecified,
          ),
          DropdownOption(
            value: 'Pâle',
            labelBuilder: (context) => context.l10n.roastLight,
          ),
          DropdownOption(
            value: 'Moyen',
            labelBuilder: (context) => context.l10n.roastMedium,
          ),
          DropdownOption(
            value: 'Foncé',
            labelBuilder: (context) => context.l10n.roastDark,
          ),
        ],
        icon: Icons.whatshot,
        required: false,
      ),

      // Tasting Notes field - optional
      FormFieldConfig.text(
        key: 'tasting_notes',
        labelBuilder: (context) => context.l10n.tastingNotesLabel,
        hintBuilder: (context) => context.l10n.enterTastingNotes,
        helperTextBuilder: (context) => context.l10n.tastingNotesHelper,
        icon: Icons.local_bar,
        required: false,
      ),

      // Acidity dropdown - optional
      FormFieldConfig.dropdown(
        key: 'acidity',
        labelBuilder: (context) => context.l10n.acidityLabel,
        hintBuilder: (context) => context.l10n.selectAcidity,
        options: [
          DropdownOption(
            value: '',
            labelBuilder: (context) => context.l10n.notSpecified,
          ),
          DropdownOption(
            value: 'Faible',
            labelBuilder: (context) => context.l10n.intensityLow,
          ),
          DropdownOption(
            value: 'Moyen',
            labelBuilder: (context) => context.l10n.intensityMedium,
          ),
          DropdownOption(
            value: 'Élevé',
            labelBuilder: (context) => context.l10n.intensityHigh,
          ),
        ],
        icon: Icons.water_drop,
        required: false,
      ),

      // Body dropdown - optional
      FormFieldConfig.dropdown(
        key: 'body',
        labelBuilder: (context) => context.l10n.bodyLabel,
        hintBuilder: (context) => context.l10n.selectBody,
        options: [
          DropdownOption(
            value: '',
            labelBuilder: (context) => context.l10n.notSpecified,
          ),
          DropdownOption(
            value: 'Faible',
            labelBuilder: (context) => context.l10n.bodyLight,
          ),
          DropdownOption(
            value: 'Moyen',
            labelBuilder: (context) => context.l10n.bodyMedium,
          ),
          DropdownOption(
            value: 'Élevé',
            labelBuilder: (context) => context.l10n.bodyFull,
          ),
        ],
        icon: Icons.fitness_center,
        required: false,
      ),

      // Sweetness dropdown - optional
      FormFieldConfig.dropdown(
        key: 'sweetness',
        labelBuilder: (context) => context.l10n.sweetnessLabel,
        hintBuilder: (context) => context.l10n.selectSweetness,
        options: [
          DropdownOption(
            value: '',
            labelBuilder: (context) => context.l10n.notSpecified,
          ),
          DropdownOption(
            value: 'Faible',
            labelBuilder: (context) => context.l10n.intensityLow,
          ),
          DropdownOption(
            value: 'Moyen',
            labelBuilder: (context) => context.l10n.intensityMedium,
          ),
          DropdownOption(
            value: 'Élevé',
            labelBuilder: (context) => context.l10n.intensityHigh,
          ),
        ],
        icon: Icons.cake,
        required: false,
      ),

      // Organic checkbox
      FormFieldConfig.checkbox(
        key: 'organic',
        labelBuilder: (context) => context.l10n.organicLabel,
        helperTextBuilder: (context) => context.l10n.organicHelper,
      ),

      // Fair Trade checkbox
      FormFieldConfig.checkbox(
        key: 'fair_trade',
        labelBuilder: (context) => context.l10n.fairTradeLabel,
        helperTextBuilder: (context) => context.l10n.fairTradeHelper,
      ),

      // Description field - optional
      FormFieldConfig.multiline(
        key: 'description',
        labelBuilder: (context) => context.l10n.description,
        hintBuilder: (context) => context.l10n.enterDescription,
        helperTextBuilder: (context) => context.l10n.optionalFieldHelper(1000),
        maxLines: 4,
        maxLength: 1000,
      ),
    ];
  }

  @override
  Map<String, TextEditingController> initializeControllers(
    CoffeeItem? initialItem,
  ) {
    return {
      'name': TextEditingController(text: initialItem?.name ?? ''),
      'roaster': TextEditingController(text: initialItem?.roaster ?? ''),
      'country': TextEditingController(text: initialItem?.country ?? ''),
      'region': TextEditingController(text: initialItem?.region ?? ''),
      'farm': TextEditingController(text: initialItem?.farm ?? ''),
      'altitude': TextEditingController(text: initialItem?.altitude ?? ''),
      'species': TextEditingController(text: initialItem?.species ?? ''),
      'variety': TextEditingController(text: initialItem?.variety ?? ''),
      'processing_method': TextEditingController(
        text: initialItem?.processingMethod ?? '',
      ),
      'decaffeinated': TextEditingController(
        text: initialItem?.decaffeinated == true ? 'true' : 'false',
      ),
      'roast_level': TextEditingController(text: initialItem?.roastLevel ?? ''),
      'tasting_notes': TextEditingController(
        text: initialItem?.tastingNotes?.join(', ') ?? '',
      ),
      'acidity': TextEditingController(text: initialItem?.acidity ?? ''),
      'body': TextEditingController(text: initialItem?.body ?? ''),
      'sweetness': TextEditingController(text: initialItem?.sweetness ?? ''),
      'organic': TextEditingController(
        text: initialItem?.organic == true ? 'true' : 'false',
      ),
      'fair_trade': TextEditingController(
        text: initialItem?.fairTrade == true ? 'true' : 'false',
      ),
      'description': TextEditingController(
        text: initialItem?.description ?? '',
      ),
    };
  }

  @override
  CoffeeItem buildItem(
    Map<String, TextEditingController> controllers,
    int? itemId,
  ) {
    // Parse tasting notes (comma-separated string to list)
    List<String>? tastingNotesList;
    final tastingNotesText = controllers['tasting_notes']!.text.trim();
    if (tastingNotesText.isNotEmpty) {
      tastingNotesList = tastingNotesText
          .split(',')
          .map((note) => note.trim())
          .where((note) => note.isNotEmpty)
          .toList();
    }

    return CoffeeItem(
      id: itemId,
      name: controllers['name']!.text.trim(),
      roaster: controllers['roaster']!.text.trim(),
      country: controllers['country']!.text.trim().isNotEmpty
          ? controllers['country']!.text.trim()
          : null,
      region: controllers['region']!.text.trim().isNotEmpty
          ? controllers['region']!.text.trim()
          : null,
      farm: controllers['farm']!.text.trim().isNotEmpty
          ? controllers['farm']!.text.trim()
          : null,
      altitude: controllers['altitude']!.text.trim().isNotEmpty
          ? controllers['altitude']!.text.trim()
          : null,
      species: controllers['species']!.text.trim().isNotEmpty
          ? controllers['species']!.text.trim()
          : null,
      variety: controllers['variety']!.text.trim().isNotEmpty
          ? controllers['variety']!.text.trim()
          : null,
      processingMethod: controllers['processing_method']!.text.trim().isNotEmpty
          ? controllers['processing_method']!.text.trim()
          : null,
      decaffeinated: controllers['decaffeinated']!.text == 'true',
      roastLevel: controllers['roast_level']!.text.trim().isNotEmpty
          ? controllers['roast_level']!.text.trim()
          : null,
      tastingNotes: tastingNotesList,
      acidity: controllers['acidity']!.text.trim().isNotEmpty
          ? controllers['acidity']!.text.trim()
          : null,
      body: controllers['body']!.text.trim().isNotEmpty
          ? controllers['body']!.text.trim()
          : null,
      sweetness: controllers['sweetness']!.text.trim().isNotEmpty
          ? controllers['sweetness']!.text.trim()
          : null,
      organic: controllers['organic']!.text == 'true',
      fairTrade: controllers['fair_trade']!.text == 'true',
      description: controllers['description']!.text.trim().isNotEmpty
          ? controllers['description']!.text.trim()
          : null,
    );
  }

  @override
  StateNotifierProvider<ItemProvider<CoffeeItem>, ItemState<CoffeeItem>>
  getProvider() {
    return coffeeItemProvider;
  }

  @override
  List<String> validate(BuildContext context, CoffeeItem coffee) {
    final errors = <String>[];

    if (coffee.name.trim().isEmpty) {
      errors.add(context.l10n.itemNameRequired('Coffee'));
    } else if (coffee.name.trim().length < 2) {
      errors.add(context.l10n.itemNameTooShort('Coffee'));
    } else if (coffee.name.trim().length > 200) {
      errors.add(context.l10n.itemNameTooLong('Coffee'));
    }

    if (coffee.roaster.trim().isEmpty) {
      errors.add(context.l10n.roasterRequired);
    }

    if (coffee.description != null && coffee.description!.length > 1000) {
      errors.add(context.l10n.descriptionTooLong);
    }

    return errors;
  }
}
