import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import '../models/scan_result.dart';

class CameraScannerWidget extends StatefulWidget {
  final Function(ScanResult) onScanResult;

  const CameraScannerWidget({super.key, required this.onScanResult});

  @override
  State<CameraScannerWidget> createState() => _CameraScannerWidgetState();
}

class _CameraScannerWidgetState extends State<CameraScannerWidget> {
  MobileScannerController? controller;
  bool _isScanning = false;
  bool _hasPermission = true;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _handleBarcodeDetection(BarcodeCapture barcodeCapture) {
    if (barcodeCapture.barcodes.isNotEmpty && _isScanning) {
      final barcode = barcodeCapture.barcodes.first;
      if (barcode.rawValue != null) {
        _handleScanResult(barcode);
      }
    }
  }

  void _handleScanResult(Barcode barcode) {
    ScanType type = ScanType.qrCode;

    // Determine scan type based on format
    switch (barcode.format) {
      case BarcodeFormat.qrCode:
        type = ScanType.qrCode;
        break;
      case BarcodeFormat.ean13:
      case BarcodeFormat.ean8:
      case BarcodeFormat.code128:
      case BarcodeFormat.code39:
      case BarcodeFormat.code93:
      case BarcodeFormat.codabar:
      case BarcodeFormat.dataMatrix:
      case BarcodeFormat.pdf417:
      case BarcodeFormat.aztec:
      case BarcodeFormat.itf:
        type = ScanType.barcode;
        break;
      default:
        type = ScanType.qrCode;
    }

    final result = ScanResult(
      id: barcode.rawValue ?? '',
      data: barcode.rawValue ?? '',
      type: type,
      timestamp: DateTime.now(),
    );

    widget.onScanResult(result);
    _stopScanning();
  }

  void _startScanning() async {
    try {
      controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      setState(() {
        _isScanning = true;
        _hasPermission = true;
      });
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _isScanning = false;
      });
    }
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    controller?.dispose();
    controller = null;
  }

  void _toggleFlash() async {
    await controller?.toggleTorch();
  }

  Widget _buildScannerOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Corner indicators
              Positioned(
                top: -2,
                left: -2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white, width: 4),
                      left: BorderSide(color: Colors.white, width: 4),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white, width: 4),
                      right: BorderSide(color: Colors.white, width: 4),
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                left: -2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 4),
                      left: BorderSide(color: Colors.white, width: 4),
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 4),
                      right: BorderSide(color: Colors.white, width: 4),
                    ),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Camera Scanner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'QR Code & Barcode',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Camera View or Start Button
            if (_isScanning && controller != null) ...[
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Mobile Scanner View
                      MobileScanner(
                        controller: controller!,
                        onDetect: _handleBarcodeDetection,
                      ),

                      // Custom overlay
                      _buildScannerOverlay(),

                      // Top controls
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _stopScanning,
                              icon: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.5),
                              ),
                            ),
                            IconButton(
                              onPressed: _toggleFlash,
                              icon: Icon(
                                Icons.flash_on,
                                color: Colors.white,
                                size: 24,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom instruction
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Align QR code or barcode within the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Start button
              SizedBox(
                width: double.infinity,
                height: 120,
                child: ElevatedButton.icon(
                  onPressed: _startScanning,
                  icon: Icon(Icons.camera_alt, size: 32),
                  label: Text(
                    'Start Scanner',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Permission error message
            if (!_hasPermission)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Camera permission required to scan codes',
                        style: TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
