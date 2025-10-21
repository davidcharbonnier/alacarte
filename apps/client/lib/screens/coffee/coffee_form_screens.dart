import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/coffee_item.dart';
import '../../models/api_response.dart';
import '../../providers/item_provider.dart';
import '../../services/item_service.dart';
import '../../forms/generic_item_form_screen.dart';

/// Screen for creating a new coffee item
class CoffeeCreateScreen extends ConsumerWidget {
  const CoffeeCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const GenericItemFormScreen<CoffeeItem>(
      itemType: 'coffee',
      // itemId and initialItem are null for create mode
    );
  }
}

/// Screen for editing an existing coffee item
class CoffeeEditScreen extends ConsumerStatefulWidget {
  final int coffeeId;

  const CoffeeEditScreen({
    super.key,
    required this.coffeeId,
  });

  @override
  ConsumerState<CoffeeEditScreen> createState() => _CoffeeEditScreenState();
}

class _CoffeeEditScreenState extends ConsumerState<CoffeeEditScreen> {
  CoffeeItem? _coffee;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCoffee();
    });
  }

  Future<void> _loadCoffee() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First try to find the coffee in the current provider state
      final coffeeItemState = ref.read(coffeeItemProvider);
      _coffee = coffeeItemState.items
          .where((item) => item.id == widget.coffeeId)
          .firstOrNull;

      // If not found in cache, load from API
      if (_coffee == null) {
        final service = ref.read(coffeeItemServiceProvider);
        final response = await service.getItemById(widget.coffeeId);
        
        if (response is ApiSuccess<CoffeeItem>) {
          _coffee = response.data;
        } else if (response is ApiError<CoffeeItem>) {
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

    if (_error != null || _coffee == null) {
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
                _error ?? 'Coffee not found',
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

    return GenericItemFormScreen<CoffeeItem>(
      itemType: 'coffee',
      itemId: widget.coffeeId,
      initialItem: _coffee,
    );
  }
}
