import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 80, color: AppColors.textLight),
          SizedBox(height: 16),
          Text(
            'Payment Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'View and process student payments',
            style: TextStyle(fontSize: 16, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
