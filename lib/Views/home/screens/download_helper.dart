// download_helper.dart
// Platform-agnostic download helper with conditional imports
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Conditional import for web implementation
import 'web_download_helper_stub.dart'
    if (dart.library.html) 'web_download_helper_web.dart';

Future<void> downloadImage(Uint8List pngBytes, String fileName) async {
  if (kIsWeb) {
    await downloadImageWeb(pngBytes, fileName);
  } else {
    // For mobile platforms, show a message
    throw UnsupportedError('Download is only supported on web platform');
  }
}
