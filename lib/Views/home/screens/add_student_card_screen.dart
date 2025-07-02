import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/SQLite/database_helper_full.dart';
import 'package:barcode_widget/barcode_widget.dart' as barcode_widget;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

import 'web_download_helper.dart'
    if (dart.library.html) 'web_download_helper_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqlite_crud_app/services/nfc_service.dart';

class AddStudentCardScreen extends StatefulWidget {
  const AddStudentCardScreen({Key? key}) : super(key: key);

  @override
  State<AddStudentCardScreen> createState() => _AddStudentCardScreenState();
}

class _AddStudentCardScreenState extends State<AddStudentCardScreen>
    with TickerProviderStateMixin {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _barcodeKey = GlobalKey();
  final GlobalKey _downloadBarcodeKey =
      GlobalKey(); // New key for download-only barcode

  String? barcodeData;
  bool isWritingNfc = false;
  bool isGeneratingBarcode = false;
  bool isDownloadingBarcode = false;
  String? nfcStatus;
  String? errorMessage;
  bool showBarcodeCard = false;
  bool nfcAvailable = false;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkNfcAvailability();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkNfcAvailability() async {
    nfcAvailable = await NFCService.instance.isAvailable();
    setState(() {});
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (errorMessage != null) {
      setState(() {
        errorMessage = null;
      });
    }
  }

  Future<void> _generateBarcode() async {
    _clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final studentId = _idController.text.trim();

    if (studentId.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a valid Student ID';
      });
      return;
    }

    setState(() {
      isGeneratingBarcode = true;
      errorMessage = null;
    });

    try {
      // Check if student already exists
      final existingStudents = await DatabaseHelper().getAllStudents();
      final existingStudent =
          existingStudents
              .where((s) => s.studentId.toString() == studentId)
              .firstOrNull;

      if (existingStudent != null) {
        setState(() {
          errorMessage = 'Student with ID $studentId already exists';
          isGeneratingBarcode = false;
        });
        return;
      }

      // Simulate generation delay for better UX
      await Future.delayed(const Duration(milliseconds: 800));

      // Generate barcode data with student info
      barcodeData = studentId;
      showBarcodeCard = true;

      // Trigger animations
      _animationController.forward();

      // Haptic feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to generate barcode: ${e.toString()}';
      });
    } finally {
      setState(() {
        isGeneratingBarcode = false;
      });
    }
  }

  Future<void> _writeNfc() async {
    if (barcodeData == null) return;
    if (kIsWeb) {
      setState(() {
        errorMessage = 'NFC writing is not supported on web browsers';
      });
      return;
    }
    if (!nfcAvailable) {
      setState(() {
        errorMessage = 'NFC is not available on this device';
      });
      return;
    }
    setState(() {
      isWritingNfc = true;
      nfcStatus = null;
      errorMessage = null;
    });
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildNfcProgressDialog(),
      );
      // Use NFCService's writeJsonToTag for writing
      final studentData = {
        'studentId': barcodeData,
        'studentName': _nameController.text.trim(),
        'generatedAt': DateTime.now().toIso8601String(),
        'type': 'student_card',
      };
      final success = await NFCService.instance.writeJsonToTag(studentData);
      Navigator.of(context).pop();
      setState(() {
        nfcStatus = success
            ? 'NFC card written successfully!\nStudent ID: $barcodeData'
            : 'NFC write failed.';
      });
      HapticFeedback.heavyImpact();
      if (success) _showSuccessOverlay();
    } catch (e) {
      Navigator.of(context).pop();
      await NFCService.instance.finish(iosErrorMessage: e.toString());
      setState(() {
        nfcStatus = 'NFC write failed: ${e.toString()}';
        errorMessage = e.toString();
      });
      HapticFeedback.heavyImpact();
    } finally {
      setState(() {
        isWritingNfc = false;
      });
    }
  }

  // Build clean barcode widget for download only
  Widget _buildDownloadBarcodeWidget() {
    return Container(
      padding: const EdgeInsets.all(24),

      child: barcode_widget.BarcodeWidget(
        barcode: barcode_widget.Barcode.code128(),
        data: barcodeData!,
        width: 400, // Increased width for better quality
        height: 120, // Increased height for better quality
        drawText: true,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Future<void> _downloadBarcode() async {
    if (barcodeData == null) return;

    setState(() {
      isDownloadingBarcode = true;
      errorMessage = null;
    });

    try {
      // Create an off-screen widget to capture the clean barcode
      final downloadWidget = RepaintBoundary(
        key: _downloadBarcodeKey,
        child: _buildDownloadBarcodeWidget(),
      );

      // Build the widget in memory
      final RenderRepaintBoundary boundary = RenderRepaintBoundary();
      final element = downloadWidget.createElement();
      element.mount(null, null);

      // Create a render object tree
      final RenderView renderView = RenderView(
        view: WidgetsBinding.instance.platformDispatcher.implicitView!,
        configuration: const ViewConfiguration(
          devicePixelRatio: 3.0, // High DPI for quality
        ),
      );

      final RenderPositionedBox renderPositionedBox = RenderPositionedBox(
        alignment: Alignment.center,
        child: boundary,
      );

      renderView.child = renderPositionedBox;
      boundary.child = downloadWidget.createRenderObject(element);

      // Layout and paint
      renderView.prepareInitialFrame();
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to generate image data');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final now = DateTime.now();
      final formattedDate =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      final fileName =
          '${_nameController.text.toUpperCase()}_${barcodeData}_$formattedDate.png';

      if (kIsWeb) {
        await _downloadForWeb(pngBytes, fileName);
      } else {
        await _downloadForMobile(pngBytes, fileName);
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      // Fallback: Use the visible barcode widget if the off-screen method fails
      try {
        final RenderRepaintBoundary boundary =
            _barcodeKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;

        final ui.Image image = await boundary.toImage(
          pixelRatio: 4.0,
        ); // Higher quality
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData == null) {
          throw Exception('Failed to generate image data');
        }

        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final now = DateTime.now();
        final formattedDate =
            '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
        final fileName =
            '${_nameController.text.toUpperCase()}_${barcodeData}_$formattedDate.png';

        if (kIsWeb) {
          await _downloadForWeb(pngBytes, fileName);
        } else {
          await _downloadForMobile(pngBytes, fileName);
        }

        HapticFeedback.lightImpact();
      } catch (fallbackError) {
        setState(() {
          errorMessage =
              'Failed to download barcode: ${fallbackError.toString()}';
        });
        HapticFeedback.heavyImpact();

        if (mounted) {
          _showErrorDialog('Download Failed', fallbackError.toString());
        }
      }
    } finally {
      setState(() {
        isDownloadingBarcode = false;
      });
    }
  }

  Future<void> _downloadForWeb(Uint8List pngBytes, String fileName) async {
    try {
      if (!kIsWeb) {
        throw Exception('Web download called on non-web platform');
      }
      await downloadImageWeb(pngBytes, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Student Card Downloaded Successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      throw Exception('Web download failed: $e');
    }
  }

  Future<void> _downloadForMobile(Uint8List pngBytes, String fileName) async {
    try {
      // Request storage permission for mobile
      permission_handler.PermissionStatus status;
      if (Platform.isAndroid) {
        if (await permission_handler.Permission.storage.isDenied) {
          status = await permission_handler.Permission.storage.request();
        } else {
          status = permission_handler.PermissionStatus.granted;
        }

        // For Android 13+ (API 33+), use photos permission instead
        if (status.isDenied) {
          status = await permission_handler.Permission.photos.request();
        }
      } else {
        status = await permission_handler.Permission.photos.request();
      }

      if (!status.isGranted && !status.isLimited) {
        throw Exception(
          'Storage permission is required to save the student card',
        );
      }

      // Get appropriate directory based on platform
      Directory? directory;
      String filePath;

      if (Platform.isAndroid) {
        // Try to use Downloads directory first
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage directory
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            directory = Directory('${directory.path}/Downloads');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          }
        }
      } else {
        // For iOS, use documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(pngBytes);

      // Verify file was created
      if (!await file.exists()) {
        throw Exception('Failed to save file');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Student Card Saved Successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saved to: ${Platform.isAndroid ? 'Downloads' : 'Documents'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _shareBarcode(pngBytes, fileName),
                  icon: const Icon(Icons.share, color: Colors.white, size: 24),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'VIEW FOLDER',
              textColor: Colors.white,
              onPressed: () {
                // Could implement file manager opening here
              },
            ),
          ),
        );
      }
    } catch (e) {
      throw Exception('Mobile download failed: $e');
    }
  }

  Future<void> _shareBarcode(Uint8List pngBytes, String fileName) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'File has been downloaded to your device. You can share it from your downloads folder.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // Note: Add share_plus package for actual sharing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'File prepared for sharing. Add share_plus package to enable sharing functionality.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      debugPrint('Failed to prepare file for sharing: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSuccessOverlay() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Success!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'NFC card has been written successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Widget _buildNfcProgressDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.nfc, color: AppColors.primary, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Writing NFC Card...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please hold your NFC card near the device',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isWritingNfc = false;
                });
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _idController.clear();
      _nameController.clear();
      barcodeData = null;
      showBarcodeCard = false;
      nfcStatus = null;
      errorMessage = null;
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Student Card Generator',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (showBarcodeCard)
            IconButton(
              onPressed: _resetForm,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Reset Form',
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildInputForm(),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(),
            ],
            if (nfcStatus != null) ...[
              const SizedBox(height: 16),
              _buildStatusCard(),
            ],
            if (showBarcodeCard) ...[
              const SizedBox(height: 24),
              _buildBarcodeCard(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Digital ID Generator',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Create & manage student cards',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                        if (kIsWeb) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'WEB',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                        if (!kIsWeb && nfcAvailable) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NFC',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    kIsWeb
                        ? 'Generate unique barcodes for student identification. Download works on all platforms. NFC writing requires mobile app.'
                        : 'Generate unique barcodes and NFC cards for seamless student identification and attendance tracking.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.person_add_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Student Information',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: 'Student ID *',
                hintText: 'Enter unique student identifier',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Student ID is required';
                }
                if (value.trim().length < 3) {
                  return 'Student ID must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Student Name (Optional)',
                hintText: 'Enter full name for records',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 28),
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isGeneratingBarcode
                          ? [Colors.grey.shade300, Colors.grey.shade400]
                          : [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    isGeneratingBarcode
                        ? null
                        : [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
              ),
              child: ElevatedButton.icon(
                onPressed: isGeneratingBarcode ? null : _generateBarcode,
                icon:
                    isGeneratingBarcode
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.qr_code_2_rounded, size: 24),
                label: Text(
                  isGeneratingBarcode
                      ? 'Generating...'
                      : 'Generate Student Card',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isSuccess = nfcStatus!.toLowerCase().contains('success');
    final color = isSuccess ? AppColors.success : Colors.red;
    final bgColor = isSuccess ? Colors.green.shade50 : Colors.red.shade50;
    final borderColor = isSuccess ? Colors.green.shade200 : Colors.red.shade200;
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nfcStatus!,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success,
                            AppColors.success.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generated Successfully!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your student card is ready',
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
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  // decoration: BoxDecoration(
                  //   gradient: LinearGradient(
                  //     colors: [Colors.grey.shade50, Colors.white],
                  //     begin: Alignment.topCenter,
                  //     end: Alignment.bottomCenter,
                  //   ),
                  //   borderRadius: BorderRadius.circular(16),
                  //   border: Border.all(color: Colors.grey.shade200),
                  //   boxShadow: [
                  //     BoxShadow(
                  //       color: Colors.black.withOpacity(0.02),
                  //       blurRadius: 10,
                  //       offset: const Offset(0, 4),
                  //     ),
                  //   ],
                  // ),
                  child: RepaintBoundary(
                    key: _barcodeKey,
                    child: Column(
                      children: [
                        // Student Card Header
                        // Container(
                        //   width: double.infinity,
                        //   padding: const EdgeInsets.all(16),
                        //   decoration: BoxDecoration(
                        //     gradient: LinearGradient(
                        //       colors: [
                        //         AppColors.primary,
                        //         AppColors.primary.withOpacity(0.8),
                        //       ],
                        //     ),
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   child: Column(
                        //     children: [
                        //       const Text(
                        //         'STUDENT ID CARD',
                        //         style: TextStyle(
                        //           color: Colors.white,
                        //           fontWeight: FontWeight.bold,
                        //           fontSize: 16,
                        //           letterSpacing: 1.2,
                        //         ),
                        //       ),
                        //       const SizedBox(height: 8),
                        //       if (_nameController.text.isNotEmpty)
                        //         Text(
                        //           _nameController.text.toUpperCase(),
                        //           style: const TextStyle(
                        //             color: Colors.white,
                        //             fontWeight: FontWeight.w600,
                        //             fontSize: 14,
                        //           ),
                        //           textAlign: TextAlign.center,
                        //         ),
                        //     ],
                        //   ),
                        // ),
                        // const SizedBox(height: 20),
                        // // Barcode
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white),
                          child: barcode_widget.BarcodeWidget(
                            barcode: barcode_widget.Barcode.code128(),
                            data: barcodeData!,
                            width: 280,
                            height: 80,
                            drawText: true,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        // const SizedBox(height: 16),
                        // // Student ID Display
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 16,
                        //     vertical: 8,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: AppColors.primary.withOpacity(0.1),
                        //     borderRadius: BorderRadius.circular(8),
                        //   ),
                        //   child: Text(
                        //     'ID: $barcodeData',
                        //     style: const TextStyle(
                        //       fontSize: 14,
                        //       fontWeight: FontWeight.bold,
                        //       color: AppColors.primary,
                        //       letterSpacing: 0.5,
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 12),
                        // // Generated timestamp
                        // Text(
                        //   'Generated: ${DateTime.now().toString().split('.')[0]}',
                        //   style: TextStyle(
                        //     fontSize: 10,
                        //     color: Colors.grey.shade600,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isDownloadingBarcode
                                    ? [
                                      Colors.grey.shade300,
                                      Colors.grey.shade400,
                                    ]
                                    : [
                                      AppColors.success,
                                      AppColors.success.withOpacity(0.8),
                                    ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow:
                              isDownloadingBarcode
                                  ? null
                                  : [
                                    BoxShadow(
                                      color: AppColors.success.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed:
                              isDownloadingBarcode ? null : _downloadBarcode,
                          icon:
                              isDownloadingBarcode
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.download_rounded,
                                    size: 20,
                                  ),
                          label: Text(
                            isDownloadingBarcode ? 'Saving...' : 'Save Card',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isWritingNfc
                                    ? [
                                      Colors.grey.shade300,
                                      Colors.grey.shade400,
                                    ]
                                    : [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.8),
                                    ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow:
                              isWritingNfc
                                  ? null
                                  : [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: isWritingNfc ? null : _writeNfc,
                          icon:
                              isWritingNfc
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(Icons.nfc_rounded, size: 20),
                          label: Text(
                            isWritingNfc ? 'Writing...' : 'Write NFC',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Additional Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed:
                          () => _shareBarcode(
                            Uint8List(0),
                            'student_card_$barcodeData.png',
                          ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey.shade300,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text('Card Information'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Student ID: $barcodeData'),
                                    if (_nameController.text.isNotEmpty)
                                      Text('Name: ${_nameController.text}'),
                                    Text('Barcode Type: Code128'),
                                    Text(
                                      'Generated: ${DateTime.now().toString().split('.')[0]}',
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey.shade300,
                    ),
                    TextButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('New Card'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ));
  }
}
