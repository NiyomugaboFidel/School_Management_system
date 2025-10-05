import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/services/scan_action_manager.dart';
import 'package:sqlite_crud_app/Views/attendance/screens/attendance_scan_screen.dart';
import 'package:sqlite_crud_app/Views/home/screens/attendance_screen.dart';
import 'dart:ui';

/// Premium action sheet for service selection with iOS-style blur
class ServiceActionSheet extends StatelessWidget {
  const ServiceActionSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? AppColors.cardColorDark.withOpacity(0.95)
                  : Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode ? AppColors.textDarkDark : AppColors.textDark,
                ),
              ),
            ),

            // Service Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildServiceCard(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: 'Attendance',
                    color: AppColors.primary500,
                    action: ScanAction.attendance,
                  ),
                  _buildServiceCard(
                    context,
                    icon: Icons.directions_bus,
                    label: 'Bus Tracking',
                    color: AppColors.secondary500,
                    action: ScanAction.busTracking,
                  ),
                  _buildServiceCard(
                    context,
                    icon: Icons.payment,
                    label: 'Payment',
                    color: AppColors.tertiary500,
                    action: ScanAction.payment,
                  ),
                  _buildServiceCard(
                    context,
                    icon: Icons.rule,
                    label: 'Discipline',
                    color: AppColors.warning,
                    action: ScanAction.discipline,
                  ),
                  _buildServiceCard(
                    context,
                    icon: Icons.person_add,
                    label: 'Add Student',
                    color: AppColors.success,
                    action: ScanAction.registration,
                  ),
                  _buildServiceCard(
                    context,
                    icon: Icons.qr_code,
                    label: 'General Scan',
                    color: AppColors.info,
                    action: ScanAction.general,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required ScanAction action,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);

          // Set the scan action context
          ScanActionManager().setAction(action);

          // Navigate based on action type
          if (action == ScanAction.attendance) {
            // Show options: Scan or Manage
            _showAttendanceOptions(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(action.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('$label - Coming soon!')),
                  ],
                ),
                backgroundColor: color,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isDarkMode ? AppColors.textDarkDark : AppColors.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show attendance options dialog
  void _showAttendanceOptions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardColorDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  'Attendance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode
                            ? AppColors.textDarkDark
                            : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose an option',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDarkMode
                            ? AppColors.textLightDark
                            : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Option 1: Scan to Mark Attendance
                _buildOptionCard(
                  context,
                  title: 'Scan Card',
                  subtitle: 'Scan NFC/QR to mark attendance',
                  icon: Icons.qr_code_scanner,
                  color: AppColors.primary500,
                  onTap: () {
                    Navigator.pop(context);
                    ScanActionManager().setAction(ScanAction.attendance);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttendanceScanScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Option 2: View/Manage Attendance
                _buildOptionCard(
                  context,
                  title: 'View & Manage',
                  subtitle: 'View and manage attendance records',
                  icon: Icons.list_alt,
                  color: AppColors.secondary500,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
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
                        fontSize: 13,
                        color:
                            isDarkMode
                                ? AppColors.textLightDark
                                : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
