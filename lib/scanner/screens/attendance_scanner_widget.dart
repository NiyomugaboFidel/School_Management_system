import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/models/scan_result.dart';
import 'package:sqlite_crud_app/models/student.dart';
import 'package:sqlite_crud_app/models/attendance.dart';
import 'package:sqlite_crud_app/Components/br_code.dart';
import 'package:sqlite_crud_app/Components/nfc_widget.dart';
import 'package:sqlite_crud_app/services/auth_services.dart';
import 'package:sqlite_crud_app/SQLite/database_helper.dart';
import 'package:sqlite_crud_app/scanner/screens/scanner_screen.dart'
    show ScannerType;

class AttendanceScannerWidget extends StatefulWidget {
  final String currentUserName;
  final TimeOfDay? lateTimeThreshold;

  const AttendanceScannerWidget({
    super.key,
    required this.currentUserName,
    this.lateTimeThreshold = const TimeOfDay(hour: 8, minute: 30),
  });

  @override
  State<AttendanceScannerWidget> createState() =>
      _AttendanceScannerWidgetState();
}

class _AttendanceScannerWidgetState extends State<AttendanceScannerWidget>
    with TickerProviderStateMixin {
  late final StudentService _studentService;
  List<AttendanceLog> _todayAttendance = [];
  bool _isProcessing = false;
  ScannerType _selectedScanner = ScannerType.none;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
    _loadTodayAttendance();
  }

  void _initializeServices() {
    _studentService = StudentService();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final attendanceList = await AttendanceService().getTodayAttendance();
      setState(() {
        _todayAttendance = attendanceList;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load today\'s attendance: $e');
    }
  }

  Future<void> _handleScanResult(ScanResult scanResult) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });
    try {
      Student? student;
      String rawId = '';
      if (scanResult.type == ScanType.nfc) {
        rawId = scanResult.data;
      } else if (scanResult.type == ScanType.barcode ||
          scanResult.type == ScanType.qrCode) {
        rawId = scanResult.id;
      }
      print(
        '[DEBUG] Raw scanned ID: \x1B[33m$rawId\x1B[0m (type: \x1B[36m${rawId.runtimeType}\x1B[0m)',
      );

      int? parsedId = int.tryParse(rawId.trim());
      if (parsedId == null) {
        print('[ERROR] Failed to parse scanned ID to int: $rawId');
        _showErrorSnackBar('Invalid student ID scanned: $rawId');
        return;
      }

      print('[DEBUG] Parsed scanned ID as int: \x1B[32m$parsedId\x1B[0m');

      // Use parsedId for lookup
      student = await _studentService.getStudentById(parsedId.toString());

      print(
        '[DEBUG] Student lookup result: ${student != null ? 'FOUND' : 'NOT FOUND'}',
      );

      if (student == null) {
        _showErrorSnackBar(
          'Student not found for scanned ${_getScanTypeName(scanResult.type)}',
        );
        return;
      }

      final existingAttendance = _todayAttendance.firstWhere(
        (attendance) => attendance.studentId == student!.studentId,
        orElse:
            () => AttendanceLog(
              id: 0,
              studentId: 0,
              date: DateTime.now(),
              status: AttendanceStatus.absent,
              markedBy: '',
              markedAt: DateTime.now(),
            ),
      );
      if (existingAttendance.id != 0) {
        _showWarningDialog(student, existingAttendance);
        return;
      }
      final currentTime = TimeOfDay.now();
      final attendanceStatus = _determineAttendanceStatus(currentTime);
      final status = attendanceStatus.value; // Use capitalized value for DB
      final success = await DatabaseHelper().markAttendance(
        student.studentId,
        status,
        widget.currentUserName,
      );
      print(
        '[DEBUG] Attendance mark result: ${success ? 'SUCCESS' : 'FAILURE'}',
      );
      if (success) {
        _showSuccessDialog(student, attendanceStatus, scanResult.type);
        await _loadTodayAttendance();
        HapticFeedback.heavyImpact();
      } else {
        _showErrorSnackBar('Failed to mark attendance for ${student.fullName}');
      }
    } catch (e) {
      print('[ERROR] Exception in _handleScanResult: $e');
      _showErrorSnackBar('Error processing scan: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  AttendanceStatus _determineAttendanceStatus(TimeOfDay currentTime) {
    if (widget.lateTimeThreshold == null) return AttendanceStatus.present;
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final lateThresholdMinutes =
        widget.lateTimeThreshold!.hour * 60 + widget.lateTimeThreshold!.minute;
    return currentMinutes > lateThresholdMinutes
        ? AttendanceStatus.late
        : AttendanceStatus.present;
  }

  String _getAttendanceNotes(AttendanceStatus status, ScanType scanType) {
    final scanMethod = _getScanTypeName(scanType);
    final time = TimeOfDay.now().format(context);
    switch (status) {
      case AttendanceStatus.present:
        return 'Marked present via $scanMethod at $time';
      case AttendanceStatus.late:
        return 'Marked late via $scanMethod at $time';
      case AttendanceStatus.absent:
        return 'Marked absent via $scanMethod at $time';
      case AttendanceStatus.excused:
        return 'Marked excused via $scanMethod at $time';
    }
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

  Future<void> _markAbsentStudents() async {
    try {
      final allStudents = await _studentService.getAllStudents();
      final unmarkedStudents =
          allStudents.where((student) {
            return !_todayAttendance.any(
              (attendance) => attendance.studentId == student.studentId,
            );
          }).toList();
      if (unmarkedStudents.isEmpty) {
        _showInfoSnackBar('All students have been marked for today');
        return;
      }
      final confirmed = await _showConfirmationDialog(
        'Mark ${unmarkedStudents.length} students as absent?',
        'This will mark all unmarked students as absent for today.',
      );
      if (!confirmed) return;
      int successCount = 0;
      for (final student in unmarkedStudents) {
        const status = 'Absent';
        final success = await DatabaseHelper().markAttendance(
          student.studentId,
          // AttendanceStatus.absent.name,
          // widget.currentUserName,
          // notes: 'Auto-marked absent - end of day process',
          status,
          'CurrentUser',
        );
        if (success) successCount++;
      }
      _showSuccessSnackBar('$successCount students marked as absent');
      await _loadTodayAttendance();
    } catch (e) {
      _showErrorSnackBar('Failed to mark absent students: $e');
    }
  }

  void _showSuccessDialog(
    Student student,
    AttendanceStatus status,
    ScanType scanType,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    size: 40,
                    color: _getStatusColor(status),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  status.name.toUpperCase() + ' ✓',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${student.studentId}',
                  style: TextStyle(fontSize: 14, color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scanned via ${_getScanTypeName(scanType)}',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showWarningDialog(Student student, AttendanceLog existingAttendance) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: AppColors.warning),
                const SizedBox(width: 8),
                const Text('Already Marked'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${student.fullName} has already been marked today:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(existingAttendance.status),
                        color: _getStatusColor(existingAttendance.status),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        existingAttendance.status.value.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(title),
                content: Text(content),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.excused:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.excused:
        return Icons.info_outline;
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildScannerSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_reg, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Attendance Scanner',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Scan student cards to mark attendance',
            style: TextStyle(fontSize: 16, color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          if (widget.lateTimeThreshold != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Late after: ${widget.lateTimeThreshold!.format(context)}',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          _buildScannerButton(
            title: 'NFC Scanner',
            subtitle: 'Scan NFC student cards',
            icon: Icons.nfc_rounded,
            color: AppColors.primary,
            onTap: () => _selectScanner(ScannerType.nfc),
          ),
          const SizedBox(height: 16),
          _buildScannerButton(
            title: 'Barcode Scanner',
            subtitle: 'Scan student barcodes/QR codes',
            icon: Icons.qr_code_scanner_rounded,
            color: AppColors.info,
            onTap: () => _selectScanner(ScannerType.camera),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markAbsentStudents,
              icon: const Icon(Icons.event_busy),
              label: const Text('Mark Remaining as Absent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
                  child: Icon(icon, size: 30, color: color),
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
                    icon: Icon(Icons.arrow_back_ios, color: AppColors.textDark),
                  ),
                  Text(
                    _selectedScanner == ScannerType.nfc
                        ? 'NFC Scanner'
                        : 'Barcode Scanner',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  // Test button for emulator
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Replace with a valid test student ID from your DB
                      const testStudentId = '20240001';
                      await _handleScanResult(
                        ScanResult(
                          id: testStudentId,
                          data: testStudentId,
                          type:
                              _selectedScanner == ScannerType.nfc
                                  ? ScanType.nfc
                                  : ScanType.barcode,
                          timestamp: DateTime.now(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isProcessing)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Processing scan...',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
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

  Widget _buildAttendanceStats() {
    final presentCount =
        _todayAttendance
            .where((a) => a.status == AttendanceStatus.present)
            .length;
    final lateCount =
        _todayAttendance.where((a) => a.status == AttendanceStatus.late).length;
    final absentCount =
        _todayAttendance
            .where((a) => a.status == AttendanceStatus.absent)
            .length;
    final totalMarked = _todayAttendance.length;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
          Text(
            'Today\'s Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Present', presentCount, AppColors.success),
              const SizedBox(width: 12),
              _buildStatCard('Late', lateCount, AppColors.warning),
              const SizedBox(width: 12),
              _buildStatCard('Absent', absentCount, AppColors.error),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total marked: $totalMarked students',
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedScanner == ScannerType.none)
                    _buildScannerSelection()
                  else
                    _buildScannerView(),
                  if (_todayAttendance.isNotEmpty) _buildAttendanceStats(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
