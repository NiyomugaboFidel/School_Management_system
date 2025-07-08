import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  ConnectivityResult? _lastConnectivityResult;
  bool _isInitialized = false;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get initial connectivity status
      _lastConnectivityResult = await _connectivity.checkConnectivity();

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
        onError: (error) {
          print('Connectivity monitoring error: $error');
        },
      );

      _isInitialized = true;
      print('✅ Connectivity service initialized');
    } catch (e) {
      print('❌ Failed to initialize connectivity service: $e');
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    print('🌐 Connectivity changed: \\${_lastConnectivityResult} -> $result');

    // Don't show notification on first initialization
    if (_lastConnectivityResult == null) {
      _lastConnectivityResult = result;
      return;
    }

    // Only show notification if status actually changed
    if (_lastConnectivityResult != result) {
      _showConnectivityNotification(result);
      _lastConnectivityResult = result;
    }
  }

  /// Show appropriate notification based on connectivity status
  void _showConnectivityNotification(ConnectivityResult result) {
    final isOnline = _isOnlineFromResult(result);

    if (isOnline) {
      _notificationService.showOnlineNotification();
    } else {
      _notificationService.showOfflineNotification();
    }
  }

  /// Check if result indicates online status
  bool _isOnlineFromResult(ConnectivityResult result) {
    return result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet;
  }

  /// Check if currently online
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isOnlineFromResult(result);
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  /// Get current connectivity status
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      print('Error getting connectivity status: $e');
      return ConnectivityResult.none;
    }
  }

  /// Show initial connectivity status on app startup
  Future<void> showInitialStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _showConnectivityNotification(result);
    } catch (e) {
      print('Error showing initial connectivity status: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
  }

  /// Expose the connectivity change stream
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
