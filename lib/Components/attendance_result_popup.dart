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

  const AttendanceResultPopup({
    required this.studentName,
    required this.studentId,
    required this.gender,
    required this.imageUrl,
    required this.status,
    required this.success,
    Key? key,
  }) : super(key: key);

  @override
  State<AttendanceResultPopup> createState() => _AttendanceResultPopupState();
}

class _AttendanceResultPopupState extends State<AttendanceResultPopup>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _imageController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _imageScaleAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Setup animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _imageScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeOutBack),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    // Add haptic feedback based on status
    _addHapticFeedback();

    // Delay image animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _imageController.forward();
    });

    // Auto dismiss after 2 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 2), () {
      _dismissPopup();
    });
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
      // Error feedback
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _imageController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _dismissPopup() {
    _fadeController.reverse();
    _scaleController.reverse();
    _imageController.reverse();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Color _getStatusColor() {
    switch (widget.status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return widget.success ? Colors.green : Colors.red;
    }
  }

  IconData _getStatusIcon() {
    if (!widget.success) return Icons.cancel;

    switch (widget.status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.access_time;
      case 'absent':
        return Icons.cancel;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeController, _scaleController]),
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismissPopup, // Dismiss on tap outside
            child: Container(
              color: Colors.black.withOpacity(0.4 * _fadeAnimation.value),
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Icon (Checkmark/X)
                        AnimatedBuilder(
                          animation: _fadeController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _fadeAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _getStatusColor().withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(),
                                  color: _getStatusColor(),
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Student Photo
                        AnimatedBuilder(
                          animation: _imageScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _imageScaleAnimation.value,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getStatusColor().withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child:
                                      widget.imageUrl.isNotEmpty
                                          ? Image.network(
                                            widget.imageUrl,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.person,
                                                  size: 50,
                                                  color: Colors.grey[600],
                                                ),
                                              );
                                            },
                                          )
                                          : Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Student Info
                        AnimatedBuilder(
                          animation: _fadeController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation.value,
                              child: Column(
                                children: [
                                  Text(
                                    'Name: ${widget.studentName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ID: ${widget.studentId}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gender: ${widget.gender}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black45,
                                    ),
                                    textAlign: TextAlign.center,
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
        );
      },
    );
  }
}
