import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Provider for connectivity state stream
final connectivityStateProvider = StreamProvider<ConnectivityState>((ref) {
  return ApiService.connectivityStream;
});

/// Provider for simple boolean connectivity status
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStateProvider).when(
    data: (state) => state == ConnectivityState.online,
    loading: () => true, // Assume online while loading
    // ignore: avoid_types_as_parameter_names, non_constant_identifier_names
    error: (_, __) => false, // Assume offline on error
  );
});
