import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reactive network connectivity stream (`true` = online, `false` = offline).
///
/// Emits the initial connectivity state before streaming updates from
/// [Connectivity.onConnectivityChanged]. Prepared for Thai error banners
/// and the Phase 6 Offline Sync Queue.
final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  final initialResults = await connectivity.checkConnectivity();
  yield _isConnected(initialResults);

  await for (final results in connectivity.onConnectivityChanged) {
    yield _isConnected(results);
  }
});

bool _isConnected(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}
