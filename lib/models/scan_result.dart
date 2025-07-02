class ScanResult {
  final String id;
  final String data;
  final ScanType type;
  final DateTime timestamp;

  ScanResult({
    required this.id,
    required this.data,
    required this.type,
    required this.timestamp,
  });
}

enum ScanType { nfc, qrCode, barcode }