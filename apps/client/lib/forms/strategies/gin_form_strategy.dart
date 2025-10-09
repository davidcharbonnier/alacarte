import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gin_item.dart';
import '../../providers/item_provider.dart';
import '../../utils/localization_utils.dart';
import 'item_form_strategy.dart';
import 'form_field_config.dart';

/// Form strategy implementation for Gin items
class GinFormStrategy extends ItemFormStrategy<GinItem> {
  @override
  String get itemType => 'gin';

  @override
  List<FormFieldConfig> getFormFields() {
    return [
      // Name field - common to all items but with gin-specific hint
      FormFieldConfig.text(
        key: 'name',
        labelBuilder: (context) => context.l10n.name,
        hintBuilder: (context) => context.l10n.enterGinName,
        icon: Icons.label,
        required: true,
      ),

      // Profile field - gin-specific (replaces 'type' from cheese)
      // Example values: "Forestier / boréal", "Floral", "Épicé"
      FormFieldConfig.text(
        key: 'profile',
        labelBuilder: (context) => context.l10n.profileLabel,
        hintBuilder: (context) => context.l10n.enterProfile,
        helperTextBuilder: (context) => context.l10n.profileHint,
        icon: Icons.local_bar,
        required: true,
      ),

      // Origin field - common to all items
      FormFieldConfig.text(
        key: 'origin',
        labelBuilder: (context) => context.l10n.origin,
        hintBuilder: (context) => context.l10n.enterOrigin,
        icon: Icons.public,
        required: true,
      ),

      // Producer field - common to all items
      FormFieldConfig.text(
        key: 'producer',
        labelBuilder: (context) => context.l10n.producer,
        hintBuilder: (context) => context.l10n.enterProducer,
        icon: Icons.business,
        required: true,
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
    GinItem? initialItem,
  ) {
    return {
      'name': TextEditingController(text: initialItem?.name ?? ''),
      'profile': TextEditingController(text: initialItem?.profile ?? ''),
      'origin': TextEditingController(text: initialItem?.origin ?? ''),
      'producer': TextEditingController(text: initialItem?.producer ?? ''),
      'description': TextEditingController(
        text: initialItem?.description ?? '',
      ),
    };
  }

  @override
  GinItem buildItem(
    Map<String, TextEditingController> controllers,
    int? itemId,
  ) {
    return GinItem(
      id: itemId,
      name: controllers['name']!.text.trim(),
      profile: controllers['profile']!.text.trim(),
      origin: controllers['origin']!.text.trim(),
      producer: controllers['producer']!.text.trim(),
      description: controllers['description']!.text.trim().isNotEmpty
          ? controllers['description']!.text.trim()
          : null,
    );
  }

  @override
  StateNotifierProvider<ItemProvider<GinItem>, ItemState<GinItem>>
      getProvider() {
    return ginItemProvider;
  }

  @override
  List<String> validate(BuildContext context, GinItem gin) {
    final errors = <String>[];

    if (gin.name.trim().isEmpty) {
      errors.add(context.l10n.itemNameRequired('Gin'));
    } else if (gin.name.trim().length < 2) {
      errors.add(context.l10n.itemNameTooShort('Gin'));
    } else if (gin.name.trim().length > 100) {
      errors.add(context.l10n.itemNameTooLong('Gin'));
    }

    if (gin.profile.trim().isEmpty) {
      errors.add(context.l10n.profileRequired);
    }

    if (gin.origin.trim().isEmpty) {
      errors.add(context.l10n.originRequired);
    }

    if (gin.producer.trim().isEmpty) {
      errors.add(context.l10n.producerRequired);
    }

    if (gin.description != null && gin.description!.length > 500) {
      errors.add(context.l10n.descriptionTooLong);
    }

    return errors;
  }
}
