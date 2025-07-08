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

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  List<ConnectivityResult> _lastConnectivityResults = [];
  bool _isInitialized = false;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get initial connectivity status
      final connectivityResults = await _connectivity.checkConnectivity();
      _lastConnectivityResults = connectivityResults;

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (results) {
          _handleConnectivityChange(results);
        },
        onError: (error) {
          if (kDebugMode) {
            print('Connectivity monitoring error: $error');
          }
        },
      );

      _isInitialized = true;
      if (kDebugMode) {
        print(
          '✅ Connectivity service initialized with status: ${_getConnectivityDescription(connectivityResults)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize connectivity service: $e');
      }
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (kDebugMode) {
      print(
        '🌐 Connectivity changed: ${_getConnectivityDescription(_lastConnectivityResults)} -> ${_getConnectivityDescription(results)}',
      );
    }

    // Don't show notification on first initialization
    if (_lastConnectivityResults.isEmpty) {
      _lastConnectivityResults = results;
      return;
    }

    // Only show notification if status actually changed
    final wasOnline = _isOnlineFromResults(_lastConnectivityResults);
    final isOnline = _isOnlineFromResults(results);

    if (wasOnline != isOnline) {
      _showConnectivityNotification(results);
    }

    _lastConnectivityResults = results;
  }

  /// Show appropriate notification based on connectivity status
  void _showConnectivityNotification(List<ConnectivityResult> results) {
    final isOnline = _isOnlineFromResults(results);

    if (isOnline) {
      _notificationService.showOnlineNotification();
    } else {
      _notificationService.showOfflineNotification();
    }
  }

  /// Check if results indicate online status
  bool _isOnlineFromResults(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }

  /// Get connectivity description for logging
  String _getConnectivityDescription(List<ConnectivityResult> results) {
    if (results.isEmpty) return 'Unknown';
    if (results.length == 1) return results.first.toString();
    return results.map((r) => r.toString()).join(', ');
  }

  /// Check if currently online
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isOnlineFromResults(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      return false;
    }
  }

  /// Get current connectivity status
  Future<List<ConnectivityResult>> getConnectivityStatus() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting connectivity status: $e');
      }
      return [ConnectivityResult.none];
    }
  }

  /// Get primary connectivity type (for backward compatibility)
  Future<ConnectivityResult> getPrimaryConnectivityType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty) return ConnectivityResult.none;

      // Return the first non-none result, or none if all are none
      return results.firstWhere(
        (result) => result != ConnectivityResult.none,
        orElse: () => ConnectivityResult.none,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting primary connectivity type: $e');
      }
      return ConnectivityResult.none;
    }
  }

  /// Show initial connectivity status on app startup
  Future<void> showInitialStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _showConnectivityNotification(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error showing initial connectivity status: $e');
      }
    }
  }

  /// Check if connected to WiFi
  Future<bool> isWifiConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking WiFi connectivity: $e');
      }
      return false;
    }
  }

  /// Check if connected to mobile data
  Future<bool> isMobileConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking mobile connectivity: $e');
      }
      return false;
    }
  }

  /// Check if connected to ethernet
  Future<bool> isEthernetConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.ethernet);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking ethernet connectivity: $e');
      }
      return false;
    }
  }

  /// Check if connected via VPN
  Future<bool> isVpnConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.vpn);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking VPN connectivity: $e');
      }
      return false;
    }
  }

  /// Get detailed connectivity info as a map
  Future<Map<String, bool>> getDetailedConnectivityInfo() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return {
        'isOnline': _isOnlineFromResults(results),
        'hasWifi': results.contains(ConnectivityResult.wifi),
        'hasMobile': results.contains(ConnectivityResult.mobile),
        'hasEthernet': results.contains(ConnectivityResult.ethernet),
        'hasVpn': results.contains(ConnectivityResult.vpn),
        'isOffline':
            results.contains(ConnectivityResult.none) || results.isEmpty,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting detailed connectivity info: $e');
      }
      return {
        'isOnline': false,
        'hasWifi': false,
        'hasMobile': false,
        'hasEthernet': false,
        'hasVpn': false,
        'isOffline': true,
      };
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
    if (kDebugMode) {
      print('🔄 Connectivity service disposed');
    }
  }

  /// Expose the connectivity change stream (returns List<ConnectivityResult>)
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Expose a stream that emits boolean values for online/offline status
  Stream<bool> get onOnlineStatusChanged => _connectivity.onConnectivityChanged
      .map((results) => _isOnlineFromResults(results));

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get the last known connectivity results
  List<ConnectivityResult> get lastConnectivityResults =>
      List.from(_lastConnectivityResults);
}
