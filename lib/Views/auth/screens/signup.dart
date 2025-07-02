import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/Components/button.dart';
import 'package:sqlite_crud_app/Components/textfield.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/models/user.dart';
import 'package:sqlite_crud_app/services/auth_services.dart';

// ============================= CLASS SignupScreen =============================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

// ============================= CLASS _SignupScreenState =============================
class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(); // Changed from email to username
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;
  String _selectedRole = 'user'; // Default role

  // ============================= DISPOSE CONTROLLERS =============================
  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================= HANDLE SIGN UP =============================
  Future<void> _handleSignUp() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = "Please agree to the Terms & Conditions";
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Passwords do not match";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final result = await _authService.signUp(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fullName: fullName,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        role: _selectedRole,
      );

      if (result == null) {
        setState(() {
          _successMessage = "Account created successfully! Please log in.";
        });
        _clearForm();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      } else {
        setState(() {
          _errorMessage = result;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================= CLEAR FORM =============================
  void _clearForm() {
    _usernameController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _agreeToTerms = false;
      _selectedRole = 'user';
    });
  }

  // ============================= VALIDATE EMAIL =============================
  String? _validateEmail(String? value) {
    // Email is optional, so empty is allowed
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ============================= VALIDATE USERNAME =============================
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  // ============================= VALIDATE PASSWORD =============================
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // ============================= BUILD LOGO WIDGET =============================
  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2),
            Color(0xFF3085FE),
            Color(0xFF2E7CE5),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        shape: BoxShape.rectangle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-2, -2),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.rectangle,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(2, 2),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.rectangle,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
            ),
            child: const Icon(
              Icons.diamond,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ============================= BUILD MODERN INPUT FIELD =============================
  Widget _buildModernInputField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    bool obscureText = isPassword && (controller == _passwordController ? _obscurePassword : _obscureConfirmPassword);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textInputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        enabled: !_isLoading,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () {
                    setState(() {
                      if (controller == _passwordController) {
                        _obscurePassword = !_obscurePassword;
                      } else {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      }
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          errorStyle: const TextStyle(height: 0),
        ),
      ),
    );
  }

  // ============================= BUILD ROLE DROPDOWN =============================
  Widget _buildRoleDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textInputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        // enabled: !_isLoading,
        decoration: InputDecoration(
          hintText: 'Select Role',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.primary,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        items: [
          DropdownMenuItem(value: 'user', child: Text('User')),
          DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
          DropdownMenuItem(value: 'admin', child: Text('Admin')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedRole = value ?? 'user';
          });
        },
      ),
    );
  }

  // ============================= BUILD MESSAGE WIDGET =============================
  Widget _buildMessageWidget() {
    if (_errorMessage != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_successMessage != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _successMessage!,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ============================= BUILD MODERN BUTTON =============================
  Widget _buildModernButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Register',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // ============================= BUILD TERMS CHECKBOX =============================
  Widget _buildTermsCheckbox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agreeToTerms,
            onChanged: _isLoading ? null : (value) {
              setState(() {
                _agreeToTerms = value ?? false;
              });
            },
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : () {
                setState(() {
                  _agreeToTerms = !_agreeToTerms;
                });
              },
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================= BUILD LOGIN LINK =============================
  Widget _buildLoginLink() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          GestureDetector(
            onTap: _isLoading ? null : () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(
              'Login',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================= BUILD METHOD =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo
                  _buildLogo(),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Register Account\nto ',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'HR Attendee',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    'Hello there, register to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Username Input (NEW)
                  _buildModernInputField(
                    hint: 'Username',
                    controller: _usernameController,
                    icon: Icons.account_circle_outlined,
                    validator: _validateUsername,
                  ),
                  
                  // First Name Input
                  _buildModernInputField(
                    hint: 'First Name',
                    controller: _firstNameController,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  
                  // Last Name Input
                  _buildModernInputField(
                    hint: 'Last Name',
                    controller: _lastNameController,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                  
                  // Email Input (NOW OPTIONAL)
                  _buildModernInputField(
                    hint: 'Email Address (Optional)',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  
                  // Role Dropdown (NEW)
                  _buildRoleDropdown(),
                  
                  // Password Input
                  _buildModernInputField(
                    hint: 'Password',
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: _validatePassword,
                  ),
                  
                  // Confirm Password Input
                  _buildModernInputField(
                    hint: 'Confirm Password',
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Terms & Conditions Checkbox
                  _buildTermsCheckbox(),
                  
                  // Error/Success Message
                  _buildMessageWidget(),
                  
                  const SizedBox(height: 8),
                  
                  // Register Button
                  _buildModernButton(),
                  
                  // Login Link
                  _buildLoginLink(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}