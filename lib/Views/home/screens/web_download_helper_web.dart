// web_download_helper_web.dart
// Only imported on web via conditional import
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadImageWeb(Uint8List pngBytes, String fileName) async {
  final blob = html.Blob([pngBytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor =
      html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;
  html.document.body!.children.add(anchor);
  anchor.click();
  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
