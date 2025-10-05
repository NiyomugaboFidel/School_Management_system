import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite_crud_app/permission_service.dart';
import 'package:sqlite_crud_app/services/notification_service.dart';
import 'package:sqlite_crud_app/SQLite/database_helper.dart';
import 'package:sqlite_crud_app/services/connectivity_service.dart';
import 'package:sqlite_crud_app/services/enhanced_sync_service.dart';

class SplashDecider extends StatefulWidget {
  const SplashDecider({Key? key}) : super(key: key);

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  bool _isInitializing = true;
  String _status = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize connectivity service and show status
      setState(() => _status = 'Checking connectivity...');
      await _initializeConnectivity();

      // Step 2: Initialize sync service (offline-first)
      setState(() => _status = 'Initializing sync service...');
      await _initializeSyncService();

      // Step 3: Initialize notifications (non-blocking)
      setState(() => _status = 'Setting up notifications...');
      _initializeNotifications();

      // Step 4: Request permissions (Android only)
      if (!kIsWeb) {
        setState(() => _status = 'Requesting permissions...');
        await _requestPermissions();
      }

      // Step 5: Initialize database (non-blocking)
      setState(() => _status = 'Preparing database...');
      _initializeDatabase();

      // Step 6: Check login state
      setState(() => _status = 'Checking login status...');
      await _checkLoginState();
    } catch (e) {
      print('Error during app initialization: $e');
      setState(() {
        _hasError = true;
        _status = 'Error: $e';
      });

      // Even if there's an error, try to proceed to login
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _initializeSyncService() async {
    try {
      print('🔄 Initializing enhanced sync service...');
      await EnhancedSyncService.instance.initialize();
      print('✅ Enhanced sync service initialized successfully');
    } catch (e) {
      print('❌ Sync service initialization failed: $e');
      // Continue without sync service - app works offline
    }
  }

  void _initializeNotifications() {
    try {
      print('🔔 Initializing notifications...');
      NotificationService()
          .initialize()
          .then((_) {
            print('✅ Notifications initialized successfully');
          })
          .catchError((e) {
            print('❌ Notification service initialization failed: $e');
            // Don't let notification errors crash the app
          });
    } catch (e) {
      print('❌ Error setting up notifications: $e');
      // Don't let notification errors crash the app
    }
  }

  Future<void> _requestPermissions() async {
    try {
      print('🔐 Requesting permissions...');
      await requestAllPermissions().timeout(const Duration(seconds: 5));
      print('✅ Permissions requested');
    } catch (e) {
      print('❌ Permission request failed: $e');
      // Continue without permissions
    }
  }

  void _initializeDatabase() {
    try {
      // Initialize database in background
      DatabaseHelper().database
          .then((_) {
            print('✅ Database initialized');
          })
          .catchError((e) {
            print('❌ Database initialization failed: $e');
            return null;
          });
    } catch (e) {
      print('❌ Error initializing database: $e');
    }
  }

  Future<void> _checkLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (!mounted) return;

      setState(() => _isInitializing = false);

      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error checking login state: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _initializeConnectivity() async {
    try {
      print('🌐 Initializing connectivity service...');
      await ConnectivityService().initialize();

      // Show initial connectivity status notification
      await ConnectivityService().showInitialStatus();
      print('✅ Connectivity service initialized');
    } catch (e) {
      print('❌ Connectivity service initialization failed: $e');
      // Continue without connectivity service
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.school, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 40),

            // App name
            const Text(
              'XTAP',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),

            // Status text
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                color: _hasError ? Colors.red : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Loading indicator
            if (_isInitializing && !_hasError)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),

            // Error retry button
            if (_hasError)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitializing = true;
                    _status = 'Retrying...';
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
