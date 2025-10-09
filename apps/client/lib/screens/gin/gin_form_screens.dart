import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gin_item.dart';
import '../../models/api_response.dart';
import '../../providers/item_provider.dart';
import '../../services/item_service.dart';
import '../../forms/generic_item_form_screen.dart';

/// Screen for creating a new gin item
class GinCreateScreen extends ConsumerWidget {
  const GinCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const GenericItemFormScreen<GinItem>(
      itemType: 'gin',
      // itemId and initialItem are null for create mode
    );
  }
}

/// Screen for editing an existing gin item
class GinEditScreen extends ConsumerStatefulWidget {
  final int ginId;

  const GinEditScreen({
    super.key,
    required this.ginId,
  });

  @override
  ConsumerState<GinEditScreen> createState() => _GinEditScreenState();
}

class _GinEditScreenState extends ConsumerState<GinEditScreen> {
  GinItem? _gin;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGin();
    });
  }

  Future<void> _loadGin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First try to find the gin in the current provider state
      final ginItemState = ref.read(ginItemProvider);
      _gin = ginItemState.items
          .where((item) => item.id == widget.ginId)
          .firstOrNull;

      // If not found in cache, load from API
      if (_gin == null) {
        final service = ref.read(ginItemServiceProvider);
        final response = await service.getItemById(widget.ginId);
        
        if (response is ApiSuccess<GinItem>) {
          _gin = response.data;
        } else if (response is ApiError<GinItem>) {
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

    if (_error != null || _gin == null) {
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
                _error ?? 'Gin not found',
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

    return GenericItemFormScreen<GinItem>(
      itemType: 'gin',
      itemId: widget.ginId,
      initialItem: _gin,
    );
  }
}
