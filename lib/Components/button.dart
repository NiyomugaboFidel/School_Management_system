import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';

class Button extends StatelessWidget {
  final String label;
  final VoidCallback? press;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double height;

  const Button({
    super.key,
    required this.label,
    required this.press,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height = 55,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final bool isDisabled = press == null || isLoading;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: width ?? size.width * .9,
      height: height,
      decoration: BoxDecoration(
        color: isDisabled
            ? Colors.grey.shade300
            : (backgroundColor ?? AppColors.primary),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: (backgroundColor ?? AppColors.primary).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: TextButton(
        onPressed: isDisabled ? null : press,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.grey.shade600
                          : (textColor ?? Colors.white),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}