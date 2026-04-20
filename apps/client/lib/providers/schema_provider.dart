import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/api_response.dart';
import '../models/item_schema.dart';
import '../services/schema_service.dart';

class SchemaState {
  final List<ItemSchema> schemas;
  final Map<String, ItemSchema> schemasByType;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefresh;

  const SchemaState({
    this.schemas = const [],
    this.schemasByType = const {},
    this.isLoading = false,
    this.error,
    this.lastRefresh,
  });

  SchemaState copyWith({
    List<ItemSchema>? schemas,
    Map<String, ItemSchema>? schemasByType,
    bool? isLoading,
    String? error,
    DateTime? lastRefresh,
  }) {
    return SchemaState(
      schemas: schemas ?? this.schemas,
      schemasByType: schemasByType ?? this.schemasByType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }

  ItemSchema? getSchema(String type) => schemasByType[type];

  bool get hasSchemas => schemas.isNotEmpty;
}

class SchemaNotifier extends StateNotifier<SchemaState> {
  final SchemaService _schemaService;

  SchemaNotifier(this._schemaService) : super(const SchemaState());

  Future<void> loadSchemas({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    final response = await _schemaService.fetchSchemas(
      forceRefresh: forceRefresh,
    );

    response.when(
      success: (schemas, _) {
        final schemasByType = {for (var s in schemas) s.name: s};
        state = state.copyWith(
          schemas: schemas,
          schemasByType: schemasByType,
          isLoading: false,
          lastRefresh: DateTime.now(),
        );
      },
      error: (message, statusCode, errorCode, details) {
        state = state.copyWith(isLoading: false, error: message);
      },
      loading: () {},
    );
  }

  Future<void> refreshSchemas() async {
    await loadSchemas(forceRefresh: true);
  }

  Future<void> refreshSchema(String type) async {
    final response = await _schemaService.refreshSchema(type);

    response.when(
      success: (schema, _) {
        final updatedSchemas = [...state.schemas];
        final index = updatedSchemas.indexWhere((s) => s.name == type);
        if (index >= 0) {
          updatedSchemas[index] = schema;
        } else {
          updatedSchemas.add(schema);
        }
        final schemasByType = {for (var s in updatedSchemas) s.name: s};
        state = state.copyWith(
          schemas: updatedSchemas,
          schemasByType: schemasByType,
          lastRefresh: DateTime.now(),
        );
      },
      error: (message, statusCode, errorCode, details) {},
      loading: () {},
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final schemaServiceProvider = Provider<SchemaService>((ref) {
  return SchemaService();
});

final schemaProvider = StateNotifierProvider<SchemaNotifier, SchemaState>((
  ref,
) {
  final schemaService = ref.watch(schemaServiceProvider);
  return SchemaNotifier(schemaService);
});

final schemaForTypeProvider = Provider.family<ItemSchema?, String>((ref, type) {
  final schemaState = ref.watch(schemaProvider);
  return schemaState.getSchema(type);
});
