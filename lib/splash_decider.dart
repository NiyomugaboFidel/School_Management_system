import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqlite_crud_app/permission_service.dart';
import 'package:sqlite_crud_app/services/notification_service.dart';
import 'package:sqlite_crud_app/SQLite/database_helper.dart';
import 'package:sqlite_crud_app/services/connectivity_service.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashDecider extends StatefulWidget {
  const SplashDecider({Key? key}) : super(key: key);

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

// Static method to test Firebase connection from anywhere
class FirebaseConnectionTester {
  static Future<void> testFirebaseConnection() async {
    try {
      print('🧪 Testing Firebase connection...');

      if (kIsWeb) {
        print('🌐 Testing on web platform');
      }

      // Try to send test data
      final now = DateTime.now();
      final testData = {
        'platform': kIsWeb ? 'web' : 'mobile',
        'timestamp': now.toIso8601String(),
        'message': 'Manual test from XTAP app',
        'test_type': 'manual_connection_test',
      };

      await FirebaseFirestore.instance
          .collection('test_connection')
          .add(testData);
      print('✅ Manual Firebase test successful!');
      print('📊 Test data sent: $testData');
    } catch (e) {
      print('❌ Manual Firebase test failed: $e');
      print('🔍 Error details: ${e.toString()}');
    }
  }
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
      // Step 1: Initialize Firebase
      setState(() => _status = 'Initializing Firebase...');
      await _initializeFirebase();

      // TEST: Send test data to Firestore to verify connection
      await _sendTestDataToFirestore();

      // Step 2: Initialize connectivity service and show status
      setState(() => _status = 'Checking connectivity...');
      await _initializeConnectivity();

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

  Future<void> _initializeFirebase() async {
    try {
      print('🔥 Initializing Firebase...');
      print('🌐 Platform: ${kIsWeb ? 'Web' : 'Mobile'}');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));

      print('✅ Firebase initialized successfully');

      // Test if Firestore is accessible
      if (kIsWeb) {
        print('🌐 Testing Firestore access on web...');
        try {
          // Just try to access Firestore to see if it's working
          final firestore = FirebaseFirestore.instance;
          print('✅ Firestore instance accessible on web');
        } catch (e) {
          print('⚠️ Firestore might not be fully configured for web: $e');
        }
      }
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      print('🔍 Error type: ${e.runtimeType}');

      if (kIsWeb) {
        print('🌐 Web-specific Firebase error - check your web configuration');
        print('💡 Make sure you have the correct Firebase web configuration');
      }

      // Continue without Firebase for now
      // Don't re-throw the error to prevent app crash
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
      DatabaseHelper().database.catchError((e) {
        print('Database initialization failed: $e');
      });
    } catch (e) {
      print('Error initializing database: $e');
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

  // Function to send test data to Firestore for connection testing
  Future<void> _sendTestDataToFirestore() async {
    try {
      // Check if we're on web and handle accordingly
      if (kIsWeb) {
        print('🌐 Running on web platform');
        // Add a small delay for web to ensure Firebase is fully initialized
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Only run if Firebase is initialized
      final now = DateTime.now();
      final testData = {
        'platform': kIsWeb ? 'web' : 'mobile',
        'timestamp': now.toIso8601String(),
        'message': 'Test data from XTAP app',
        'app_version': '1.0.0',
      };

      await FirebaseFirestore.instance
          .collection('test_connection')
          .add(testData);
      print('✅ Test data sent to Firestore successfully!');
      print('📊 Test data: $testData');
    } catch (e) {
      print('❌ Failed to send test data to Firestore: $e');
      print('🔍 Error details: ${e.toString()}');

      // Don't crash the app, just log the error
      if (kIsWeb) {
        print(
          '🌐 Web-specific Firebase error - this might be expected if Firebase is not fully configured for web',
        );
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
