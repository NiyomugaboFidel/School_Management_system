import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/models/scan_result.dart';
import 'package:sqlite_crud_app/Components/br_code.dart';
import 'package:sqlite_crud_app/Components/nfc_widget.dart';

enum ScannerType { nfc, qrCode, barcode, none, camera }

class ScannerMainScreen extends StatefulWidget {
  const ScannerMainScreen({super.key});

  @override
  State<ScannerMainScreen> createState() => _ScannerMainScreenState();
}

class _ScannerMainScreenState extends State<ScannerMainScreen>
    with TickerProviderStateMixin {
  List<ScanResult> _scanResults = [];
  ScannerType _selectedScanner = ScannerType.none;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleScanResult(ScanResult result) {
    setState(() {
      _scanResults.insert(0, result);
    });

    // Show success feedback
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForScanType(result.type),
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_getScanTypeName(result.type)} scanned successfully!',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _selectScanner(ScannerType type) {
    setState(() {
      _selectedScanner = type;
    });
    _fadeController.forward();
    _slideController.forward();
  }

  void _goBack() {
    _fadeController.reverse();
    _slideController.reverse();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _selectedScanner = ScannerType.none;
      });
    });
  }

  void _clearResults() {
    setState(() {
      _scanResults.clear();
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  IconData _getIconForScanType(ScanType type) {
    switch (type) {
      case ScanType.nfc:
        return Icons.nfc_rounded;
      case ScanType.qrCode:
        return Icons.qr_code_rounded;
      case ScanType.barcode:
        return Icons.barcode_reader;
      default:
        return Icons.help_outline;
    }
  }

  String _getScanTypeName(ScanType type) {
    switch (type) {
      case ScanType.nfc:
        return 'NFC';
      case ScanType.qrCode:
        return 'QR Code';
      case ScanType.barcode:
        return 'Barcode';
    }
  }

  Color _getColorForScanType(ScanType type) {
    switch (type) {
      case ScanType.nfc:
        return AppColors.primary;
      case ScanType.qrCode:
        return AppColors.info;
      case ScanType.barcode:
        return AppColors.warning;
    }
  }

  Widget _buildScannerSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Scanner Type',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the type of scanner you want to use',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 32),
          
          // NFC Scanner Button
          _buildScannerButton(
            title: 'NFC Scanner',
            subtitle: 'Scan NFC tags and cards',
            icon: Icons.nfc_rounded,
            color: AppColors.primary,
            onTap: () => _selectScanner(ScannerType.nfc),
          ),
          
          const SizedBox(height: 16),
          
          // Camera Scanner Button
          _buildScannerButton(
            title: 'Camera Scanner',
            subtitle: 'Scan QR codes and barcodes',
            icon: Icons.qr_code_scanner_rounded,
            color: AppColors.info,
            onTap: () => _selectScanner(ScannerType.camera),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textLight,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    _selectedScanner == ScannerType.nfc ? 'NFC Scanner' : 'Camera Scanner',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Scanner Widget
              if (_selectedScanner == ScannerType.nfc)
                NfcScannerWidget(onScanResult: _handleScanResult)
              else if (_selectedScanner == ScannerType.camera)
                CameraScannerWidget(onScanResult: _handleScanResult),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Scan Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_scanResults.length}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.divider, height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _scanResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final result = _scanResults[index];
                return _buildResultItem(result, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ScanResult result, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.coloredBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getColorForScanType(result.type).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getColorForScanType(result.type),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForScanType(result.type),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getScanTypeName(result.type),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.textLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${result.timestamp.hour.toString().padLeft(2, '0')}:${result.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (result.id.isNotEmpty)
                    _buildDataContainer('ID', result.id),
                  if (result.data.isNotEmpty && result.data != result.id) ...[
                    const SizedBox(height: 8),
                    _buildDataContainer('Data', result.data),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataContainer(String label, String data) {
    return GestureDetector(
      onTap: () => _copyToClipboard(data),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontFamily: 'monospace',
              ),
              maxLines: label == 'Data' ? 3 : null,
              overflow: label == 'Data' ? TextOverflow.ellipsis : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldWithBoxBackground,
      appBar: AppBar(
        title: const Text(
          'Scanner App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          if (_scanResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.white),
              onPressed: _clearResults,
              tooltip: 'Clear all results',
            ),
        ],
      ),
      body: Column(
        children: [
          // Scanner Section
          if (_selectedScanner == ScannerType.none)
            _buildScannerSelection()
          else
            _buildScannerView(),

          // Results Section
          if (_scanResults.isNotEmpty)
            Expanded(child: _buildResultsList()),

          // Empty State
          if (_scanResults.isEmpty && _selectedScanner != ScannerType.none)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 64,
                      color: AppColors.placeholder,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No scans yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start scanning to see results here',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}