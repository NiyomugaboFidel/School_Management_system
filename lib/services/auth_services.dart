import 'package:sqlite_crud_app/SQLite/database_helper.dart';
import 'package:sqlite_crud_app/models/attendance.dart';
import 'package:sqlite_crud_app/models/student.dart';

import '../models/user.dart';

/// Example usage of the improved DatabaseHelper
// ============================= CLASS AuthService =============================
class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ============================= SIGN UP =============================
  Future<String?> signUp({
    required String username,
    required String password,
    required String fullName,
    String? email,
    String role = 'user',
  }) async {
    try {
      // Validate input data
      if (username.trim().isEmpty ||
          password.length < 6 ||
          fullName.trim().isEmpty) {
        return 'Please provide valid username, password (min 6 chars), and full name';
      }

      if (email != null && email.isNotEmpty && !_isValidEmail(email)) {
        return 'Please provide a valid email address';
      }

      if (!['admin', 'teacher', 'user'].contains(role)) {
        return 'Invalid user role';
      }

      final user = User(
        username: username.trim(),
        password: password,
        fullName: fullName.trim(),
        email: email?.trim(),
        role: UserRole.values.firstWhere(
          (r) => r.value == role,
          orElse: () => UserRole.user,
        ),
        isActive: true,
      );

      final result = await _dbHelper.createUser(user);

      if (result.success) {
        DatabaseLogger.logDatabaseOperation('SignUp', true);
        return null; // Success
      } else {
        DatabaseLogger.logDatabaseOperation('SignUp', false, result.message);
        return result.message ?? 'Failed to create user';
      }
    } catch (e) {
      DatabaseLogger.logDatabaseOperation('SignUp', false, e.toString());
      return 'Sign up failed: $e';
    }
  }

  // ============================= SIGN IN =============================
  Future<SignInResult> signIn(String username, String password) async {
    try {
      final result = await _dbHelper.authenticate(username, password);

      if (result.success && result.user != null) {
        DatabaseLogger.logDatabaseOperation('SignIn', true);
        return SignInResult.success(result.user!);
      } else {
        DatabaseLogger.logDatabaseOperation('SignIn', false, result.message);
        return SignInResult.failure(result.message ?? 'Sign in failed');
      }
    } catch (e) {
      DatabaseLogger.logDatabaseOperation('SignIn', false, e.toString());
      return SignInResult.failure('Sign in error: $e');
    }
  }

  // ============================= GET CURRENT USER =============================
  Future<User?> getCurrentUser(String username) async {
    try {
      return await _dbHelper.getUserByUsername(username);
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'GetCurrentUser',
        false,
        e.toString(),
      );
      return null;
    }
  }

  // ============================= GET USER BY ID =============================
  Future<User?> getUserById(int userId) async {
    try {
      return await _dbHelper.getUserById(userId);
    } catch (e) {
      DatabaseLogger.logDatabaseOperation('GetUserById', false, e.toString());
      return null;
    }
  }

  // ============================= UPDATE PROFILE =============================
  Future<bool> updateProfile(User user) async {
    try {
      final success = await _dbHelper.updateUser(user);
      DatabaseLogger.logDatabaseOperation('UpdateProfile', success);
      return success;
    } catch (e) {
      DatabaseLogger.logDatabaseOperation('UpdateProfile', false, e.toString());
      return false;
    }
  }

  // ============================= CHANGE PASSWORD =============================
  Future<bool> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      if (newPassword.length < 6) {
        return false;
      }

      final success = await _dbHelper.changePassword(
        userId,
        oldPassword,
        newPassword,
      );
      DatabaseLogger.logDatabaseOperation('ChangePassword', success);
      return success;
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'ChangePassword',
        false,
        e.toString(),
      );
      return false;
    }
  }

  // ============================= DEACTIVATE USER =============================
  Future<bool> deactivateUser(int userId) async {
    try {
      final success = await _dbHelper.deactivateUser(userId);
      DatabaseLogger.logDatabaseOperation('DeactivateUser', success);
      return success;
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'DeactivateUser',
        false,
        e.toString(),
      );
      return false;
    }
  }

  // ============================= VALIDATE EMAIL =============================
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }
}

// ============================= CLASS SignInResult =============================
class SignInResult {
  final bool success;
  final User? user;
  final String? error;

  SignInResult._(this.success, this.user, this.error);

  factory SignInResult.success(User user) => SignInResult._(true, user, null);
  factory SignInResult.failure(String error) =>
      SignInResult._(false, null, error);
}

