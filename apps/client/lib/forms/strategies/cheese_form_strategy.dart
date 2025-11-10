import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../models/cheese_item.dart';
import '../../providers/item_provider.dart';
import '../../utils/localization_utils.dart';
import 'item_form_strategy.dart';
import 'form_field_config.dart';

/// Form strategy implementation for Cheese items
class CheeseFormStrategy extends ItemFormStrategy<CheeseItem> {
  @override
  String get itemType => 'cheese';

  @override
  List<FormFieldConfig> getFormFields() {
    return [
      // Name field - common to all items but with cheese-specific hint
      FormFieldConfig.text(
        key: 'name',
        labelBuilder: (context) => context.l10n.name,
        hintBuilder: (context) => context.l10n.enterItemName('cheese'),
        icon: Icons.label,
        required: true,
      ),

      // Type field - cheese-specific (e.g., "Hard", "Soft", "Blue")
      FormFieldConfig.text(
        key: 'type',
        labelBuilder: (context) => context.l10n.type,
        hintBuilder: (context) => context.l10n.cheeseTypeHint,
        icon: Icons.category,
        required: true,
      ),

      // Origin field - optional for cheese
      FormFieldConfig.text(
        key: 'origin',
        labelBuilder: (context) => context.l10n.origin,
        hintBuilder: (context) => context.l10n.enterOrigin,
        icon: Icons.public,
        required: false,
      ),

      // Producer field - optional for cheese
      FormFieldConfig.text(
        key: 'producer',
        labelBuilder: (context) => context.l10n.producer,
        hintBuilder: (context) => context.l10n.enterProducer,
        icon: Icons.business,
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
    CheeseItem? initialItem,
  ) {
    return {
      'name': TextEditingController(text: initialItem?.name ?? ''),
      'type': TextEditingController(text: initialItem?.type ?? ''),
      'origin': TextEditingController(text: initialItem?.origin ?? ''),
      'producer': TextEditingController(text: initialItem?.producer ?? ''),
      'description': TextEditingController(
        text: initialItem?.description ?? '',
      ),
    };
  }

  @override
  CheeseItem buildItem(
    Map<String, TextEditingController> controllers,
    int? itemId,
  ) {
    return CheeseItem(
      id: itemId,
      name: controllers['name']!.text.trim(),
      type: controllers['type']!.text.trim(),
      origin: controllers['origin']!.text.trim().isNotEmpty
          ? controllers['origin']!.text.trim()
          : null,
      producer: controllers['producer']!.text.trim().isNotEmpty
          ? controllers['producer']!.text.trim()
          : null,
      description: controllers['description']!.text.trim().isNotEmpty
          ? controllers['description']!.text.trim()
          : null,
    );
  }

  @override
  StateNotifierProvider<ItemProvider<CheeseItem>, ItemState<CheeseItem>>
      getProvider() {
    return cheeseItemProvider;
  }

  @override
  List<String> validate(BuildContext context, CheeseItem cheese) {
    final errors = <String>[];

    if (cheese.name.trim().isEmpty) {
      errors.add(context.l10n.itemNameRequired('Cheese'));
    } else if (cheese.name.trim().length < 2) {
      errors.add(context.l10n.itemNameTooShort('Cheese'));
    } else if (cheese.name.trim().length > 100) {
      errors.add(context.l10n.itemNameTooLong('Cheese'));
    }

    if (cheese.type.trim().isEmpty) {
      errors.add(context.l10n.typeRequired);
    }

    if (cheese.description != null && cheese.description!.length > 500) {
      errors.add(context.l10n.descriptionTooLong);
    }

    return errors;
  }
}
