import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static FlutterLocalNotificationsPlugin? _notifications;
  static FirebaseMessaging? _firebaseMessaging;

  // Notification channels
  static const String _attendanceChannel = 'attendance_channel';
  static const String _syncChannel = 'sync_channel';
  static const String _systemChannel = 'system_channel';

  /// Initialize notification service
  Future<void> initialize() async {
    _notifications = FlutterLocalNotificationsPlugin();
    _firebaseMessaging = FirebaseMessaging.instance;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();

    // Only run firebase_messaging code on non-web platforms
    if (!kIsWeb) {
      try {
        await _firebaseMessaging!.requestPermission();

        // Set up message listener with error handling
        FirebaseMessaging.onMessage.listen(
          (message) {
            try {
              final notification = message.notification;
              if (notification != null) {
                NotificationService.showNotification(
                  notification.title ?? 'Notification',
                  notification.body ?? '',
                );
              }
            } catch (e) {
              print('Error handling Firebase message: $e');
            }
          },
          onError: (error) {
            print('Firebase messaging error: $error');
          },
        );
      } catch (e) {
        print('Firebase messaging initialization failed: $e');
        // Continue without Firebase messaging
      }
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const androidChannel = AndroidNotificationChannel(
      _attendanceChannel,
      'Attendance Notifications',
      description: 'Notifications for attendance activities',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const syncChannel = AndroidNotificationChannel(
      _syncChannel,
      'Sync Notifications',
      description: 'Notifications for data synchronization',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
    );

    const systemChannel = AndroidNotificationChannel(
      _systemChannel,
      'System Notifications',
      description: 'General system notifications',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _notifications!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    await _notifications!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(syncChannel);

    await _notifications!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(systemChannel);
  }

  /// Show attendance marked notification
  Future<void> showAttendanceMarked({
    required String studentName,
    required String status,
    required String time,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _attendanceChannel,
        'Attendance Notifications',
        channelDescription: 'Notifications for attendance activities',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Attendance Marked',
      '$studentName marked as $status at $time',
      notificationDetails,
      payload: 'attendance_marked',
    );
  }

  /// Show sync success notification
  Future<void> showSyncSuccess({required int recordCount}) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _syncChannel,
        'Sync Notifications',
        channelDescription: 'Notifications for data synchronization',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        enableVibration: false,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1,
      'Sync Completed',
      'Successfully synced $recordCount records to cloud',
      notificationDetails,
      payload: 'sync_success',
    );
  }

  /// Show sync error notification
  Future<void> showSyncError({required String error}) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _syncChannel,
        'Sync Notifications',
        channelDescription: 'Notifications for data synchronization',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFF44336),
        enableVibration: false,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 2,
      'Sync Failed',
      'Failed to sync data: $error',
      notificationDetails,
      payload: 'sync_error',
    );
  }

  /// Show online notification
  Future<void> showOnlineNotification() async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _systemChannel,
        'System Notifications',
        channelDescription: 'General system notifications',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        enableVibration: false,
        playSound: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
    );

    await _notifications!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 3,
      'Online',
      'You are now online. Data will sync automatically.',
      notificationDetails,
      payload: 'online_status',
    );
  }

  /// Show offline notification
  Future<void> showOfflineNotification() async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _systemChannel,
        'System Notifications',
        channelDescription: 'General system notifications',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF9800),
        enableVibration: false,
        playSound: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      ),
    );

    await _notifications!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 4,
      'Offline',
      'You are offline. Data will sync when connection is restored.',
      notificationDetails,
      payload: 'offline_status',
    );
  }

  /// Show holiday notification
  Future<void> showHolidayNotification({required String holidayName}) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _systemChannel,
        'System Notifications',
        channelDescription: 'General system notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF9C27B0),
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 5,
      'Holiday Today',
      'Today is $holidayName. No attendance marking.',
      notificationDetails,
      payload: 'holiday',
    );
  }

  /// Show duplicate attendance warning
  Future<void> showDuplicateAttendanceWarning({
    required String studentName,
    required String existingStatus,
    required String newStatus,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _attendanceChannel,
        'Attendance Notifications',
        channelDescription: 'Notifications for attendance activities',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF9800),
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications!.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 6,
      'Duplicate Attendance',
      '$studentName already marked as $existingStatus. New status: $newStatus',
      notificationDetails,
      payload: 'duplicate_attendance',
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap based on payload
    switch (response.payload) {
      case 'attendance_marked':
        // Navigate to attendance screen
        break;
      case 'sync_success':
        // Show sync details
        break;
      case 'sync_error':
        // Show error details
        break;
      case 'holiday':
        // Show holiday details
        break;
      case 'duplicate_attendance':
        // Show attendance conflict resolution
        break;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications!.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications!.cancel(id);
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'default_channel',
          'General',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _notifications!.show(0, title, body, platformChannelSpecifics);
    await logNotification(title, body);
  }

  static Future<void> logNotification(String title, String body) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
