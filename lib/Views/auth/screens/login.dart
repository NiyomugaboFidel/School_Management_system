import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/models/user.dart';
import 'package:sqlite_crud_app/utils/user_session.dart';
import 'package:sqlite_crud_app/services/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================= CLASS LoginScreen =============================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// ============================= CLASS _LoginScreenState =============================
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  late UserSession userSession;
  bool _isChecked = true;
  bool _isLoading = false;
  bool _obscurePassword = true; // Added for password visibility toggle
  String? _errorMessage;

  // ============================= INIT STATE =============================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userSession = Provider.of<UserSession>(context, listen: false);
      _loadSavedCredentials();
    });
  }

  // ============================= DISPOSE CONTROLLERS =============================
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================= LOAD SAVED CREDENTIALS =============================
  Future<void> _loadSavedCredentials() async {
    if (_isChecked) {
      // TODO: Implement loading saved credentials
    }
  }

  // ============================= SAVE CREDENTIALS =============================
  Future<void> _saveCredentials() async {
    if (_isChecked) {
      // TODO: Implement saving credentials
    }
  }

  // ============================= HANDLE LOGIN =============================
  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SignInResult result;

      if (kIsWeb) {
        result = await _handleWebLogin(username, password);
      } else {
        result = await _authService.signIn(username, password);
      }

      if (result.success && result.user != null) {
        if (_isChecked) {
          await _saveCredentials();
        }

        await userSession.setCurrentUser(result.user!, rememberMe: _isChecked);

        // ✅ Persist login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _errorMessage = result.error ?? "Login failed";
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

  // ============================= HANDLE WEB LOGIN =============================
  Future<SignInResult> _handleWebLogin(String username, String password) async {
    print("Web login attempt: $username, $password");
    if (username == "fidele" || password == "1234678") {
      // Fixed logic error
      final user = User(
        id: 1,
        fullName: "Fidele Niyomugabo",
        email: "fidele@example.com",
        username: "fidele",
        password: "***",
        role: UserRole.admin,
        lastLogin: DateTime.now(),
      );
      return SignInResult.success(user);
    } else {
      return SignInResult.failure("Invalid credentials");
    }
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
          colors: [Color(0xFF4A90E2), Color(0xFF3085FE), Color(0xFF2E7CE5)],
          stops: [0.0, 0.5, 1.0],
        ),
        shape: BoxShape.rectangle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Create the geometric cube effect
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

  // ============================= BUILD ERROR MESSAGE WIDGET =============================
  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

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
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
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
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textInputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText:
            isPassword ? _obscurePassword : false, // Fixed to use state
        validator: validator,
        enabled: !_isLoading,
        onFieldSubmitted: onFieldSubmitted,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility, // Fixed icon
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword; // Toggle visibility
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

  // ============================= BUILD MODERN BUTTON =============================
  Widget _buildModernButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
      ),
    );
  }

  // ============================= BUILD REMEMBER ME CHECKBOX =============================
  Widget _buildRememberMeCheckbox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: _isChecked,
            onChanged:
                _isLoading
                    ? null
                    : (value) {
                      setState(() {
                        _isChecked = true;
                      });
                    },
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap:
                _isLoading
                    ? null
                    : () {
                      setState(() {
                        _isChecked = !_isChecked;
                      });
                    },
            child: Text(
              'Remember me',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
          const Spacer(),
          // Forgot Password
          TextButton(
            onPressed:
                _isLoading
                    ? null
                    : () {
                      // Handle forgot password
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Forgot password feature coming soon!'),
                        ),
                      );
                    },
            child: const Text(
              'Forgot Password ?',
              style: TextStyle(color: AppColors.primary, fontSize: 14),
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
                  const SizedBox(height: 60),

                  // Logo
                  _buildLogo(),

                  const SizedBox(height: 40),

                  // Welcome Text
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Welcome Back ',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(text: '👋', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'to ',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'Hello there, login to continue',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 50),

                  // Username Input
                  _buildModernInputField(
                    hint: 'Username',
                    controller: _usernameController,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),

                  // Password Input
                  _buildModernInputField(
                    hint: 'Password',
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),

                  // Remember Me & Forgot Password
                  _buildRememberMeCheckbox(),

                  const SizedBox(height: 20),

                  // Error Message
                  _buildErrorMessage(),

                  // Login Button
                  _buildModernButton(),

                  const SizedBox(height: 30),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't have an account? ",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                  Navigator.pushNamed(context, '/signup');
                                },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
