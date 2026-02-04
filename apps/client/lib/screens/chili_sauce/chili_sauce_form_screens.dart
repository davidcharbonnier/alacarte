import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chili_sauce_item.dart';
import '../../models/api_response.dart';
import '../../providers/item_provider.dart';
import '../../services/item_service.dart';
import '../../forms/generic_item_form_screen.dart';
import '../../utils/localization_utils.dart';

/// Screen for creating a new chili sauce
class ChiliSauceCreateScreen extends ConsumerWidget {
  const ChiliSauceCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const GenericItemFormScreen<ChiliSauceItem>(
      itemType: 'chili-sauce',
      // itemId and initialItem are null for create mode
    );
  }
}

/// Screen for editing an existing chili sauce
class ChiliSauceEditScreen extends ConsumerStatefulWidget {
  final int chiliSauceId;

  const ChiliSauceEditScreen({
    super.key,
    required this.chiliSauceId,
  });

  @override
  ConsumerState<ChiliSauceEditScreen> createState() => _ChiliSauceEditScreenState();
}

class _ChiliSauceEditScreenState extends ConsumerState<ChiliSauceEditScreen> {
  ChiliSauceItem? _chiliSauce;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChiliSauce();
    });
  }

  Future<void> _loadChiliSauce() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First try to find the chili sauce in the current provider state
      final chiliSauceItemState = ref.read(chiliSauceItemProvider);
      _chiliSauce = chiliSauceItemState.items
          .where((item) => item.id == widget.chiliSauceId)
          .firstOrNull;

      // If not found in cache, load from API
      if (_chiliSauce == null) {
        final service = ref.read(chiliSauceItemServiceProvider);
        final response = await service.getItemById(widget.chiliSauceId);
        
        if (response is ApiSuccess<ChiliSauceItem>) {
          _chiliSauce = response.data;
        } else if (response is ApiError<ChiliSauceItem>) {
          _error = response.message;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.loading),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _chiliSauce == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.error),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? context.l10n.itemNotFound,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.goBack),
              ),
            ],
          ),
        ),
      );
    }

    return GenericItemFormScreen<ChiliSauceItem>(
      itemType: 'chili-sauce',
      itemId: widget.chiliSauceId,
      initialItem: _chiliSauce,
    );
  }
}