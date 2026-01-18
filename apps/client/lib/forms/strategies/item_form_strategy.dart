import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../models/rateable_item.dart';
import '../../providers/item_provider.dart';
import 'form_field_config.dart';

/// Abstract strategy interface for item-specific form logic
///
/// Each item type (cheese, gin, wine, etc.) implements this strategy
/// to provide its specific form configuration and business logic.
abstract class ItemFormStrategy<T extends RateableItem> {
  /// Item type identifier (e.g., 'cheese', 'gin')
  String get itemType;

  /// Get ordered list of form field configurations
  ///
  /// The form will render fields in the order specified here.
  /// Each field configuration includes localization functions.
  List<FormFieldConfig> getFormFields();

  /// Initialize text controllers with optional initial data
  ///
  /// Returns a map where keys match the field keys from getFormFields().
  /// Controllers should be initialized with existing item data when editing.
  Map<String, TextEditingController> initializeControllers(T? initialItem);

  /// Build an item instance from controller values
  ///
  /// Takes the controller map and optional itemId (for updates)
  /// and constructs a complete item instance.
  T buildItem(Map<String, TextEditingController> controllers, int? itemId);

  /// Get the Riverpod provider for this item type
  ///
  /// Returns the appropriate StateNotifierProvider for CRUD operations.
  StateNotifierProvider<ItemProvider<T>, ItemState<T>> getProvider();

  /// Validate item data and return localized error messages
  ///
  /// Takes a BuildContext for localization and the item to validate.
  /// Returns a list of error messages (empty if valid).
  List<String> validate(BuildContext context, T item);

  /// Dispose all controllers
  ///
  /// Called when the form is disposed to clean up resources.
  void disposeControllers(Map<String, TextEditingController> controllers) {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }
}
