import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/app_colors.dart';
import '../../../SQLite/database_helper.dart';
import '../../../utils/user_session.dart';
import '../../../services/sync_service.dart';
import '../../../models/attendance.dart';
import 'add_student_card_screen.dart';
import 'attendance_screen.dart';
import 'payment_screen.dart';
import 'discipline_screen.dart';
import '../../attendance/screens/attendance_scan_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqlite_crud_app/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  late SyncService _syncService;
  bool _syncServiceReady = false;

  // Statistics data
  int totalStudents = 0;
  int totalClasses = 0;
  int presentToday = 0;
  int absentToday = 0;
  int lateToday = 0;
  bool isLoading = true;
  bool isSyncing = false;
  String syncStatus = 'Checking sync status...';
  DateTime? lastSyncTime;

  // Connectivity status
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initSyncService();
    _loadDashboardData();
    _checkSyncStatus();
    _initConnectivityStatus();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initSyncService() async {
    final db = await _dbHelper.database;
    setState(() {
      _syncService = SyncService(
        firestore: FirebaseFirestore.instance,
        localDb: db,
      );
      _syncServiceReady = true;
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load basic statistics
      final students = await _dbHelper.getAllStudents();
      final classes = await _dbHelper.getAllClasses();
      final todayAttendance = await _dbHelper.getTodayAttendance();

      // Calculate attendance statistics
      int present = 0, absent = 0, late = 0;
      for (final attendance in todayAttendance) {
        switch (attendance.status) {
          case AttendanceStatus.present:
            present++;
            break;
          case AttendanceStatus.absent:
            absent++;
            break;
          case AttendanceStatus.late:
            late++;
            break;
          case AttendanceStatus.excused:
            // Count as present for statistics
            present++;
            break;
        }
      }

      setState(() {
        totalStudents = students.length;
        totalClasses = classes.length;
        presentToday = present;
        absentToday = absent;
        lateToday = late;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString('last_sync_time');

      if (lastSync != null) {
        lastSyncTime = DateTime.parse(lastSync);
        setState(() {
          syncStatus = 'Last sync: ${_formatDateTime(lastSyncTime!)}';
        });
      } else {
        setState(() {
          syncStatus = 'No sync data available';
        });
      }
    } catch (e) {
      setState(() {
        syncStatus = 'Sync status unavailable';
      });
    }
  }

  Future<void> _performSync() async {
    if (!_syncServiceReady) return;
    setState(() {
      isSyncing = true;
    });
    try {
      await _syncService.syncAllData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
      setState(() {
        lastSyncTime = DateTime.now();
        syncStatus = 'Last sync: Just now';
        isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data synced successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _initConnectivityStatus() async {
    try {
      final status = await ConnectivityService().getConnectivityStatus();
      setState(() {
        _connectivityStatus = status;
        _isOnline = status != ConnectivityResult.none;
      });
    } catch (e) {
      print('Error getting connectivity status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userSession = Provider.of<UserSession>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode
              ? AppColors.scaffoldBackgroundDark
              : AppColors.scaffoldBackground,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          slivers: [
            // Dashboard Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      _buildWelcomeSection(userSession),
                      const SizedBox(height: 24),

                      // Today's Attendance Summary
                      _buildTodayAttendanceSection(),
                      const SizedBox(height: 24),

                      // Statistics Cards
                      _buildStatisticsSection(),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActionsSection(),
                      const SizedBox(height: 24),

                      // Sync Status
                      _buildSyncStatusSection(),
                      const SizedBox(height: 24),

                      // Connectivity Status
                      _buildConnectivityStatus(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(UserSession userSession) {
    final currentTime = DateTime.now();
    final greeting = _getGreeting(currentTime.hour);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary500, AppColors.primary600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.white.withOpacity(0.2),
            child: Icon(Icons.person, size: 35, color: AppColors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userSession.currentUser?.fullName ?? 'User',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: ${userSession.currentUser?.role.value ?? 'User'}',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.school, color: AppColors.white.withOpacity(0.8), size: 40),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              const Text(
                "Today's Attendance",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceStatCard(
                  'Present',
                  presentToday.toString(),
                  AppColors.success,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAttendanceStatCard(
                  'Late',
                  lateToday.toString(),
                  AppColors.warning,
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAttendanceStatCard(
                  'Absent',
                  absentToday.toString(),
                  AppColors.error,
                  Icons.cancel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceScanScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Start Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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

  Widget _buildAttendanceStatCard(
    String label,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
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
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'School Statistics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Students',
              totalStudents.toString(),
              Icons.people,
              AppColors.primary,
            ),
            _buildStatCard(
              'Total Classes',
              totalClasses.toString(),
              Icons.class_,
              AppColors.info,
            ),
            _buildStatCard(
              'Attendance Rate',
              totalStudents > 0
                  ? '${((presentToday / totalStudents) * 100).toStringAsFixed(1)}%'
                  : '0%',
              Icons.analytics,
              AppColors.success,
            ),
            _buildStatCard(
              'Today\'s Date',
              DateFormat('MMM d').format(DateTime.now()),
              Icons.calendar_today,
              AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Icon(Icons.trending_up, color: color.withOpacity(0.5), size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Scan QR',
                Icons.qr_code_scanner,
                AppColors.primary500,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceScanScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Add Student',
                Icons.person_add,
                AppColors.secondary500,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddStudentCardScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'View History',
                Icons.history,
                AppColors.tertiary500,
                () {
                  // Navigate to calendar/history view
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calendar view coming soon!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Settings',
                Icons.settings,
                AppColors.info,
                () {
                  // Navigate to settings
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSyncing ? Icons.sync : Icons.cloud_sync,
                color: isSyncing ? AppColors.warning : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Sync Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (isSyncing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            syncStatus,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSyncing ? null : _performSync,
              icon: Icon(isSyncing ? Icons.sync : Icons.sync_alt),
              label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isOnline ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isOnline ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  _getConnectivityTypeText(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? Colors.green : Colors.red,
            size: 24,
          ),
        ],
      ),
    );
  }

  String _getConnectivityTypeText() {
    switch (_connectivityStatus) {
      case ConnectivityResult.wifi:
        return 'WiFi Connection';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet Connection';
      case ConnectivityResult.none:
        return 'No Internet Connection';
      default:
        return 'Unknown Connection';
    }
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
