import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cheese_item.dart';
import '../../models/api_response.dart';
import '../../providers/item_provider.dart';
import '../../services/item_service.dart';
import '../../forms/generic_item_form_screen.dart';

/// Screen for creating a new cheese item
class CheeseCreateScreen extends ConsumerWidget {
  const CheeseCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const GenericItemFormScreen<CheeseItem>(
      itemType: 'cheese',
      // itemId and initialItem are null for create mode
    );
  }
}

/// Screen for editing an existing cheese item
class CheeseEditScreen extends ConsumerStatefulWidget {
  final int cheeseId;

  const CheeseEditScreen({
    super.key,
    required this.cheeseId,
  });

  @override
  ConsumerState<CheeseEditScreen> createState() => _CheeseEditScreenState();
}

class _CheeseEditScreenState extends ConsumerState<CheeseEditScreen> {
  CheeseItem? _cheese;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCheese();
    });
  }

  Future<void> _loadCheese() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First try to find the cheese in the current provider state
      final cheeseItemState = ref.read(cheeseItemProvider);
      _cheese = cheeseItemState.items
          .where((item) => item.id == widget.cheeseId)
          .firstOrNull;

      // If not found in cache, load from API
      if (_cheese == null) {
        final service = ref.read(cheeseItemServiceProvider);
        final response = await service.getItemById(widget.cheeseId);
        
        if (response is ApiSuccess<CheeseItem>) {
          _cheese = response.data;
        } else if (response is ApiError<CheeseItem>) {
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
          title: const Text('Loading...'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _cheese == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
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
                _error ?? 'Cheese not found',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return GenericItemFormScreen<CheeseItem>(
      itemType: 'cheese',
      itemId: widget.cheeseId,
      initialItem: _cheese,
    );
  }
}
