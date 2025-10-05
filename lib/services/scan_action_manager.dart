import 'package:flutter/material.dart';

/// Scan Action Manager - Manages context for scanning operations
/// This ensures the system knows what action to take when a card is scanned
class ScanActionManager extends ChangeNotifier {
  static final ScanActionManager _instance = ScanActionManager._internal();
  factory ScanActionManager() => _instance;
  ScanActionManager._internal();

  ScanAction? _currentAction;
  DateTime? _actionStartTime;
  Map<String, dynamic>? _actionContext;

  ScanAction? get currentAction => _currentAction;
  bool get hasActiveAction => _currentAction != null;
  String get actionDescription =>
      _currentAction?.description ?? 'No active action';

  /// Set the current scan action with context
  void setAction(ScanAction action, {Map<String, dynamic>? context}) {
    _currentAction = action;
    _actionStartTime = DateTime.now();
    _actionContext = context;
    notifyListeners();
    print('✅ Scan action set: ${action.description}');
  }

  /// Clear the current action
  void clearAction() {
    _currentAction = null;
    _actionStartTime = null;
    _actionContext = null;
    notifyListeners();
    print('🔄 Scan action cleared');
  }

  /// Get action context data
  T? getContext<T>(String key) {
    return _actionContext?[key] as T?;
  }

  /// Check if action has timed out (5 minutes)
  bool isActionExpired() {
    if (_actionStartTime == null) return true;
    return DateTime.now().difference(_actionStartTime!).inMinutes > 5;
  }
}

/// Available scan actions in the system
enum ScanAction {
  attendance('Mark Attendance', Icons.how_to_reg, Colors.blue),
  payment('Process Payment', Icons.payment, Colors.green),
  busTracking('Track Bus', Icons.directions_bus, Colors.orange),
  discipline('Record Discipline', Icons.rule, Colors.red),
  registration('Register Student', Icons.person_add, Colors.purple),
  general('General Scan', Icons.qr_code_scanner, Colors.grey);

  final String description;
  final IconData icon;
  final Color color;

  const ScanAction(this.description, this.icon, this.color);
}
