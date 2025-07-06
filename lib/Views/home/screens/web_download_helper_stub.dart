// web_download_helper_stub.dart
// Stub implementation for non-web platforms
import 'dart:typed_data';

Future<void> downloadImageWeb(Uint8List pngBytes, String fileName) async {
  throw UnsupportedError('Web download is not available on this platform');
} 