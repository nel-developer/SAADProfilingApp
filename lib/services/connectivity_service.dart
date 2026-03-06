import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  /// Get current connectivity status
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      // If check fails, assume online (optimistic) to prevent blocking login
      return true;
    }
  }

  /// Stream of connectivity changes
  Stream<ConnectivityResult> getConnectivityStream() {
    return _connectivity.onConnectivityChanged;
  }

  /// Check if device went from offline to online
  Future<bool> wasOfflineNowOnline(ConnectivityResult result) async {
    return result != ConnectivityResult.none;
  }
}
