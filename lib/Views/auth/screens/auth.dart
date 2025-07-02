import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/Components/button.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Authentication",
                style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const Text(
                "Authenticate to access your vital information",
                style: TextStyle(color: Colors.grey),
              ),
              Expanded(child: Image.asset("assets/startup.jpg",
               height: 400,
                          width: 400,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 400,
                              width: 400,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.school,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ),
              ),
              Button(label: "LOGIN", press: () {
                Navigator.pushNamed(context, '/login');
              }),
              Button(label: "SIGN UP", press: () {
                Navigator.pushNamed(context, '/signup');
              }),
            ],
          ),
        ),
      )),
    );
  }
}
