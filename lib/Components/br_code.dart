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

class _CameraScannerWidgetState extends State<CameraScannerWidget>
    with TickerProviderStateMixin {
  MobileScannerController? controller;
  bool _isScanning = false;
  bool _hasPermission = true;
  
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Scan line animation (moves from top to bottom)
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for scan button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
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
      });
      
      _scanLineController.repeat();
    } catch (e) {
      setState(() {
        _hasPermission = false;
      });
    }
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    controller?.dispose();
    controller = null;
    _scanLineController.stop();
  }

  void _toggleFlash() async {
    await controller?.toggleTorch();
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        // Dark overlay
        Container(
          color: Colors.black.withOpacity(0.5),
        ),
        
        // Center scanning area
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Corner decorations
                Positioned(
                  top: -2,
                  left: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.primary, width: 4),
                        left: BorderSide(color: AppColors.primary, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
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
                        top: BorderSide(color: AppColors.primary, width: 4),
                        right: BorderSide(color: AppColors.primary, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
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
                        bottom: BorderSide(color: AppColors.primary, width: 4),
                        left: BorderSide(color: AppColors.primary, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
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
                        bottom: BorderSide(color: AppColors.primary, width: 4),
                        right: BorderSide(color: AppColors.primary, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                // Animated scan line
                if (_isScanning)
                  AnimatedBuilder(
                    animation: _scanLineAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanLineAnimation.value * 246,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        
        // Instructions
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Position the QR code or barcode within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 24,
                    color: AppColors.info,
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
                      
                      // Flash toggle button
                      // Positioned(
                      //   top: 16,
                      //   right: 16,
                      //   child: Container(
                      //     decoration: BoxDecoration(
                      //       color: Colors.black.withOpacity(0.5),
                      //       borderRadius: BorderRadius.circular(8),
                      //     ),
                      //     child: IconButton(
                      //       onPressed: _toggleFlash,
                      //       icon: ValueListenableBuilder<bool>(
                      //         valueListenable: controller!.torchEnabled,
                      //         builder: (context, state, child) {
                      //           return Icon(
                      //             state
                      //                 ? Icons.flash_on
                      //                 : Icons.flash_off,
                      //             color: Colors.white,
                      //           );
                      //         },
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Control buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stopScanning,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Scanning'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Start scanning button with animation
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 40,
                              color: AppColors.info,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ready to Scan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the button below to start scanning',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startScanning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'Start Camera Scan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Supports QR codes, barcodes, and other formats',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Permission error message
            if (!_hasPermission)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Camera permission required to scan codes',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
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