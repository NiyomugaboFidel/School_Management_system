import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/services/scan_action_manager.dart';
import 'package:sqlite_crud_app/Views/attendance/screens/attendance_scan_screen.dart';
import 'package:sqlite_crud_app/Views/home/screens/attendance_screen.dart';
import 'dart:ui';

/// Reusable service options dialog for Scan or Manage
class ServiceOptionsDialog {
  /// Show attendance options (Scan or Manage)
  static void showAttendanceOptions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? AppColors.cardColorDark.withOpacity(0.95)
                        : Colors.white.withOpacity(0.95),
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
          ),
    );
  }

  /// Show payment options (Scan or Manage) - Coming Soon
  static void showPaymentOptions(BuildContext context) {
    _showComingSoonDialog(
      context,
      'Payment',
      Icons.payment,
      AppColors.tertiary500,
    );
  }

  /// Show bus tracking options (Scan or Manage) - Coming Soon
  static void showBusTrackingOptions(BuildContext context) {
    _showComingSoonDialog(
      context,
      'Bus Tracking',
      Icons.directions_bus,
      AppColors.secondary500,
    );
  }

  /// Show discipline options (Scan or Manage) - Coming Soon
  static void showDisciplineOptions(BuildContext context) {
    _showComingSoonDialog(context, 'Discipline', Icons.rule, AppColors.warning);
  }

  /// Generic coming soon dialog for services not yet implemented
  static void _showComingSoonDialog(
    BuildContext context,
    String serviceName,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? AppColors.cardColorDark.withOpacity(0.95)
                        : Colors.white.withOpacity(0.95),
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

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 48),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    serviceName,
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
                    'Coming soon!',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          isDarkMode
                              ? AppColors.textLightDark
                              : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This feature is under development',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDarkMode
                              ? AppColors.textLightDark.withOpacity(0.7)
                              : AppColors.textLight.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  /// Build option card
  static Widget _buildOptionCard(
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