// ============================= CLASS UserRepository =============================
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ============================= GET ALL USERS =============================
  Future<List<User>> getAllUsers() async {
    try {
      return await _dbHelper.getAllActiveUsers();
    } catch (e) {
      DatabaseLogger.logDatabaseOperation('GetAllUsers', false, e.toString());
      return [];
    }
  }

  // ============================= GET USERS WITH PAGINATION =============================
  Future<List<User>> getUsers({int page = 1, int limit = 20}) async {
    try {
      final allUsers = await _dbHelper.getAllActiveUsers();
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;

      if (startIndex >= allUsers.length) return [];

      return allUsers.sublist(
        startIndex,
        endIndex > allUsers.length ? allUsers.length : endIndex,
      );
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'GetUsersWithPagination',
        false,
        e.toString(),
      );
      return [];
    }
  }

  // ============================= SEARCH USERS =============================
  Future<List<User>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final allUsers = await _dbHelper.getAllActiveUsers();
      return allUsers.where((user) {
        final searchQuery = query.toLowerCase();
        return user.fullName?.toLowerCase().contains(searchQuery) == true ||
            user.username.toLowerCase().contains(searchQuery) ||
            user.email?.toLowerCase().contains(searchQuery) == true;
      }).toList();
    } catch (e) {
      DatabaseLogger.logDatabaseOperation('SearchUsers', false, e.toString());
      return [];
    }
  }

  // ============================= CREATE MULTIPLE USERS =============================
  Future<CreateUsersResult> createMultipleUsers(List<User> users) async {
    final List<String> errors = [];
    final List<User> successfulUsers = [];

    try {
      for (final user in users) {
        final result = await _dbHelper.createUser(user);
        if (result.success && result.user != null) {
          successfulUsers.add(result.user!);
        } else {
          errors.add(
            'Failed to create user ${user.username}: ${result.message}',
          );
        }
      }

      final success = errors.isEmpty;
      DatabaseLogger.logDatabaseOperation('CreateMultipleUsers', success);

      return CreateUsersResult(
        success: success,
        createdUsers: successfulUsers,
        errors: errors,
      );
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'CreateMultipleUsers',
        false,
        e.toString(),
      );
      return CreateUsersResult(
        success: false,
        createdUsers: successfulUsers,
        errors: [...errors, 'Unexpected error: $e'],
      );
    }
  }

  // ============================= GET USERS BY ROLE =============================
  Future<List<User>> getUsersByRole(String role) async {
    try {
      final allUsers = await _dbHelper.getAllActiveUsers();
      return allUsers.where((user) => user.role == role).toList();
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'GetUsersByRole',
        false,
        e.toString(),
      );
      return [];
    }
  }

  // ============================= GET USER STATISTICS =============================
  Future<UserStatistics> getUserStatistics() async {
    try {
      final allUsers = await _dbHelper.getAllActiveUsers();

      final stats = UserStatistics(
        totalUsers: allUsers.length,
        adminCount: allUsers.where((u) => u.role == 'admin').length,
        teacherCount: allUsers.where((u) => u.role == 'teacher').length,
        userCount: allUsers.where((u) => u.role == 'user').length,
        activeUsers: allUsers.where((u) => u.isActive).length,
      );

      return stats;
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'GetUserStatistics',
        false,
        e.toString(),
      );
      return UserStatistics.empty();
    }
  }
}

// ============================= CLASS StudentService =============================
class StudentService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ============================= GET ALL STUDENTS =============================
  Future<List<Student>> getAllStudents() async {
    try {
      return await _dbHelper.getAllStudents();
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'GetAllStudents',
        false,
        e.toString(),
      );
      return [];
    }
  }

  // ============================= SEARCH STUDENTS =============================
  Future<List<Student>> searchStudents(String query) async {
    try {
      return await _dbHelper.searchStudents(query);
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'SearchStudents',
        false,
        e.toString(),
      );
      return [];
    }
  }

  // ============================= GET STUDENT BY BARCODE =============================
  Future<Student?> getStudentByBarcode(String barcode) async {
    try {
      return await _dbHelper.getStudentByBarcode(barcode);
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'GetStudentByBarcode',
        false,
        e.toString(),
      );
      return null;
    }
  }

  // ============================= GET STUDENT BY NFC =============================
  Future<Student?> getStudentByNFC(String nfcTagId) async {
    try {
      return await _dbHelper.getStudentByNFC(nfcTagId);
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'GetStudentByNFC',
        false,
        e.toString(),
      );
      return null;
    }
  }

  // ============================= GET STUDENT BY NFC =============================
  Future<Student?> getStudentById(String studentId) async {
    try {
      return await _dbHelper.getStudentById(studentId);
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'GetStudentByNFC',
        false,
        e.toString(),
      );
      return null;
    }
  }


  // ============================= GET STUDENTS BY CLASS =============================
  Future<List<Student>> getStudentsByClass(int classId) async {
    try {
      return await _dbHelper.getStudentsByClass(classId);
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'GetStudentsByClass',
        false,
        e.toString(),
      );
      return [];
    }
  }
}

