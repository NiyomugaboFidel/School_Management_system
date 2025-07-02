import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/SQLite/database_helper_full.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/Views/home/screens/add_student_card_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int totalStudents = 0;
  int presentToday = 0;
  int lateToday = 0;
  int absentToday = 0;
  bool isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadStats();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => isLoading = true);
    try {
      final students = await DatabaseHelper().getAllStudents();
      final attendance = await DatabaseHelper().getTodayAttendance();

      totalStudents = students.length;
      presentToday =
          attendance.where((a) => a.status.value == 'Present').length;
      lateToday = attendance.where((a) => a.status.value == 'Late').length;
      absentToday = attendance.where((a) => a.status.value == 'Absent').length;

      _animationController.forward();
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openAddStudentCardScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => AddStudentCardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary.withOpacity(0.05), Colors.white],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'Loading dashboard...',
                style: TextStyle(color: AppColors.textDark, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.05), Colors.white],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isTablet ? 32 : 20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: isTablet ? 32 : 24),
                  _buildStatsGrid(isTablet),
                  SizedBox(height: isTablet ? 48 : 32),
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                  _buildAttendanceSummary(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final formattedDate = '${_getMonthName(now.month)} ${now.day}, ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            formattedDate,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isTablet) {
    final stats = [
      StatData(
        'Total Students',
        totalStudents,
        Icons.groups_rounded,
        AppColors.primary,
      ),
      StatData(
        'Present',
        presentToday,
        Icons.check_circle_rounded,
        AppColors.success,
      ),
      StatData('Late', lateToday, Icons.schedule_rounded, AppColors.warning),
      StatData('Absent', absentToday, Icons.cancel_rounded, AppColors.error),
    ];

    if (isTablet) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            stats
                .map(
                  (stat) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildEnhancedStatCard(stat),
                    ),
                  ),
                )
                .toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildEnhancedStatCard(stats[0])),
            const SizedBox(width: 16),
            Expanded(child: _buildEnhancedStatCard(stats[1])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildEnhancedStatCard(stats[2])),
            const SizedBox(width: 16),
            Expanded(child: _buildEnhancedStatCard(stats[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard(StatData stat) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, stat.color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: stat.color.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Add navigation or action here
          },
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: stat.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: 24),
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: stat.value),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: stat.color,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  stat.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAddStudentCardScreen,
              icon: const Icon(Icons.nfc_rounded, size: 20),
              label: const Text('Add Student Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    final total = presentToday + lateToday + absentToday;
    final attendanceRate = total > 0 ? (presentToday / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Today\'s Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$attendanceRate%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? presentToday / total : 0,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            total > 0
                ? '$presentToday out of $total students are present today'
                : 'No attendance data for today',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDark.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

class StatData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  StatData(this.title, this.value, this.icon, this.color);
}
