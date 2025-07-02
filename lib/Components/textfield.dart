import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';


class InputField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool passwordInvisible;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final void Function(String)? onFieldSubmitted;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  const InputField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.passwordInvisible = false,
    this.validator,
    this.enabled = true,
    this.onFieldSubmitted,
    this.keyboardType,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscureText = true;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.passwordInvisible;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 6),
      width: size.width * .9,
      decoration: BoxDecoration(
        color: widget.enabled ? AppColors.textInputBackground : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isFocused 
              ? AppColors.primary
              : widget.enabled 
                  ? Colors.transparent 
                  : Colors.grey.shade300,
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.passwordInvisible ? _obscureText : false,
        validator: widget.validator,
        enabled: widget.enabled,
        onFieldSubmitted: widget.onFieldSubmitted,
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        textCapitalization: widget.textCapitalization,
        style: TextStyle(
          color: widget.enabled ? Colors.black : Colors.grey.shade600,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          icon: Icon(
            widget.icon,
            color: _isFocused ? AppColors.primary: Colors.grey.shade600,
          ),
          suffixIcon: widget.passwordInvisible
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: widget.enabled ? _togglePasswordVisibility : null,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          counterText: '', // Hide character counter
          errorStyle: const TextStyle(height: 0), // Hide error text since we handle it elsewhere
        ),
      ),
    );
  }
}