import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/scanner/screens/attendance_scanner_widget.dart';

enum ScannerType { nfc, qrCode, barcode, none, camera, attendance }

class ScannerMainScreen extends StatefulWidget {
  const ScannerMainScreen({super.key});

  @override
  State<ScannerMainScreen> createState() => _ScannerMainScreenState();
}

class _ScannerMainScreenState extends State<ScannerMainScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Attendance Scanner',
          style: TextStyle(color: AppColors.white),
        ),
        centerTitle: false,
      ),
      body: Center(child: AttendanceScannerWidget(currentUserName: 'Admin')),
    );
  }
}
