// ====================================================================
// QUICK ACTIONS USAGE EXAMPLE
// ====================================================================
// This file shows how to use the new QuickActions widget and
// ServiceOptionsDialog in your screens.
// ====================================================================

import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/Components/quick_actions.dart';
import 'package:sqlite_crud_app/Components/service_options_dialog.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/Views/home/screens/add_student_card_screen.dart';

// Example 1: Using QuickActions Widget
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Actions Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Use the QuickActions widget with predefined service types
            QuickActions(
              actions: [
                // Attendance - Will automatically show Scan/Manage options
                QuickActionItem(
                  title: 'Attendance',
                  icon: Icons.qr_code_scanner,
                  color: AppColors.primary500,
                  type: QuickActionType.attendance,
                  // No onTap needed - handled automatically!
                ),

                // Payment - Will show "Coming Soon" dialog
                QuickActionItem(
                  title: 'Payment',
                  icon: Icons.payment,
                  color: AppColors.tertiary500,
                  type: QuickActionType.payment,
                ),

                // Bus Tracking - Will show "Coming Soon" dialog
                QuickActionItem(
                  title: 'Bus Tracking',
                  icon: Icons.directions_bus,
                  color: AppColors.secondary500,
                  type: QuickActionType.busTracking,
                ),

                // Discipline - Will show "Coming Soon" dialog
                QuickActionItem(
                  title: 'Discipline',
                  icon: Icons.rule,
                  color: AppColors.warning,
                  type: QuickActionType.discipline,
                ),

                // Custom action with your own callback
                QuickActionItem(
                  title: 'Add Student',
                  icon: Icons.person_add,
                  color: AppColors.success,
                  type: QuickActionType.custom,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddStudentCardScreen(),
                      ),
                    );
                  },
                ),

                // Settings with custom navigation
                QuickActionItem(
                  title: 'Settings',
                  icon: Icons.settings,
                  color: AppColors.info,
                  type: QuickActionType.custom,
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Example 2: Using ServiceOptionsDialog directly (without QuickActions widget)
class DirectUsageExample extends StatelessWidget {
  const DirectUsageExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Direct Dialog Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Show attendance options dialog directly
                ServiceOptionsDialog.showAttendanceOptions(context);
              },
              child: const Text('Show Attendance Options'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Show payment options (coming soon dialog)
                ServiceOptionsDialog.showPaymentOptions(context);
              },
              child: const Text('Show Payment Options'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Show bus tracking options (coming soon dialog)
                ServiceOptionsDialog.showBusTrackingOptions(context);
              },
              child: const Text('Show Bus Tracking Options'),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// KEY FEATURES:
// ====================================================================
// ✅ Automatic handling of Scan/Manage options for services
// ✅ Beautiful iOS-style blur effects and animations
// ✅ Dark mode support built-in
// ✅ Reusable across your entire app
// ✅ Consistent UI/UX for all services
// ✅ Easy to extend for new services
//
// WHEN TO USE WHICH:
// - Use QuickActions widget: When you want a grid of action cards
// - Use ServiceOptionsDialog directly: When you want to trigger from buttons
// ====================================================================
