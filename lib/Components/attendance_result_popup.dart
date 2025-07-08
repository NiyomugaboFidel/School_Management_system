import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class AttendanceResultPopup extends StatefulWidget {
  final String studentName;
  final String studentId;
  final String gender;
  final String imageUrl;
  final String status;
  final bool success;
  final VoidCallback? onDismiss;

  const AttendanceResultPopup({
    required this.studentName,
    required this.studentId,
    required this.gender,
    required this.imageUrl,
    required this.status,
    required this.success,
    this.onDismiss,
    Key? key,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String studentName,
    required String studentId,
    required String gender,
    required String imageUrl,
    required String status,
    required bool success,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => AttendanceResultPopup(
            studentName: studentName,
            studentId: studentId,
            gender: gender,
            imageUrl: imageUrl,
            status: status,
            success: success,
            onDismiss: () {
              entry.remove();
            },
          ),
    );
    overlay.insert(entry);
  }

  @override
  State<AttendanceResultPopup> createState() => _AttendanceResultPopupState();
}

class _AttendanceResultPopupState extends State<AttendanceResultPopup>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _imageController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _imageScaleAnimation;
  late Animation<double> _pulseAnimation;
  Timer? _autoDismissTimer;
  bool _isDisposed = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _addHapticFeedback();
    _setupAutoDismiss();
  }

  void _initializeAnimations() {
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Setup animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _imageScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    // Start entrance animations
    _fadeController.forward();
    _scaleController.forward();

    // Delay image animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!_isDisposed && mounted) {
        _imageController.forward();
      }
    });

    // Start pulse animation for success status
    if (widget.success) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!_isDisposed && mounted) {
          _pulseController.repeat(reverse: true);
        }
      });
    }
  }

  void _addHapticFeedback() {
    if (widget.success) {
      switch (widget.status.toLowerCase()) {
        case 'present':
          HapticFeedback.lightImpact();
          break;
        case 'late':
          HapticFeedback.mediumImpact();
          break;
        case 'absent':
          HapticFeedback.heavyImpact();
          break;
        default:
          HapticFeedback.lightImpact();
      }
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _setupAutoDismiss() {
    _autoDismissTimer = Timer(const Duration(seconds: 3), () {
      if (!_isDisposed && mounted && !_isDismissing) {
        _dismissPopup();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoDismissTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    _imageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _dismissPopup() {
    if (_isDismissing || _isDisposed) return;
    _isDismissing = true;

    _autoDismissTimer?.cancel();
    _pulseController.stop();

    // Reverse animations
    _fadeController.reverse();
    _scaleController.reverse();
    _imageController.reverse();

    // Wait for animations to complete then remove overlay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_isDisposed) {
        widget.onDismiss?.call();
      }
    });
  }

  Color _getStatusColor() {
    switch (widget.status.toLowerCase()) {
      case 'present':
        return const Color(0xFF4CAF50); // Green
      case 'late':
        return const Color(0xFFFF9800); // Orange
      case 'absent':
        return const Color(0xFFE53935); // Red
      default:
        return widget.success
            ? const Color(0xFF4CAF50)
            : const Color(0xFFE53935);
    }
  }

  IconData _getStatusIcon() {
    if (!widget.success) return Icons.cancel_rounded;

    switch (widget.status.toLowerCase()) {
      case 'present':
        return Icons.check_circle_rounded;
      case 'late':
        return Icons.schedule_rounded;
      case 'absent':
        return Icons.cancel_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String _getStatusMessage() {
    if (!widget.success) return 'Attendance Failed';

    switch (widget.status.toLowerCase()) {
      case 'present':
        return 'Attendance Marked: Present';
      case 'late':
        return 'Attendance Marked: Late';
      case 'absent':
        return 'Attendance Marked: Absent';
      default:
        return 'Attendance Recorded';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeController, _scaleController]),
      builder: (context, child) {
        return WillPopScope(
          onWillPop: () async {
            _dismissPopup();
            return false;
          },
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismissPopup,
              child: Container(
                color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
                child: Center(
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: isTablet ? 400 : size.width * 0.85,
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: _getStatusColor().withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status Icon with pulse animation
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale:
                                    _fadeAnimation.value *
                                    _pulseAnimation.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor().withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _getStatusColor().withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    _getStatusIcon(),
                                    color: _getStatusColor(),
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Status Message
                          AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: Text(
                                  _getStatusMessage(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Student Photo with enhanced styling
                          AnimatedBuilder(
                            animation: _imageScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _imageScaleAnimation.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getStatusColor().withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child:
                                        widget.imageUrl.isNotEmpty
                                            ? Image.network(
                                              widget.imageUrl,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  width: 120,
                                                  height: 120,
                                                  color: Colors.grey[100],
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                      color: _getStatusColor(),
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  width: 120,
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.person_rounded,
                                                    size: 60,
                                                    color: Colors.grey[400],
                                                  ),
                                                );
                                              },
                                            )
                                            : Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: 60,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Student Info with better styling
                          AnimatedBuilder(
                            animation: _fadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildInfoRow(
                                            'Name',
                                            widget.studentName,
                                          ),
                                          const SizedBox(height: 8),
                                          _buildInfoRow('ID', widget.studentId),
                                          const SizedBox(height: 8),
                                          _buildInfoRow(
                                            'Gender',
                                            widget.gender,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tap anywhere to dismiss',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Helper function to show the popup
void showAttendanceResult(
  BuildContext context, {
  required String studentName,
  required String studentId,
  required String gender,
  required String imageUrl,
  required String status,
  required bool success,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    builder:
        (context) => AttendanceResultPopup(
          studentName: studentName,
          studentId: studentId,
          gender: gender,
          imageUrl: imageUrl,
          status: status,
          success: success,
        ),
  );
}
