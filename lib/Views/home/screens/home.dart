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

// Remove inline mock data classes and use shared models if needed

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _loadUserSessionAndTimes();
    _animationController.forward();
  }

  Future<void> _loadUserSessionAndTimes() async {
    setState(() => isLoading = true);
    await UserSession().initialize();
    final prefs = await SharedPreferences.getInstance();
    final checkInString = prefs.getString(_checkInKey);
    final checkOutString = prefs.getString(_checkOutKey);
    setState(() {
      currentUser = UserSession().currentUser;
      checkInTime =
          checkInString != null ? DateTime.tryParse(checkInString) : null;
      checkOutTime =
          checkOutString != null ? DateTime.tryParse(checkOutString) : null;
      isLoading = false;
    });
  }

  Future<void> _handleCheckAction(bool isCheckIn) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (isCheckIn) {
        checkInTime = DateTime.now();
        isCheckedIn = true;
        checkOutTime = null; // Reset checkout on new checkin
        prefs.setString(_checkInKey, checkInTime!.toIso8601String());
        prefs.remove(_checkOutKey);
      } else {
        checkOutTime = DateTime.now();
        isCheckedIn = false;
        prefs.setString(_checkOutKey, checkOutTime!.toIso8601String());
      }
    });
    HapticFeedback.lightImpact();
    final action = isCheckIn ? 'Check In' : 'Check Out';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action successful!'),
        backgroundColor: isCheckIn ? AppColors.success : AppColors.error,
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

  Widget _buildHomeScreen() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final actions = [
      {
        'title': 'Check In',
        'icon': Icons.login,
        'color': AppColors.success,
        'isCheckIn': true,
      },
      {
        'title': 'Check Out',
        'icon': Icons.logout,
        'color': AppColors.error,
        'isCheckIn': false,
      },
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            QuickActions(
              actions: actions,
              onActionTap: (isCheckIn) => _handleCheckAction(isCheckIn),
            ),
            const SizedBox(height: 20),
            TodayActivity(
              checkInTime: checkInTime,
              checkOutTime: checkOutTime,
              sessionDuration: _getSessionDuration(),
              userName: currentUser?.displayName ?? 'User',
            ),
            const SizedBox(height: 20),
            _buildStatisticsCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  currentUser?.fullName != null &&
                          currentUser!.fullName!.isNotEmpty
                      ? currentUser!.fullName!
                          .split(' ')
                          .map((e) => e[0])
                          .join('')
                      : (currentUser?.username.isNotEmpty == true
                          ? currentUser!.username[0].toUpperCase()
                          : 'U'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      currentUser?.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUser?.role.value ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidgets = [
      _buildHomeScreen(),
      AttendanceScreen(),
      const DisciplineScreen(),
      const PaymentScreen(),
      const DashboardScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldWithBoxBackground,
      appBar: AppBar(
        title: Text(
          navItems[currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications feature coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
        ],
      ),
      body: screenWidgets[currentIndex],
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
}
