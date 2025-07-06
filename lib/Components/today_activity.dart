import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/Components/activity_item.dart';

class TodayActivity extends StatelessWidget {
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String sessionDuration;
  final String userName;

  const TodayActivity({
    Key? key,
    required this.checkInTime,
    required this.checkOutTime,
    required this.sessionDuration,
    required this.userName,
  }) : super(key: key);

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Today\'s Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.scaffoldWithBoxBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ActivityItem(
                    title: 'Check In',
                    value: _formatTime(checkInTime),
                    icon: Icons.login,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 20),
                  ActivityItem(
                    title: 'Check Out',
                    value: _formatTime(checkOutTime),
                    icon: Icons.logout,
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ActivityItem(
                    title: 'Session Duration',
                    value: sessionDuration,
                    icon: Icons.timer,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 20),
                  ActivityItem(
                    title: 'User',
                    value: userName,
                    icon: Icons.person,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
