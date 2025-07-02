import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:sqlite_crud_app/models/user.dart';

// ============================= CLASS UserSession =============================
class UserSession extends ChangeNotifier {
  static final UserSession _instance = UserSession._internal();

  factory UserSession() => _instance;
  UserSession._internal();

  // ============================= PRIVATE FIELDS =============================
  User? _currentUser;
  bool _isInitialized = false;
  DateTime? _sessionStartTime;

  static const int _sessionTimeoutMinutes = 30;
  static const String _userKey = 'current_user';
  static const String _sessionTimeKey = 'session_time';
  static const String _rememberMeKey = 'remember_me';

  // ============================= GETTERS =============================
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isTeacher => _currentUser?.isTeacher ?? false;
  String get userName => _currentUser?.displayName ?? 'Guest';

  bool get isSessionValid {
    if (_sessionStartTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_sessionStartTime!);
    return difference.inMinutes < _sessionTimeoutMinutes;
  }

  // ============================= INITIALIZE SESSION =============================
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      final sessionTimeString = prefs.getString(_sessionTimeKey);
      if (userJson != null && sessionTimeString != null) {
        final userData = json.decode(userJson);
        _currentUser = User.fromMap(userData);
        _sessionStartTime = DateTime.parse(sessionTimeString);
        if (!isSessionValid) {
          await _clearStoredSession();
          _currentUser = null;
          _sessionStartTime = null;
        }
      } else {
        _currentUser = null;
        _sessionStartTime = null;
      }
    } catch (e) {
      debugPrint('Error initializing user session: $e');
      await _clearStoredSession();
      _currentUser = null;
      _sessionStartTime = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ============================= SET CURRENT USER =============================
  Future<void> setCurrentUser(User user, {bool rememberMe = false}) async {
    _currentUser = user;
    _sessionStartTime = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setString(_userKey, json.encode(user.toMap()));
        await prefs.setString(
          _sessionTimeKey,
          _sessionStartTime!.toIso8601String(),
        );
        await prefs.setBool(_rememberMeKey, true);
      } else {
        await _clearStoredSession();
      }
    } catch (e) {
      debugPrint('Error saving user session: $e');
    }
    notifyListeners();
  }

  // ============================= UPDATE CURRENT USER =============================
  Future<void> updateCurrentUser(User updatedUser) async {
    if (_currentUser?.id != updatedUser.id) return;
    _currentUser = updatedUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (rememberMe) {
        await prefs.setString(_userKey, json.encode(updatedUser.toMap()));
      }
    } catch (e) {
      debugPrint('Error updating user session: $e');
    }
    notifyListeners();
  }

  // ============================= REFRESH SESSION =============================
  Future<void> refreshSession() async {
    if (_currentUser == null) return;
    _sessionStartTime = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (rememberMe) {
        await prefs.setString(
          _sessionTimeKey,
          _sessionStartTime!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error refreshing session: $e');
    }
  }

  // ============================= LOGOUT USER =============================
  Future<void> logout() async {
    _currentUser = null;
    _sessionStartTime = null;
    await _clearStoredSession();
    notifyListeners();
  }

  // ============================= CLEAR STORED SESSION =============================
  Future<void> _clearStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_sessionTimeKey);
      await prefs.remove(_rememberMeKey);
    } catch (e) {
      debugPrint('Error clearing stored session: $e');
    }
  }

  // ============================= CHECK SESSION TIMEOUT =============================
  Future<bool> checkSessionTimeout() async {
    if (_currentUser == null) return false;
    if (!isSessionValid) {
      await logout();
      return true;
    }
    return false;
  }

  // ============================= SESSION DURATION GETTER =============================
  Duration? get sessionDuration {
    if (_sessionStartTime == null) return null;
    return DateTime.now().difference(_sessionStartTime!);
  }

  // ============================= REMAINING SESSION TIME GETTER =============================
  Duration? get remainingSessionTime {
    if (_sessionStartTime == null) return null;
    const maxDuration = Duration(minutes: _sessionTimeoutMinutes);
    final elapsed = DateTime.now().difference(_sessionStartTime!);
    final remaining = maxDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // ============================= FORMATTED REMAINING TIME GETTER =============================
  String get formattedRemainingTime {
    final remaining = remainingSessionTime;
    if (remaining == null) return 'No active session';
    if (remaining == Duration.zero) return 'Session expired';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // ============================= FORMATTED SESSION DURATION GETTER =============================
  String get formattedSessionDuration {
    final duration = sessionDuration;
    if (duration == null) return 'No active session';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // ============================= HAS ROLE =============================
  bool hasRole(String role) {
    if (_currentUser == null) return false;
    switch (role.toLowerCase()) {
      case 'admin':
        return isAdmin;
      case 'teacher':
        return isTeacher;
      default:
        return false;
    }
  }

  // ============================= USER INITIALS GETTER =============================
  String get userInitials {
    if (_currentUser?.displayName == null ||
        _currentUser?.displayName.isEmpty == true) {
      return 'U';
    }
    final names = _currentUser!.displayName.split(' ');
    if (names.length >= 2) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    } else {
      return names.first[0].toUpperCase();
    }
  }

  // ============================= IS REMEMBER ME ENABLED =============================
  Future<bool> get isRememberMeEnabled async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      debugPrint('Error checking remember me status: $e');
      return false;
    }
  }

  // ============================= FORMATTED SESSION START TIME GETTER =============================
  String get formattedSessionStartTime {
    if (_sessionStartTime == null) return 'No active session';
    final now = DateTime.now();
    final difference = now.difference(_sessionStartTime!);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // ============================= RESET SESSION =============================
  Future<void> resetSession() async {
    _currentUser = null;
    _sessionStartTime = null;
    _isInitialized = false;
    await _clearStoredSession();
    notifyListeners();
  }
}
