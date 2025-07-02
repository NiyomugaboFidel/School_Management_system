import 'package:permission_handler/permission_handler.dart';

Future<void> requestAllPermissions() async {
  await [
    Permission.camera,
    Permission.microphone,
    Permission.storage,
    Permission.manageExternalStorage,
    Permission.notification,
    Permission.phone,
    Permission.sensors,
    Permission.ignoreBatteryOptimizations,
  ].request();
}
