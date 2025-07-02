import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqlite_crud_app/utils/user_session.dart';
import 'package:sqlite_crud_app/models/user.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<UserSession>(
        builder: (context, userSession, child) {
          final user = userSession.currentUser;

          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No user data available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernSliverAppBar(context, user, userSession),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildProfileContent(context, user, userSession),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernSliverAppBar(
    BuildContext context,
    User user,
    UserSession userSession,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getRoleColor(user.role),
                _getRoleColor(user.role).withOpacity(0.8),
                _getRoleColor(user.role).withOpacity(0.6),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated background pattern
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CirclePatternPainter(_pulseAnimation.value),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: _buildEnhancedProfileAvatar(user),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRoleIcon(user.role),
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getRoleDisplayName(user.role),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () => _showModernSettingsDialog(context, userSession),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedProfileAvatar(User user) {
    return Hero(
      tag: 'profile_avatar',
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: _getRoleColor(user.role).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 58,
                backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                child: Text(
                  UserSession().userInitials,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getRoleColor(user.role),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    User user,
    UserSession userSession,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModernInfoCard(user, userSession),
          const SizedBox(height: 20),
          _buildModernSessionCard(userSession),
          const SizedBox(height: 20),
          _buildQuickActions(context, userSession),
          const SizedBox(height: 20),
          _buildModernActionButtons(context, userSession),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard(User user, UserSession userSession) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: _getRoleColor(user.role),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildModernInfoRow(Icons.badge_rounded, 'Username', user.username),
            _buildModernInfoRow(
              Icons.person_outline_rounded,
              'Full Name',
              user.fullName ?? 'Not provided',
            ),
            _buildModernInfoRow(
              Icons.email_rounded,
              'Email',
              user.email ?? 'Not provided',
            ),
            _buildModernInfoRow(
              Icons.security_rounded,
              'Role',
              _getRoleDisplayName(user.role),
            ),
            _buildModernInfoRow(
              Icons.schedule_rounded,
              'Last Login',
              user.formattedLastLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSessionCard(UserSession userSession) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.timer_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Session Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildModernInfoRow(
              Icons.access_time_rounded,
              'Session Duration',
              userSession.formattedSessionDuration,
            ),
            _buildModernInfoRow(
              Icons.timer_off_rounded,
              'Remaining Time',
              userSession.formattedRemainingTime,
              valueColor:
                  userSession.remainingSessionTime != null &&
                          userSession.remainingSessionTime!.inMinutes < 5
                      ? Colors.red
                      : Colors.green,
            ),
            _buildModernInfoRow(
              Icons.login_rounded,
              'Session Started',
              userSession.formattedSessionStartTime,
            ),
            FutureBuilder<bool>(
              future: userSession.isRememberMeEnabled,
              builder: (context, snapshot) {
                return _buildModernInfoRow(
                  Icons.memory_rounded,
                  'Remember Me',
                  snapshot.data == true ? 'Enabled' : 'Disabled',
                  valueColor: snapshot.data == true ? Colors.blue : Colors.grey,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserSession userSession) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionItem(
                    Icons.edit_rounded,
                    'Edit Profile',
                    Colors.blue,
                    () => _showComingSoonSnackBar('Edit Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionItem(
                    Icons.lock_rounded,
                    'Security',
                    Colors.orange,
                    () => _showComingSoonSnackBar('Security Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButtons(
    BuildContext context,
    UserSession userSession,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _refreshSession(userSession),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text(
              'Refresh Session',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.red, Colors.red.shade600]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _showModernLogoutDialog(context, userSession),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _refreshSession(UserSession userSession) async {
    try {
      await userSession.logout();

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Logged out successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Logout failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showModernLogoutDialog(BuildContext context, UserSession userSession) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Logout Confirmation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to logout? You will need to sign in again to access your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _performLogout(context, userSession);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showModernSettingsDialog(
    BuildContext context,
    UserSession userSession,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.blue,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSettingsOption(
                  Icons.edit_rounded,
                  'Edit Profile',
                  'Update your personal information',
                  () {
                    Navigator.of(dialogContext).pop();
                    _showComingSoonSnackBar('Edit Profile');
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingsOption(
                  Icons.lock_rounded,
                  'Change Password',
                  'Update your account password',
                  () {
                    Navigator.of(dialogContext).pop();
                    _showComingSoonSnackBar('Change Password');
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Text('$feature feature coming soon!'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _performLogout(
    BuildContext context,
    UserSession userSession,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Logging out...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Clear check-in and check-out times on logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_check_in_time');
      await prefs.remove('user_check_out_time');
      await userSession.logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Logged out successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Logout failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFF8B5CF6); // Modern purple
      case UserRole.teacher:
        return const Color(0xFF3B82F6); // Modern blue
      case UserRole.user:
        return const Color(0xFF10B981); // Modern green
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.teacher:
        return Icons.school_rounded;
      case UserRole.user:
        return Icons.person_rounded;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.user:
        return 'User';
    }
  }
}

// Custom painter for animated background pattern
class CirclePatternPainter extends CustomPainter {
  final double animationValue;

  CirclePatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.8;

    // Draw animated circles
    for (int i = 1; i <= 3; i++) {
      final radius = (maxRadius / 3) * i * animationValue;
      canvas.drawCircle(center, radius, paint);
    }

    // Draw decorative dots
    final dotPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final x =
          center.dx + (maxRadius * 0.7) * animationValue * math.cos(angle);
      final y =
          center.dy + (maxRadius * 0.7) * animationValue * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
