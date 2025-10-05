import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/Views/recent/recent_services_grid_screen.dart';
import 'package:sqlite_crud_app/Views/home/screens/calendar_page.dart';
import 'package:sqlite_crud_app/Views/settings/screens/settings_screen.dart';
import 'package:sqlite_crud_app/Views/home/screens/dashboard_screen.dart';
import 'package:sqlite_crud_app/Components/service_action_sheet.dart';
import 'package:sqlite_crud_app/Components/premium_drawer.dart';
import 'package:sqlite_crud_app/Components/premium_app_bar.dart';

/// Premium Navigation Menu with Middle FAB Action Button
class NavigationMenu extends StatelessWidget {
  const NavigationMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigationController = Provider.of<NavigationController>(context);

    return Scaffold(
      drawer: const PremiumDrawer(),
      appBar: PremiumAppBar(
        title: _getAppBarTitle(navigationController.selectedIndex),
        notificationCount: 3, // TODO: Get from notification service
      ),
      body: navigationController.screens[navigationController.selectedIndex],
      floatingActionButton: _buildMiddleActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(context, navigationController),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Recent Records';
      case 2:
        return 'Calendar';
      case 3:
        return 'Settings';
      default:
        return 'XTAP';
    }
  }

  Widget _buildMiddleActionButton(BuildContext context) {
    return Container(
      height: 65,
      width: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary500, AppColors.primary600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          _showServiceActionSheet(context);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  void _showServiceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ServiceActionSheet(),
    );
  }

  Widget _buildBottomNavBar(
    BuildContext context,
    NavigationController controller,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardColorDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                isSelected: controller.selectedIndex == 0,
                onTap: () => controller.setSelectedIndex(0),
              ),
              _buildNavItem(
                context,
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                label: 'Recent',
                index: 1,
                isSelected: controller.selectedIndex == 1,
                onTap: () => controller.setSelectedIndex(1),
              ),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(
                context,
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month,
                label: 'Calendar',
                index: 2,
                isSelected: controller.selectedIndex == 2,
                onTap: () => controller.setSelectedIndex(2),
              ),
              _buildNavItem(
                context,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                index: 3,
                isSelected: controller.selectedIndex == 3,
                onTap: () => controller.setSelectedIndex(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color =
        isSelected
            ? AppColors.primary500
            : isDarkMode
            ? AppColors.textLightDark
            : AppColors.textLight;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: isSelected ? 28 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationController extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  final List<Widget> screens = [
    DashboardScreen(), // Home/Dashboard
    RecentServicesGridScreen(), // Recent records with grid view
    CalendarPage(), // Calendar
    SettingsScreen(), // Settings
  ];
}
