import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/Components/service_options_dialog.dart';

enum QuickActionType {
  attendance,
  payment,
  busTracking,
  discipline,
  addStudent,
  viewHistory,
  settings,
  custom,
}

class QuickActions extends StatelessWidget {
  final List<QuickActionItem> actions;

  const QuickActions({Key? key, required this.actions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textDarkDark : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              actions.map((action) {
                return _buildActionCard(context, action, isDarkMode);
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    QuickActionItem action,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: () => _handleActionTap(context, action),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [action.color, action.color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: action.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              action.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleActionTap(BuildContext context, QuickActionItem action) {
    // If custom callback is provided, use it
    if (action.onTap != null) {
      action.onTap!();
      return;
    }

    // Otherwise, show service options dialog based on type
    switch (action.type) {
      case QuickActionType.attendance:
        ServiceOptionsDialog.showAttendanceOptions(context);
        break;
      case QuickActionType.payment:
        ServiceOptionsDialog.showPaymentOptions(context);
        break;
      case QuickActionType.busTracking:
        ServiceOptionsDialog.showBusTrackingOptions(context);
        break;
      case QuickActionType.discipline:
        ServiceOptionsDialog.showDisciplineOptions(context);
        break;
      case QuickActionType.addStudent:
      case QuickActionType.viewHistory:
      case QuickActionType.settings:
      case QuickActionType.custom:
        // For these, a custom callback should be provided
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action.title} - Please provide a custom handler'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        break;
    }
  }
}

/// Quick action item model
class QuickActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final QuickActionType type;
  final VoidCallback? onTap; // Optional custom callback

  const QuickActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.type,
    this.onTap,
  });
}
