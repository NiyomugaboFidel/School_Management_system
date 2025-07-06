import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/utils/user_session.dart';
import 'package:sqlite_crud_app/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite_crud_app/Views/home/screens/attendance_screen.dart';
import 'package:sqlite_crud_app/Views/home/screens/discipline_screen.dart';
import 'package:sqlite_crud_app/Views/home/screens/payment_screen.dart';
import 'package:sqlite_crud_app/Views/home/screens/dashboard_screen.dart';
import 'package:sqlite_crud_app/Components/quick_actions.dart';
import 'package:sqlite_crud_app/Components/today_activity.dart';
import 'package:sqlite_crud_app/Views/attendance/screens/attendance_scan_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../SQLite/database_helper.dart';
import 'add_student_card_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _animationController;
  late AnimationController _checkInController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  User? currentUser;
  DateTime? checkInTime;
  DateTime? checkOutTime;
  bool isCheckedIn = false;
  bool isLoading = true;

  static const String _checkInKey = 'user_check_in_time';
  static const String _checkOutKey = 'user_check_out_time';

  final List<String> navItems = [
    'Home',
    'Attendance',
    'Discipline',
    'Payment',
    'Dashboard',
  ];

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Statistics data
  int totalStudents = 0;
  int presentToday = 0;
  int absentToday = 0;
  int totalClasses = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _checkInController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _checkInController, curve: Curves.elasticOut),
    );
    _checkAndLoadUserSession();
    _loadDashboardData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _checkInController.dispose();
    super.dispose();
  }

  Future<void> _checkAndLoadUserSession() async {
    setState(() => isLoading = true);
    await UserSession().initialize();
    final user = UserSession().currentUser;
    final isValid = UserSession().isSessionValid && user != null;
    if (!isValid) {
      await UserSession().logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final checkInString = prefs.getString(_checkInKey);
    final checkOutString = prefs.getString(_checkOutKey);

    // Check if user is currently checked in
    final today = DateTime.now();
    final checkInDate =
        checkInString != null ? DateTime.tryParse(checkInString) : null;
    final checkOutDate =
        checkOutString != null ? DateTime.tryParse(checkOutString) : null;

    bool userIsCheckedIn = false;
    if (checkInDate != null) {
      // If there's a check-in time and it's from today
      if (checkInDate.day == today.day &&
          checkInDate.month == today.month &&
          checkInDate.year == today.year) {
        // If there's no check-out time, or check-out is from a different day, user is checked in
        if (checkOutDate == null || checkOutDate.isBefore(checkInDate)) {
          userIsCheckedIn = true;
        }
      }
    }

    setState(() {
      currentUser = user;
      checkInTime = checkInDate;
      checkOutTime = checkOutDate;
      isCheckedIn = userIsCheckedIn;
      isLoading = false;
    });
  }

  Future<void> _handleCheckAction(bool isCheckIn) async {
    _checkInController.forward().then((_) => _checkInController.reverse());

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    setState(() {
      if (isCheckIn) {
        checkInTime = now;
        isCheckedIn = true;
        checkOutTime = null;
        prefs.setString(_checkInKey, checkInTime!.toIso8601String());
        prefs.remove(_checkOutKey);
      } else {
        checkOutTime = now;
        isCheckedIn = false;
        prefs.setString(_checkOutKey, checkOutTime!.toIso8601String());
      }
    });

    HapticFeedback.lightImpact();
    final action = isCheckIn ? 'Check In' : 'Check Out';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isCheckIn ? Icons.login : Icons.logout, color: Colors.white),
            const SizedBox(width: 8),
            Text('$action successful at ${DateFormat('HH:mm').format(now)}'),
          ],
        ),
        backgroundColor: isCheckIn ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getSessionDuration() {
    if (checkInTime == null) return '--:--';
    final end = checkOutTime ?? DateTime.now();
    final duration = end.difference(checkInTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDashboardData() async {
    try {
      final students = await _dbHelper.getAllStudents();
      final classes = await _dbHelper.getAllClasses();

      setState(() {
        totalStudents = students.length;
        totalClasses = classes.length;
        presentToday = 0; // TODO: Implement today's attendance
        absentToday = 0; // TODO: Implement today's attendance
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _getCurrentScreen() {
    switch (currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return AttendanceScreen();
      case 2:
        return const DisciplineScreen();
      case 3:
        return const PaymentScreen();
      case 4:
        return const DashboardScreen();
      default:
        return _buildHomeContent();
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
      appBar: currentIndex == 4 ? _buildDashboardAppBar() : _buildHomeAppBar(),
      body: _getCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rule),
              label: 'Discipline',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment),
              label: 'Payment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHomeAppBar() {
    return AppBar(
      title: Text(
        navItems[currentIndex],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      centerTitle: false,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/settings');
          },
          icon: const Icon(Icons.notifications_outlined),
        ),

        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search feature coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.search),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/settings');
          },
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildDashboardAppBar() {
    return AppBar(
      title: const Text(
        'Analytics Dashboard',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      centerTitle: false,
      backgroundColor: AppColors.primary500,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Advanced analytics coming soon!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export data feature coming soon!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.sync),
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Refreshing dashboard...')),
            );
            await _loadDashboardData();
          },
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    final userSession = Provider.of<UserSession>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        await _checkAndLoadUserSession();
        await _loadDashboardData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome & Check-in Section
                _buildWelcomeSection(userSession),
                const SizedBox(height: 24),

                // Check-in/Check-out Card
                _buildCheckInOutCard(),
                const SizedBox(height: 24),

                // Quick Statistics
                _buildQuickStats(),
                const SizedBox(height: 24),

                // Today's Activity
                _buildTodayActivity(),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(UserSession userSession) {
    final currentTime = DateTime.now();
    final greeting = _getGreeting(currentTime.hour);
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(currentTime);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary500, AppColors.primary600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userSession.currentUser?.fullName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInOutCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work Session',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCheckedIn ? 'Active Session' : 'Not Started',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isCheckedIn ? AppColors.success : AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isCheckedIn ? AppColors.success : AppColors.textLight)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getSessionDuration(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isCheckedIn ? AppColors.success : AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (checkInTime != null) ...[
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.login, color: AppColors.success, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        'Check In',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('HH:mm').format(checkInTime!),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (checkOutTime != null) ...[
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.logout, color: AppColors.warning, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        'Check Out',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('HH:mm').format(checkOutTime!),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleCheckAction(!isCheckedIn),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCheckedIn ? AppColors.warning : AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isCheckedIn ? Icons.logout : Icons.login, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isCheckedIn ? 'Check Out' : 'Check In',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.people,
                  totalStudents.toString(),
                  'Students',
                  AppColors.primary500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  Icons.class_,
                  totalClasses.toString(),
                  'Classes',
                  AppColors.secondary500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            Icons.access_time,
            'Session Duration',
            _getSessionDuration(),
            AppColors.info,
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            Icons.check_circle,
            'Status',
            isCheckedIn ? 'Active' : 'Inactive',
            isCheckedIn ? AppColors.success : AppColors.textLight,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                'Payments',
                Icons.payment,
                AppColors.tertiary500,
                () => setState(() => currentIndex = 3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Analytics',
                Icons.analytics,
                AppColors.info,
                () => setState(() => currentIndex = 4),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
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

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
