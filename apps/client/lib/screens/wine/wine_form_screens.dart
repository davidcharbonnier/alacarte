import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wine_item.dart';
import '../../models/api_response.dart';
import '../../providers/item_provider.dart';
import '../../services/item_service.dart';
import '../../forms/generic_item_form_screen.dart';

/// Screen for creating a new wine item
class WineCreateScreen extends ConsumerWidget {
  const WineCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const GenericItemFormScreen<WineItem>(
      itemType: 'wine',
      // itemId and initialItem are null for create mode
    );
  }
}

/// Screen for editing an existing wine item
class WineEditScreen extends ConsumerStatefulWidget {
  final int wineId;

  const WineEditScreen({
    super.key,
    required this.wineId,
  });

  @override
  ConsumerState<WineEditScreen> createState() => _WineEditScreenState();
}

class _WineEditScreenState extends ConsumerState<WineEditScreen> {
  WineItem? _wine;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWine();
    });
  }

  Future<void> _loadWine() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First try to find the wine in the current provider state
      final wineItemState = ref.read(wineItemProvider);
      _wine = wineItemState.items
          .where((item) => item.id == widget.wineId)
          .firstOrNull;

      // If not found in cache, load from API
      if (_wine == null) {
        final service = ref.read(wineItemServiceProvider);
        final response = await service.getItemById(widget.wineId);
        
        if (response is ApiSuccess<WineItem>) {
          _wine = response.data;
        } else if (response is ApiError<WineItem>) {
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

    if (_error != null || _wine == null) {
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
                _error ?? 'Wine not found',
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

    return GenericItemFormScreen<WineItem>(
      itemType: 'wine',
      itemId: widget.wineId,
      initialItem: _wine,
    );
  }
}
