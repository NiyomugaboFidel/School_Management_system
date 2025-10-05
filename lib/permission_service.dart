import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

Future<void> requestAllPermissions() async {
  try {
    // Request permissions in parallel to speed up the process
    await Future.wait([
      Permission.camera.request(),
      Permission.microphone.request(),
      Permission.storage.request(),
      Permission.notification.request(),
      Permission.phone.request(),
      Permission.sensors.request(),
    ]);

    // Request more sensitive permissions separately
    try {
      await Permission.manageExternalStorage.request();
    } catch (e) {
      print('External storage permission failed: $e');
    }

    try {
      await Permission.ignoreBatteryOptimizations.request();
    } catch (e) {
      print('Battery optimization permission failed: $e');
    }
  } catch (e) {
    print('Error requesting permissions: $e');
    // Continue without permissions rather than blocking the app
  }
}
