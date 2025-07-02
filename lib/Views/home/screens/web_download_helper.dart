// web_download_helper.dart
// Fallback for non-web platforms
import 'dart:typed_data';

Future<void> downloadImageWeb(Uint8List pngBytes, String fileName) async {
  throw UnsupportedError('Web download is only supported on web platform');
}