// ============================= CLASS AttendanceService =============================
class AttendanceService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ============================= MARK ATTENDANCE =============================
  Future<bool> markAttendance(
    int studentId,
    String status,
    String markedBy, {
    String? notes,
  }) async {
    try {
      final success = await _dbHelper.markAttendance(
        studentId,
        status,
        markedBy,
        notes: notes,
      );
      DatabaseLogger.logDatabaseOperation('MarkAttendance', success);
      return success;
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'MarkAttendance',
        false,
        e.toString(),
      );
      return false;
    }
  }

  // ============================= GET TODAY'S ATTENDANCE =============================
  Future<List<AttendanceLog>> getTodayAttendance() async {
    try {
      return await _dbHelper.getTodayAttendance();
    } catch (e) {
      DatabaseLogger.logDatabaseOperation(
        'GetTodayAttendance',
        false,
        e.toString(),
      );
      return [];
    }
  }
}

// ============================= CLASS DatabaseLogger =============================
class DatabaseLogger {
  static void logDatabaseOperation(
    String operation,
    bool success, [
    String? error,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    final status = success ? 'SUCCESS' : 'FAILED';
    final message = '[$timestamp] $operation: $status';

    if (error != null) {
      print('$message - Error: $error');
    } else {
      print(message);
    }
  }

  static void logInfo(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] INFO: $message');
  }

  static void logWarning(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] WARNING: $message');
  }

  static void logError(String message, [dynamic error]) {
    final timestamp = DateTime.now().toIso8601String();
    if (error != null) {
      print('[$timestamp] ERROR: $message - $error');
    } else {
      print('[$timestamp] ERROR: $message');
    }
  }
}

// ============================= CLASS DatabaseManager =============================
class DatabaseManager {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ============================= INITIALIZE DATABASE =============================
  Future<bool> initializeDatabase() async {
    try {
      final db = await _dbHelper.database;
      DatabaseLogger.logInfo('Database initialized successfully');
      return true;
    } catch (e) {
      DatabaseLogger.logError('Failed to initialize database', e);
      return false;
    }
  }

  // ============================= BACKUP DATABASE =============================
  Future<Map<String, List<Map<String, dynamic>>>> backupDatabase() async {
    try {
      final backup = await _dbHelper.getDatabaseBackup();
      DatabaseLogger.logDatabaseOperation('BackupDatabase', backup.isNotEmpty);
      return backup;
    } catch (e) {
      DatabaseLogger.logError('Database backup failed', e);
      return {};
    }
  }

  // ============================= CLEAR ALL DATA =============================
  Future<bool> clearAllData() async {
    try {
      final success = await _dbHelper.clearAllData();
      DatabaseLogger.logDatabaseOperation('ClearAllData', success);
      return success;
    } catch (e) {
      DatabaseLogger.logError('Failed to clear all data', e);
      return false;
    }
  }

  // ============================= CLOSE DATABASE =============================
  Future<void> closeDatabase() async {
    try {
      await _dbHelper.close();
      DatabaseLogger.logInfo('Database closed successfully');
    } catch (e) {
      DatabaseLogger.logError('Failed to close database', e);
    }
  }

  // ============================= DELETE DATABASE =============================
  Future<bool> deleteDatabase() async {
    try {
      final success = await _dbHelper.deleteDatabase();
      DatabaseLogger.logDatabaseOperation('DeleteDatabase', success);
      return success;
    } catch (e) {
      DatabaseLogger.logError('Failed to delete database', e);
      return false;
    }
  }
}

// ============================= RESULT CLASSES =============================

/// Result class for creating multiple users
class CreateUsersResult {
  final bool success;
  final List<User> createdUsers;
  final List<String> errors;

  CreateUsersResult({
    required this.success,
    required this.createdUsers,
    required this.errors,
  });

  int get successCount => createdUsers.length;
  int get errorCount => errors.length;
  bool get hasErrors => errors.isNotEmpty;
}

/// User statistics class
class UserStatistics {
  final int totalUsers;
  final int adminCount;
  final int teacherCount;
  final int userCount;
  final int activeUsers;

  UserStatistics({
    required this.totalUsers,
    required this.adminCount,
    required this.teacherCount,
    required this.userCount,
    required this.activeUsers,
  });

  factory UserStatistics.empty() => UserStatistics(
    totalUsers: 0,
    adminCount: 0,
    teacherCount: 0,
    userCount: 0,
    activeUsers: 0,
  );

  double get adminPercentage =>
      totalUsers > 0 ? (adminCount / totalUsers) * 100 : 0;
  double get teacherPercentage =>
      totalUsers > 0 ? (teacherCount / totalUsers) * 100 : 0;
  double get userPercentage =>
      totalUsers > 0 ? (userCount / totalUsers) * 100 : 0;
  double get activePercentage =>
      totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0;
}
