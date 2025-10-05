import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/models/user.dart';
import 'package:sqlite_crud_app/utils/user_session.dart';
import 'package:sqlite_crud_app/services/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

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
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  late UserSession userSession;
  bool _isChecked = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePin = true;
  String? _errorMessage;

  // Authentication method selection
  AuthMethod _selectedAuthMethod = AuthMethod.usernamePassword;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  // ============================= INIT STATE =============================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userSession = Provider.of<UserSession>(context, listen: false);
      _loadSavedCredentials();
      _checkBiometricAvailability();
    });
  }

  // ============================= DISPOSE CONTROLLERS =============================
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ============================= CHECK BIOMETRIC AVAILABILITY =============================
  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final canGetBiometrics = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      setState(() {
        _biometricAvailable =
            canCheckBiometrics &&
            canGetBiometrics &&
            availableBiometrics.isNotEmpty;
      });

      // Check if biometric is enabled in settings
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      });
    } catch (e) {
      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  // ============================= LOAD SAVED CREDENTIALS =============================
  Future<void> _loadSavedCredentials() async {
    if (_isChecked) {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('saved_username');
      final savedPhone = prefs.getString('saved_phone');

      if (savedUsername != null) {
        _usernameController.text = savedUsername;
      }
      if (savedPhone != null) {
        _phoneController.text = savedPhone;
      }
    }
  }

  // ============================= SAVE CREDENTIALS =============================
  Future<void> _saveCredentials() async {
    if (_isChecked) {
      final prefs = await SharedPreferences.getInstance();
      if (_selectedAuthMethod == AuthMethod.usernamePassword) {
        await prefs.setString(
          'saved_username',
          _usernameController.text.trim(),
        );
      } else if (_selectedAuthMethod == AuthMethod.phonePin) {
        await prefs.setString('saved_phone', _phoneController.text.trim());
      }
    }
  }

  // ============================= HANDLE BIOMETRIC AUTH =============================
  Future<void> _handleBiometricAuth() async {
    if (!_biometricAvailable || !_biometricEnabled) {
      setState(() {
        _errorMessage = 'Biometric authentication not available or not enabled';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access the attendance system',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // For biometric auth, we'll use a default admin user or stored credentials
        final prefs = await SharedPreferences.getInstance();
        final savedUsername = prefs.getString('saved_username') ?? 'admin';
        final savedPassword = prefs.getString('saved_password') ?? 'admin123';

        await _performLogin(savedUsername, savedPassword);
      } else {
        setState(() {
          _errorMessage = 'Biometric authentication failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric authentication error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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

    String username, password;

    if (_selectedAuthMethod == AuthMethod.usernamePassword) {
      username = _usernameController.text.trim();
      password = _passwordController.text;
    } else if (_selectedAuthMethod == AuthMethod.phonePin) {
      username = _phoneController.text.trim();
      password = _pinController.text;
    } else {
      setState(() {
        _errorMessage = "Please select an authentication method";
      });
      return;
    }

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields";
      });
      return;
    }

    await _performLogin(username, password);
  }

  // ============================= PERFORM LOGIN =============================
  Future<void> _performLogin(String username, String password) async {
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
        await _saveCredentials();

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

    // Default users for web testing
    final defaultUsers = {
      'admin': {
        'password': 'admin123',
        'fullName': 'System Administrator',
        'email': 'admin@school.com',
        'role': UserRole.admin,
      },
      'teacher': {
        'password': 'teacher123',
        'fullName': 'John Teacher',
        'email': 'teacher@school.com',
        'role': UserRole.teacher,
      },
      'user': {
        'password': 'user123',
        'fullName': 'Regular User',
        'email': 'user@school.com',
        'role': UserRole.user,
      },
      'fidele': {
        'password': '1234678',
        'fullName': 'Fidele Niyomugabo',
        'email': 'fidele@example.com',
        'role': UserRole.admin,
      },
    };

    final userData = defaultUsers[username];
    if (userData != null && userData['password'] == password) {
      final user = User(
        id: defaultUsers.keys.toList().indexOf(username) + 1,
        fullName: userData['fullName'] as String,
        email: userData['email'] as String,
        username: username,
        password: "***",
        role: userData['role'] as UserRole,
        lastLogin: DateTime.now(),
      );
      return SignInResult.success(user);
    } else {
      return SignInResult.failure(
        "Invalid credentials. Use admin/admin123, teacher/teacher123, user/user123, or fidele/1234678",
      );
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
      child: const Icon(Icons.school, color: Colors.white, size: 40),
    );
  }

  // ============================= BUILD ERROR MESSAGE =============================
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

  // ============================= BUILD AUTH METHOD SELECTOR =============================
  Widget _buildAuthMethodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Login Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAuthMethodOption(
                  AuthMethod.usernamePassword,
                  Icons.person_outline,
                  'Username',
                  'Use username and password',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAuthMethodOption(
                  AuthMethod.phonePin,
                  Icons.phone_outlined,
                  'Phone',
                  'Use phone and PIN',
                ),
              ),
            ],
          ),
          if (_biometricAvailable && _biometricEnabled) ...[
            const SizedBox(height: 12),
            _buildAuthMethodOption(
              AuthMethod.biometric,
              Icons.fingerprint,
              'Biometric',
              'Use fingerprint or face ID',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthMethodOption(
    AuthMethod method,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedAuthMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAuthMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================= BUILD INPUT FIELDS =============================
  Widget _buildInputFields() {
    if (_selectedAuthMethod == AuthMethod.biometric) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_selectedAuthMethod == AuthMethod.usernamePassword) ...[
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
          const SizedBox(height: 16),
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
        ] else if (_selectedAuthMethod == AuthMethod.phonePin) ...[
          _buildModernInputField(
            hint: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernInputField(
            hint: 'PIN (4-6 digits)',
            controller: _pinController,
            icon: Icons.pin_outlined,
            isPassword: true,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your PIN';
              }
              if (value.length < 4 || value.length > 6) {
                return 'PIN must be 4-6 digits';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(),
          ),
        ],
      ],
    );
  }

  // ============================= BUILD MODERN INPUT FIELD =============================
  Widget _buildModernInputField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
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
            isPassword
                ? (isPassword == _obscurePassword
                    ? _obscurePassword
                    : _obscurePin)
                : false,
        keyboardType: keyboardType,
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
                      (isPassword == _obscurePassword
                              ? _obscurePassword
                              : _obscurePin)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isPassword == _obscurePassword) {
                          _obscurePassword = !_obscurePassword;
                        } else {
                          _obscurePin = !_obscurePin;
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

  // ============================= BUILD MODERN BUTTON =============================
  Widget _buildModernButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              _isLoading
                  ? [Colors.grey.shade300, Colors.grey.shade400]
                  : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            _isLoading
                ? null
                : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: ElevatedButton(
        onPressed:
            _isLoading
                ? null
                : (_selectedAuthMethod == AuthMethod.biometric
                    ? _handleBiometricAuth
                    : _handleLogin),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedAuthMethod == AuthMethod.biometric
                          ? Icons.fingerprint
                          : Icons.login,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedAuthMethod == AuthMethod.biometric
                          ? 'Authenticate'
                          : 'Login',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                        _isChecked = value ?? true;
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
          TextButton(
            onPressed:
                _isLoading
                    ? null
                    : () {
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
                          text: 'School System',
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
                    'Fast and secure high school system',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 40),

                  // Auth Method Selector
                  _buildAuthMethodSelector(),

                  const SizedBox(height: 20),

                  // Input Fields
                  _buildInputFields(),

                  // Remember Me & Forgot Password
                  if (_selectedAuthMethod != AuthMethod.biometric)
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
                        'Don\'t have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
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
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
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

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}

// ============================= ENUM AUTH METHOD =============================
enum AuthMethod { usernamePassword, phonePin, biometric }
