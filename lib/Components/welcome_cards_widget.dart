import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../utils/user_session.dart';

class WelcomeCardsWidget extends StatefulWidget {
  final UserSession userSession;

  const WelcomeCardsWidget({Key? key, required this.userSession})
    : super(key: key);

  @override
  State<WelcomeCardsWidget> createState() => _WelcomeCardsWidgetState();
}

class _WelcomeCardsWidgetState extends State<WelcomeCardsWidget> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < 4) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return DateFormat('HH:mm').format(now);
  }

  String _getWeatherStatus() {
    // You can integrate with weather API here
    return 'Sunny';
  }

  // Base card container for consistent sizing
  Widget _buildBaseCard({
    required Widget child,
    required IconData headerIcon,
    required String headerTitle,
    String? headerSubtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      height: 260,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.primary500, width: 1.5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary500.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(headerIcon, color: AppColors.primary500, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      headerTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (headerSubtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        headerSubtitle,
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary500.withOpacity(0.05),
        border: Border.all(
          color: AppColors.primary500.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary500, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    IconData icon,
    Color? color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary500).withOpacity(0.05),
          border: Border.all(
            color: (color ?? AppColors.primary500).withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? AppColors.primary500, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.primary500.withOpacity(0.02),
        border: Border.all(
          color: AppColors.primary500.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary500, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary500.withOpacity(0.05),
          border: Border.all(
            color: AppColors.primary500.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary500, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(now);
    final username = widget.userSession.currentUser?.username ?? 'User';

    return _buildBaseCard(
      headerIcon: Icons.waving_hand,
      headerTitle: greeting,
      headerSubtitle: username.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Time Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary500.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary500.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.primary500,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.access_time,
                        _getCurrentTime(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.wb_sunny,
                        _getWeatherStatus(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Welcome Message
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary500.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary500.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to start your productive day?',
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.7),
                      fontSize: 11,
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

  Widget _buildSystemInfoCard() {
    return _buildBaseCard(
      headerIcon: Icons.monitor_outlined,
      headerTitle: 'System Status',
      headerSubtitle: 'Real-time monitoring',
      child: Column(
        children: [
          // System Stats
          Row(
            children: [
              _buildStatBox('CPU', '35%', Icons.memory, Colors.blue),
              const SizedBox(width: 10),
              _buildStatBox('RAM', '4.2GB', Icons.storage, Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          // Storage Info
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary500.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary500.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Storage Usage',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: AppColors.primary500.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '256 GB / 512 GB',
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.7),
                      fontSize: 10,
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

  Widget _buildStatsCard() {
    return _buildBaseCard(
      headerIcon: Icons.analytics_outlined,
      headerTitle: 'Quick Stats',
      headerSubtitle: 'Today\'s overview',
      child: Column(
        children: [
          Row(
            children: [
              _buildStatBox('Users', '1,234', Icons.people, Colors.purple),
              const SizedBox(width: 10),
              _buildStatBox('Tasks', '42', Icons.task_alt, Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBox('Alerts', '7', Icons.notifications, Colors.red),
              const SizedBox(width: 10),
              _buildStatBox('Messages', '23', Icons.message, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return _buildBaseCard(
      headerIcon: Icons.timeline,
      headerTitle: 'Recent Activity',
      headerSubtitle: 'Latest updates',
      child: Column(
        children: [
          _buildListItem(Icons.login, 'User Login', '2 minutes ago'),
          _buildListItem(Icons.edit, 'Document Updated', '15 minutes ago'),
          _buildListItem(Icons.mail, 'New Message Received', '1 hour ago'),
          // _buildListItem(Icons.cloud_upload, 'File Uploaded', '2 hours ago'),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return _buildBaseCard(
      headerIcon: Icons.dashboard,
      headerTitle: 'Quick Actions',
      headerSubtitle: 'Frequently used',
      child: Column(
        children: [
          Row(
            children: [
              _buildActionButton('Add Task', Icons.add_task),
              const SizedBox(width: 10),
              _buildActionButton('Settings', Icons.settings),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton('Reports', Icons.assessment),
              const SizedBox(width: 10),
              _buildActionButton('Profile', Icons.person),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildWelcomeCard(),
              _buildSystemInfoCard(),
              _buildStatsCard(),
              _buildActivityCard(),
              _buildQuickActionsCard(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentPage == index ? 20 : 6,
              decoration: BoxDecoration(
                color:
                    _currentPage == index
                        ? AppColors.primary500
                        : AppColors.primary500.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
