import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/Components/action_button.dart';

class QuickActions extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final void Function(bool isCheckIn) onActionTap;

  const QuickActions({
    Key? key,
    required this.actions,
    required this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 12),
        Row(
          children:
              actions.map((action) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: action == actions.last ? 0 : 8,
                    ),
                    child: ActionButton(
                      title: action['title'] as String,
                      icon: action['icon'] as IconData,
                      color: action['color'] as Color,
                      onTap: () => onActionTap(action['isCheckIn'] as bool),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
