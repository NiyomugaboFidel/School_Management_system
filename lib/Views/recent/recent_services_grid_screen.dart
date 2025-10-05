import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/Views/recent/recent_records_screen.dart';

/// Premium Recent page with grid view of service cards
class RecentServicesGridScreen extends StatefulWidget {
  const RecentServicesGridScreen({Key? key}) : super(key: key);

  @override
  State<RecentServicesGridScreen> createState() =>
      _RecentServicesGridScreenState();
}

class _RecentServicesGridScreenState extends State<RecentServicesGridScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<ServiceCard> services = [
    ServiceCard(
      title: 'Attendance',
      icon: Icons.how_to_reg,
      color: AppColors.primary500,
      route: '/attendance-records',
    ),
    ServiceCard(
      title: 'Bus Tracking',
      icon: Icons.directions_bus,
      color: AppColors.secondary500,
      route: '/bus-records',
    ),
    ServiceCard(
      title: 'Payments',
      icon: Icons.payment,
      color: AppColors.tertiary500,
      route: '/payment-records',
    ),
    ServiceCard(
      title: 'Discipline',
      icon: Icons.rule,
      color: AppColors.warning,
      route: '/discipline-records',
    ),
    ServiceCard(
      title: 'Students',
      icon: Icons.people,
      color: AppColors.info,
      route: '/student-records',
    ),
    ServiceCard(
      title: 'Reports',
      icon: Icons.assessment,
      color: AppColors.success,
      route: '/reports',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode
              ? AppColors.scaffoldBackgroundDark
              : AppColors.scaffoldBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Service Grid (no duplicate title since it's in AppBar)
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Service Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final delay = index * 0.1;
                    final animationValue = Curves.easeOut.transform(
                      (_animationController.value - delay).clamp(0.0, 1.0),
                    );

                    return Transform.scale(
                      scale: animationValue,
                      child: Opacity(
                        opacity: animationValue,
                        child: _buildServiceCard(context, services[index]),
                      ),
                    );
                  },
                );
              }, childCount: services.length),
            ),
          ),

          // Recent Activity Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDarkMode
                              ? AppColors.textDarkDark
                              : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickAccessCard(
                    context,
                    icon: Icons.history,
                    title: 'Today\'s Attendance',
                    subtitle: 'View all attendance records from today',
                    color: AppColors.primary500,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecentRecordsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildQuickAccessCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Select Date',
                    subtitle: 'Browse records by date',
                    color: AppColors.secondary500,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecentRecordsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceCard service) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate based on service
          if (service.title == 'Attendance') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecentRecordsScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${service.title} records coming soon!'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardColorDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: service.color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [service.color, service.color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: service.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(service.icon, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Service Title
              Text(
                service.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isDarkMode ? AppColors.textDarkDark : AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                'View Records',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDarkMode
                          ? AppColors.textLightDark
                          : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardColorDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDarkMode
                                ? AppColors.textDarkDark
                                : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDarkMode
                                ? AppColors.textLightDark
                                : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.white24 : Colors.black12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceCard {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  ServiceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}
