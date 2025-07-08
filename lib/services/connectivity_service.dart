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
  ConnectivityResult _lastConnectivityResult = ConnectivityResult.none;
  bool _isInitialized = false;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get initial connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();
      _lastConnectivityResult = connectivityResult;

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (result) {
          _handleConnectivityChange(result);
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
          '✅ Connectivity service initialized with status: ${_getConnectivityDescription(connectivityResult)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize connectivity service: $e');
      }
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    if (kDebugMode) {
      print(
        '🌐 Connectivity changed: ${_getConnectivityDescription(_lastConnectivityResult)} -> ${_getConnectivityDescription(result)}',
      );
    }

    // Don't show notification on first initialization
    if (_lastConnectivityResult == ConnectivityResult.none) {
      _lastConnectivityResult = result;
      return;
    }

    // Only show notification if status actually changed
    final wasOnline = _isOnlineFromResult(_lastConnectivityResult);
    final isOnline = _isOnlineFromResult(result);

    if (wasOnline != isOnline) {
      _showConnectivityNotification(result);
    }

    _lastConnectivityResult = result;
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

  /// Check if results indicate online status
  bool _isOnlineFromResult(ConnectivityResult result) {
    return result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn;
  }

  /// Get connectivity description for logging
  String _getConnectivityDescription(ConnectivityResult result) {
    return result.toString();
  }

  /// Check if currently online
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _isOnlineFromResult(result);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      return false;
    }
  }

  /// Get current connectivity status
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting connectivity status: $e');
      }
      return ConnectivityResult.none;
    }
  }

  /// Get primary connectivity type (for backward compatibility)
  Future<ConnectivityResult> getPrimaryConnectivityType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result;
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
      final result = await _connectivity.checkConnectivity();
      _showConnectivityNotification(result);
    } catch (e) {
      if (kDebugMode) {
        print('Error showing initial connectivity status: $e');
      }
    }
  }

  /// Check if connected to WiFi
  Future<bool> isWifiConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.wifi;
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
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.mobile;
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
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.ethernet;
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
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.vpn;
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
      final result = await _connectivity.checkConnectivity();
      return {
        'isOnline': _isOnlineFromResult(result),
        'hasWifi': result == ConnectivityResult.wifi,
        'hasMobile': result == ConnectivityResult.mobile,
        'hasEthernet': result == ConnectivityResult.ethernet,
        'hasVpn': result == ConnectivityResult.vpn,
        'isOffline': result == ConnectivityResult.none,
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

  /// Expose the connectivity change stream (returns ConnectivityResult)
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Expose a stream that emits boolean values for online/offline status
  Stream<bool> get onOnlineStatusChanged => _connectivity.onConnectivityChanged
      .map((result) => _isOnlineFromResult(result));

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get the last known connectivity result
  ConnectivityResult get lastConnectivityResult => _lastConnectivityResult;
}
