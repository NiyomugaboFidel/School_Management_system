// lib/database/database_helper.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';

// Import all model classes
import '../models/user.dart';
import '../models/student.dart';
import '../models/level.dart';
import '../models/class.dart';
import '../models/attendance.dart';
import '../models/payment.dart';
import '../models/discipline.dart';

/// Database Helper for School Management System
/// Handles all database operations including user authentication, 
/// student management, attendance tracking, and payments
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _databaseName = "school_management.db";
  static const int _databaseVersion = 1;

  // Table names - centralized for easy maintenance
  static const String _tableUsers = "users";
  static const String _tableLevels = "levels";
  static const String _tableClasses = "classes";
  static const String _tableStudents = "students";
  static const String _tableAttendance = "attendance_logs";
  static const String _tablePayments = "payments";
  static const String _tableDiscipline = "discipline";
  static const String _tableHolidays = "holidays";
  static const String _tableStatistics = "statistics";
  static const String _tableSyncQueue = "sync_queue";

  /// Get database instance - lazy initialization
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database with proper error handling
  Future<Database> _initDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  /// Create all tables with proper constraints and indexes
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    _createUserTable(batch);
    _createLevelTable(batch);
    _createClassTable(batch);
    _createStudentTable(batch);
    _createAttendanceTable(batch);
    _createPaymentTable(batch);
    _createDisciplineTable(batch);
    _createHolidayTable(batch);
    _createStatisticsTable(batch);
    _createSyncQueueTable(batch);
    _createIndexes(batch);

    await batch.commit(noResult: true);
    await _insertInitialData(db);
  }

  /// Create users table
  void _createUserTable(Batch batch) {
    batch.execute('''
      CREATE TABLE $_tableUsers (
        usr_id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT UNIQUE,
        usr_name TEXT UNIQUE NOT NULL,
        usr_password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'teacher', 'user')),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
        last_login TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  /// Create levels table
  void _createLevelTable(Batch batch) {
    batch.execute('''
      CREATE TABLE $_tableLevels (
        level_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  /// Create classes table
  void _createClassTable(Batch batch) {
    batch.execute('''
      CREATE TABLE $_tableClasses (
        class_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        level_id INTEGER NOT NULL,
        section TEXT NOT NULL,
        student_count INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (level_id) REFERENCES $_tableLevels(level_id) ON DELETE CASCADE,
        UNIQUE(name, level_id)
      )
    ''');
  }

  /// Create students table
  void _createStudentTable(Batch batch) {
    batch.execute('''
      CREATE TABLE $_tableStudents (
        student_id INTEGER PRIMARY KEY,
        reg_number TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        class_id INTEGER NOT NULL,
        barcode TEXT UNIQUE,
        nfc_tag_id TEXT UNIQUE,
        profile_image TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (class_id) REFERENCES $_tableClasses(class_id) ON DELETE RESTRICT
      )
    ''');
  }

  /// Create attendance logs table
  void _createAttendanceTable(Batch batch) {
    batch.execute('''
      CREATE TABLE $_tableAttendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('Present', 'Absent', 'Late', 'Excused')),
        marked_by TEXT NOT NULL,
        marked_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        profile_image TEXT,
        notes TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (student_id) REFERENCES $_tableStudents(student_id) ON DELETE CASCADE,
        UNIQUE(student_id, date)
      )
    ''');
  }

  /// Create payments table
  void _createPaymentTable(Batch batch) {
    batch.execute('''
      CREATE TABLE $_tablePayments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        amount REAL NOT NULL CHECK (amount > 0),
        date_paid TEXT NOT NULL,
        payment_type TEXT NOT NULL,
        payment_method TEXT,
        parent_reason TEXT,
        receipt_number TEXT UNIQUE,
        profile_image TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (student_id) REFERENCES $_tableStudents(student_id) ON DELETE CASCADE
      )
    ''');
  }

  /// Create discipline table
  void _createDisciplineTable(Batch batch) {
    batch.execute('''
      CREATE TABLE $_tableDiscipline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        incident_date TEXT NOT NULL,
        marks_deducted INTEGER NOT NULL DEFAULT 0 CHECK (marks_deducted >= 0),
        reason TEXT NOT NULL,
        severity TEXT NOT NULL CHECK (severity IN ('Minor', 'Major', 'Severe')),
        action_taken TEXT,
        recorded_by TEXT NOT NULL,
        profile_image TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (student_id) REFERENCES $_tableStudents(student_id) ON DELETE CASCADE
      )
    ''');
  }

  /// Create holidays table
  void _createHolidayTable(Batch batch) {
    batch.execute('''
      CREATE TABLE $_tableHolidays (
        date TEXT PRIMARY KEY,
        reason TEXT NOT NULL,
        holiday_type TEXT NOT NULL DEFAULT 'Public',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  /// Create statistics table
  void _createStatisticsTable(Batch batch) {
    batch.execute('''
      CREATE TABLE $_tableStatistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER UNIQUE NOT NULL,
        academic_year TEXT NOT NULL,
        total_school_days INTEGER NOT NULL DEFAULT 0,
        present_count INTEGER NOT NULL DEFAULT 0,
        absent_count INTEGER NOT NULL DEFAULT 0,
        late_count INTEGER NOT NULL DEFAULT 0,
        excused_count INTEGER NOT NULL DEFAULT 0,
        discipline_cases INTEGER NOT NULL DEFAULT 0,
        total_discipline_marks_deducted INTEGER NOT NULL DEFAULT 0,
        attendance_percentage REAL NOT NULL DEFAULT 0.0,
        behavior_rating TEXT CHECK (behavior_rating IN ('Excellent', 'Good', 'Fair', 'Poor')),
        last_calculated TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (student_id) REFERENCES $_tableStudents(student_id) ON DELETE CASCADE
      )
    ''');
  }

  /// Create sync queue table
  void _createSyncQueueTable(Batch batch) {
    batch.execute('''
      CREATE TABLE $_tableSyncQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
        data TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_attempt TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  /// Create indexes for better performance
  void _createIndexes(Batch batch) {
    // Students indexes
    batch.execute('CREATE INDEX idx_students_class_id ON $_tableStudents(class_id)');
    batch.execute('CREATE INDEX idx_students_reg_number ON $_tableStudents(reg_number)');
    batch.execute('CREATE INDEX idx_students_barcode ON $_tableStudents(barcode)');
    batch.execute('CREATE INDEX idx_students_nfc_tag_id ON $_tableStudents(nfc_tag_id)');
    
    // Attendance indexes
    batch.execute('CREATE INDEX idx_attendance_student_id ON $_tableAttendance(student_id)');
    batch.execute('CREATE INDEX idx_attendance_date ON $_tableAttendance(date)');
    batch.execute('CREATE INDEX idx_attendance_synced ON $_tableAttendance(synced)');
    
    // Payments indexes
    batch.execute('CREATE INDEX idx_payments_student_id ON $_tablePayments(student_id)');
    batch.execute('CREATE INDEX idx_payments_date ON $_tablePayments(date_paid)');
    batch.execute('CREATE INDEX idx_payments_synced ON $_tablePayments(synced)');
    
    // Classes indexes
    batch.execute('CREATE INDEX idx_classes_level_id ON $_tableClasses(level_id)');
    batch.execute('CREATE INDEX idx_classes_active ON $_tableClasses(is_active)');
  }

  /// Insert initial test data
  Future<void> _insertInitialData(Database db) async {
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    // Insert default admin user
    batch.insert(_tableUsers, {
      'full_name': 'System Administrator',
      'email': 'admin@school.com',
      'usr_name': 'admin',
      'usr_password': _hashPassword('admin123'),
      'role': 'admin',
      'created_at': now,
      'updated_at': now,
    });

    // Insert levels
    final levels = ['L3', 'L4', 'L5'];
    for (int i = 0; i < levels.length; i++) {
      batch.insert(_tableLevels, {
        'level_id': i + 1,
        'name': levels[i],
        'created_at': now,
        'updated_at': now,
      });
    }

    // Insert classes
    await _insertClasses(batch, levels, now);
    await batch.commit(noResult: true);
    
    // Insert test students
    await _insertTestStudents(db);
  }

  /// Insert classes for each level and section
  Future<void> _insertClasses(Batch batch, List<String> levels, String now) async {
    final sections = ['SOD', 'NET', 'MTD'];
    final subsections = ['A', 'B'];
    int classId = 1;
    
    for (int levelId = 1; levelId <= 3; levelId++) {
      for (String section in sections) {
        for (String subsection in subsections) {
          final className = '${levels[levelId - 1]} $section $subsection';
          batch.insert(_tableClasses, {
            'class_id': classId,
            'name': className,
            'level_id': levelId,
            'section': section,
            'student_count': 0,
            'created_at': now,
            'updated_at': now,
          });
          classId++;
        }
      }
    }
  }

  /// Insert test students with sample data
  Future<void> _insertTestStudents(Database db) async {
    final random = Random();
    final firstNames = ['John', 'Jane', 'Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank', 'Grace', 'Henry'];
    final lastNames = ['Smith', 'Johnson', 'Brown', 'Davis', 'Wilson', 'Miller', 'Taylor', 'Anderson', 'Thomas', 'Jackson'];
    final now = DateTime.now().toIso8601String();

    for (int i = 1; i <= 10; i++) {
      final studentId = 20240000 + i;
      final student = _createTestStudent(i, studentId, firstNames, lastNames, random, now);
      
      await db.insert(_tableStudents, student);
      await _updateClassStudentCount(db, student['class_id'], now);
      await _insertSampleAttendance(db, studentId);
      await _insertSamplePayments(db, studentId);
    }
  }

  /// Create a test student record
  Map<String, dynamic> _createTestStudent(int index, int studentId, List<String> firstNames, 
      List<String> lastNames, Random random, String now) {
    final firstName = firstNames[index - 1];
    final lastName = lastNames[random.nextInt(lastNames.length)];
    final classId = random.nextInt(18) + 1;

    return {
      'student_id': studentId,
      'reg_number': 'REG${studentId.toString().substring(4)}',
      'full_name': '$firstName $lastName',
      'class_id': classId,
      'barcode': 'BC$studentId',
      'nfc_tag_id': 'NFC$studentId',
      'profile_image': null,
      'created_at': now,
      'updated_at': now,
    };
  }

  /// Update class student count
  Future<void> _updateClassStudentCount(Database db, int classId, String now) async {
    await db.rawUpdate('''
      UPDATE $_tableClasses 
      SET student_count = student_count + 1, updated_at = ?
      WHERE class_id = ?
    ''', [now, classId]);
  }

  /// Insert sample attendance records
  Future<void> _insertSampleAttendance(Database db, int studentId) async {
    final random = Random();
    final statuses = ['Present', 'Absent', 'Late', 'Present', 'Present'];
    
    for (int i = 1; i <= 5; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final status = statuses[random.nextInt(statuses.length)];
      
      await db.insert(_tableAttendance, {
        'student_id': studentId,
        'date': date.toIso8601String().split('T')[0],
        'status': status,
        'marked_by': 'System',
        'marked_at': date.toIso8601String(),
        'notes': 'Sample attendance record',
        'created_at': date.toIso8601String(),
      });
    }
  }

  /// Insert sample payments
  Future<void> _insertSamplePayments(Database db, int studentId) async {
    final random = Random();
    final paymentTypes = ['Tuition', 'Transport', 'Meals', 'Books'];
    
    for (int i = 1; i <= 2; i++) {
      final paymentDate = DateTime.now().subtract(Duration(days: i * 15));
      final amount = (random.nextInt(5) + 1) * 50000.0;
      final paymentType = paymentTypes[random.nextInt(paymentTypes.length)];
      
      await db.insert(_tablePayments, {
        'student_id': studentId,
        'amount': amount,
        'date_paid': paymentDate.toIso8601String().split('T')[0],
        'payment_type': paymentType,
        'payment_method': 'Cash',
        'receipt_number': 'REC$studentId${i.toString().padLeft(3, '0')}',
        'created_at': paymentDate.toIso8601String(),
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    // Add migration logic for future versions
  }

  Future<void> _onOpen(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ============================= AUTHENTICATION METHODS =============================

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password against hash
  bool _verifyPassword(String password, String hashedPassword) {
    return _hashPassword(password) == hashedPassword;
  }

  /// Authenticate user with username and password
  Future<AuthResult> authenticate(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      return AuthResult.failure('Username and password cannot be empty');
    }

    try {
      final db = await database;
      final hashedPassword = _hashPassword(password);
      final now = DateTime.now().toIso8601String();

      final result = await db.query(
        _tableUsers,
        where: 'usr_name = ? AND usr_password = ? AND is_active = 1',
        whereArgs: [username.trim(), hashedPassword],
      );

      if (result.isNotEmpty) {
        // Update last login
        await db.update(
          _tableUsers,
          {'last_login': now, 'updated_at': now},
          where: 'usr_id = ?',
          whereArgs: [result.first['usr_id']],
        );

        final user = User.fromMap(result.first);
        return AuthResult.success(user);
      } else {
        return AuthResult.failure('Invalid username or password');
      }
    } catch (e) {
      return AuthResult.failure('Authentication failed: $e');
    }
  }

  // ============================= USER MANAGEMENT METHODS =============================

  /// Create new user
  Future<CreateUserResult> createUser(User user) async {
    if (!_isValidUser(user)) {
      return CreateUserResult.failure('Invalid user data');
    }

    try {
      final db = await database;

      // Check if username or email already exists
      final existingUser = await db.query(
        _tableUsers,
        where: 'usr_name = ? OR email = ?',
        whereArgs: [user.username, user.email],
      );

      if (existingUser.isNotEmpty) {
        return CreateUserResult.failure('Username or email already exists');
      }

      final now = DateTime.now().toIso8601String();
      final userMap = user.toMap();
      userMap['usr_password'] = _hashPassword(user.password);
      userMap['created_at'] = now;
      userMap['updated_at'] = now;

      final userId = await db.insert(_tableUsers, userMap);
      final newUser = user.copyWith(id: userId);
      return CreateUserResult.success(newUser);
    } catch (e) {
      return CreateUserResult.failure('Error creating user: $e');
    }
  }

  /// Get user by username
  Future<User?> getUserByUsername(String username) async {
    if (username.trim().isEmpty) return null;

    try {
      final db = await database;
      final result = await db.query(
        _tableUsers,
        where: 'usr_name = ? AND is_active = 1',
        whereArgs: [username.trim()],
      );

      return result.isNotEmpty ? User.fromMap(result.first) : null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Get user by ID
  Future<User?> getUserById(int userId) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableUsers,
        where: 'usr_id = ? AND is_active = 1',
        whereArgs: [userId],
      );

      return result.isNotEmpty ? User.fromMap(result.first) : null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  /// Update user information
  Future<bool> updateUser(User user) async {
    if (user.id == null || !_isValidUser(user)) return false;

    try {
      final db = await database;
      final userMap = user.toMap();
      userMap['updated_at'] = DateTime.now().toIso8601String();
      userMap.remove('usr_password'); // Don't update password here

      final result = await db.update(
        _tableUsers,
        userMap,
        where: 'usr_id = ?',
        whereArgs: [user.id],
      );

      return result > 0;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  /// Change user password
  Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    if (newPassword.length < 6) return false;

    try {
      final db = await database;

      // Verify old password
      final result = await db.query(
        _tableUsers,
        where: 'usr_id = ? AND usr_password = ?',
        whereArgs: [userId, _hashPassword(oldPassword)],
      );

      if (result.isEmpty) return false;

      // Update with new password
      final updateResult = await db.update(
        _tableUsers,
        {
          'usr_password': _hashPassword(newPassword),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'usr_id = ?',
        whereArgs: [userId],
      );

      return updateResult > 0;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  /// Deactivate user
  Future<bool> deactivateUser(int userId) async {
    try {
      final db = await database;
      final result = await db.update(
        _tableUsers,
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'usr_id = ?',
        whereArgs: [userId],
      );

      return result > 0;
    } catch (e) {
      print('Error deactivating user: $e');
      return false;
    }
  }

  /// Get all active users
  Future<List<User>> getAllActiveUsers() async {
    try {
      final db = await database;
      final result = await db.query(
        _tableUsers,
        where: 'is_active = 1',
        orderBy: 'created_at DESC',
      );

      return result.map((map) => User.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Validate user data
  bool _isValidUser(User user) {
    return user.username.trim().isNotEmpty &&
        user.password.length >= 6 &&
        user.fullName?.trim().isNotEmpty == true &&
        _isValidEmail(user.email);
  }

  /// Validate email format
  bool _isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  // ============================= STUDENT MANAGEMENT METHODS =============================

  /// Get all students with class and level information
  Future<List<Student>> getAllStudents() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE s.is_active = 1
        ORDER BY s.full_name
      ''');

      return result.map((map) => Student.fromMap(map)).toList();
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  /// Get student by barcode
  Future<Student?> getStudentByBarcode(String barcode) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE s.barcode = ? AND s.is_active = 1
      ''', [barcode]);

      return result.isNotEmpty ? Student.fromMap(result.first) : null;
    } catch (e) {
      print('Error getting student by barcode: $e');
      return null;
    }
  }

  /// Get student by NFC tag ID
  Future<Student?> getStudentByNFC(String nfcTagId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE s.nfc_tag_id = ? AND s.is_active = 1
      ''', [nfcTagId]);

      return result.isNotEmpty ? Student.fromMap(result.first) : null;
    } catch (e) {
      print('Error getting student by NFC: $e');
      return null;
    }
  }

    /// Get student by NFC tag ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE s.student_id = ? AND s.is_active = 1
      ''', [studentId]);

      return result.isNotEmpty ? Student.fromMap(result.first) : null;
    } catch (e) {
      print('Error getting student by ID: $e');
      return null;
    }
  }

  // ============================= ATTENDANCE METHODS =============================

  /// Mark attendance for a student
  Future<bool> markAttendance(int studentId, String status, String markedBy, {String? notes}) async {
    try {
      final db = await database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final now = DateTime.now().toIso8601String();

      // Check if attendance already marked today
      final existing = await db.query(
        _tableAttendance,
        where: 'student_id = ? AND date = ?',
        whereArgs: [studentId, today],
      );

      if (existing.isNotEmpty) {
        // Update existing record
        final result = await db.update(
          _tableAttendance,
          {
            'status': status,
            'marked_by': markedBy,
            'marked_at': now,
            'notes': notes,
            'synced': 0,
          },
          where: 'student_id = ? AND date = ?',
          whereArgs: [studentId, today],
        );
        return result > 0;
      } else {
        // Insert new record
        final result = await db.insert(_tableAttendance, {
          'student_id': studentId,
          'date': today,
          'status': status,
          'marked_by': markedBy,
          'marked_at': now,
          'notes': notes,
          'synced': 0,
          'created_at': now,
        });
        return result > 0;
      }
    } catch (e) {
      print('Error marking attendance: $e');
      return false;
    }
  }

  /// Get today's attendance records
  Future<List<AttendanceLog>> getTodayAttendance() async {
    try {
      final db = await database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final result = await db.rawQuery('''
        SELECT a.*, s.full_name, s.reg_number, c.name as class_name
        FROM $_tableAttendance a
        JOIN $_tableStudents s ON a.student_id = s.student_id
        JOIN $_tableClasses c ON s.class_id = c.class_id
        WHERE a.date = ?
        ORDER BY a.marked_at DESC
      ''', [today]);

      return result.map((map) => AttendanceLog.fromMap(map)).toList();
    } catch (e) {
      print('Error getting today\'s attendance: $e');
      return [];
    }
  }

  // ============================= PAYMENT METHODS =============================

  /// Record a payment
  Future<bool> recordPayment(int studentId, double amount, String paymentType, 
      String paymentMethod, {String? receiptNumber, String? parentReason}) async {
    try {
      final db = await database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final now = DateTime.now().toIso8601String();

      final result = await db.insert(_tablePayments, {
        'student_id': studentId,
        'amount': amount,
        'date_paid': today,
        'payment_type': paymentType,
        'payment_method': paymentMethod,
        'receipt_number': receiptNumber,
        'parent_reason': parentReason,
        'synced': 0,
        'created_at': now,
      });

      return result > 0;
    } catch (e) {
      print('Error recording payment: $e');
      return false;
    }
  }

  /// Get student payments
  Future<List<Payment>> getStudentPayments(int studentId) async {
    try {
      final db = await database;
      final result = await db.query(
        _tablePayments,
        where: 'student_id = ?',
        whereArgs: [studentId],
        orderBy: 'date_paid DESC',
      );
      return result.map((map) => Payment.fromMap(map)).toList();
    } catch (e) {
      print('Error getting student payments: $e');
      return [];
    }
  }

  /// Get recent payments
  Future<List<Payment>> getRecentPayments({int limit = 50}) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT p.*, s.full_name, s.reg_number, c.name as class_name
        FROM $_tablePayments p
        JOIN $_tableStudents s ON p.student_id = s.student_id
        JOIN $_tableClasses c ON s.class_id = c.class_id
        ORDER BY p.created_at DESC
        LIMIT ?
      ''', [limit]);

      return result.map((map) => Payment.fromMap(map)).toList();
    } catch (e) {
      print('Error getting recent payments: $e');
      return [];
    }
  }

  /// Get total payments for a student
  Future<double> getStudentTotalPayments(int studentId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT SUM(amount) as total
        FROM $_tablePayments
        WHERE student_id = ?
      ''', [studentId]);

      if (result.isNotEmpty && result.first['total'] != null) {
        return (result.first['total'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error getting student total payments: $e');
      return 0.0;
    }
  }

  // ============================= DISCIPLINE METHODS =============================

  /// Record a discipline case
  Future<bool> recordDiscipline({
    required int studentId,
    required String incidentDate,
    required int marksDeducted,
    required String reason,
    required String severity,
    required String recordedBy,
    String? actionTaken,
  }) async {
    try {
      final db = await database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final now = DateTime.now().toIso8601String();

      final result = await db.insert(_tableDiscipline, {
        'student_id': studentId,
        'date': today,
        'incident_date': incidentDate,
        'marks_deducted': marksDeducted,
        'reason': reason,
        'severity': severity,
        'action_taken': actionTaken,
        'recorded_by': recordedBy,
        'synced': 0,
        'created_at': now,
      });

      return result > 0;
    } catch (e) {
      print('Error recording discipline: $e');
      return false;
    }
  }

  /// Get student discipline records
  Future<List<DisciplineRecord>> getStudentDisciplineRecords(int studentId) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableDiscipline,
        where: 'student_id = ?',
        whereArgs: [studentId],
        orderBy: 'incident_date DESC',
      );

      return result.map((map) => DisciplineRecord.fromMap(map)).toList();
    } catch (e) {
      print('Error getting student discipline records: $e');
      return [];
    }
  }

  /// Get recent discipline cases
  Future<List<DisciplineRecord>> getRecentDisciplineCases({int limit = 50}) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT d.*, s.full_name, s.reg_number, c.name as class_name
        FROM $_tableDiscipline d
        JOIN $_tableStudents s ON d.student_id = s.student_id
        JOIN $_tableClasses c ON s.class_id = c.class_id
        ORDER BY d.created_at DESC
        LIMIT ?
      ''', [limit]);

      return result.map((map) => DisciplineRecord.fromMap(map)).toList();
    } catch (e) {
      print('Error getting recent discipline cases: $e');
      return [];
    }
  }

  /// Get total discipline marks deducted for a student
  Future<int> getStudentTotalDisciplineMarks(int studentId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT SUM(marks_deducted) as total
        FROM $_tableDiscipline
        WHERE student_id = ?
      ''', [studentId]);

      if (result.isNotEmpty && result.first['total'] != null) {
        return (result.first['total'] as num).toInt();
      }
      return 0;
    } catch (e) {
      print('Error getting student total discipline marks: $e');
      return 0;
    }
  }

  // ============================= LEVEL AND CLASS METHODS =============================

  /// Get all levels
  Future<List<Level>> getAllLevels() async {
    try {
      final db = await database;
      final result = await db.query(
        _tableLevels,
        orderBy: 'name',
      );

      return result.map((map) => Level.fromMap(map)).toList();
    } catch (e) {
      print('Error getting levels: $e');
      return [];
    }
  }

  /// Get all classes
  Future<List<SchoolClass>> getAllClasses() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT c.*, l.name as level_name
        FROM $_tableClasses c
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE c.is_active = 1
        ORDER BY l.name, c.name
      ''');

      return result.map((map) => SchoolClass.fromMap(map)).toList();
    } catch (e) {
      print('Error getting classes: $e');
      return [];
    }
  }

  /// Get classes by level
  Future<List<SchoolClass>> getClassesByLevel(int levelId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT c.*, l.name as level_name
        FROM $_tableClasses c
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE c.level_id = ? AND c.is_active = 1
        ORDER BY c.name
      ''', [levelId]);

      return result.map((map) => SchoolClass.fromMap(map)).toList();
    } catch (e) {
      print('Error getting classes by level: $e');
      return [];
    }
  }

  /// Get students by class
  Future<List<Student>> getStudentsByClass(int classId) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE s.class_id = ? AND s.is_active = 1
        ORDER BY s.full_name
      ''', [classId]);

      return result.map((map) => Student.fromMap(map)).toList();
    } catch (e) {
      print('Error getting students by class: $e');
      return [];
    }
  }

  // ============================= STATISTICS METHODS =============================

  /// Calculate and update student statistics
  Future<bool> updateStudentStatistics(int studentId, String academicYear) async {
    try {
      final db = await database;

      // Get attendance statistics
      final attendanceStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_records,
          SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) as present_count,
          SUM(CASE WHEN status = 'Absent' THEN 1 ELSE 0 END) as absent_count,
          SUM(CASE WHEN status = 'Late' THEN 1 ELSE 0 END) as late_count,
          SUM(CASE WHEN status = 'Excused' THEN 1 ELSE 0 END) as excused_count
        FROM $_tableAttendance
        WHERE student_id = ?
      ''', [studentId]);

      // Get discipline statistics
      final disciplineStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as discipline_cases,
          SUM(marks_deducted) as total_marks_deducted
        FROM $_tableDiscipline
        WHERE student_id = ?
      ''', [studentId]);

      if (attendanceStats.isNotEmpty && disciplineStats.isNotEmpty) {
        final attendanceData = attendanceStats.first;
        final disciplineData = disciplineStats.first;

        final totalDays = (attendanceData['total_records'] as num).toInt();
        final presentCount = (attendanceData['present_count'] as num).toInt();
        final absentCount = (attendanceData['absent_count'] as num).toInt();
        final lateCount = (attendanceData['late_count'] as num).toInt();
        final excusedCount = (attendanceData['excused_count'] as num).toInt();
        final disciplineCases = (disciplineData['discipline_cases'] as num).toInt();
        final totalMarksDeducted = (disciplineData['total_marks_deducted'] as num?)?.toInt() ?? 0;

        final attendancePercentage = totalDays > 0 ? (presentCount / totalDays) * 100 : 0.0;
        final behaviorRating = _calculateBehaviorRating(disciplineCases, totalMarksDeducted);

        // Insert or update statistics
        await db.rawQuery('''
          INSERT OR REPLACE INTO $_tableStatistics (
            student_id, academic_year, total_school_days, present_count, absent_count,
            late_count, excused_count, discipline_cases, total_discipline_marks_deducted,
            attendance_percentage, behavior_rating, last_calculated
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          studentId, academicYear, totalDays, presentCount, absentCount,
          lateCount, excusedCount, disciplineCases, totalMarksDeducted,
          attendancePercentage, behaviorRating, DateTime.now().toIso8601String()
        ]);

        return true;
      }
      return false;
    } catch (e) {
      print('Error updating student statistics: $e');
      return false;
    }
  }

  /// Calculate behavior rating based on discipline records
  String _calculateBehaviorRating(int disciplineCases, int totalMarksDeducted) {
    if (disciplineCases == 0 && totalMarksDeducted == 0) {
      return 'Excellent';
    } else if (disciplineCases <= 2 && totalMarksDeducted <= 10) {
      return 'Good';
    } else if (disciplineCases <= 5 && totalMarksDeducted <= 25) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  /// Get student statistics
  Future<Map<String, dynamic>?> getStudentStatistics(int studentId, String academicYear) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableStatistics,
        where: 'student_id = ? AND academic_year = ?',
        whereArgs: [studentId, academicYear],
      );

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error getting student statistics: $e');
      return null;
    }
  }

  // ============================= HOLIDAY METHODS =============================

  /// Add holiday
  Future<bool> addHoliday(String date, String reason, {String holidayType = 'Public'}) async {
    try {
      final db = await database;
      final result = await db.insert(_tableHolidays, {
        'date': date,
        'reason': reason,
        'holiday_type': holidayType,
        'created_at': DateTime.now().toIso8601String(),
      });

      return result > 0;
    } catch (e) {
      print('Error adding holiday: $e');
      return false;
    }
  }

  /// Check if date is holiday
  Future<bool> isHoliday(String date) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableHolidays,
        where: 'date = ? AND is_active = 1',
        whereArgs: [date],
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error checking holiday: $e');
      return false;
    }
  }

  /// Get all holidays
  Future<List<Map<String, dynamic>>> getAllHolidays() async {
    try {
      final db = await database;
      final result = await db.query(
        _tableHolidays,
        where: 'is_active = 1',
        orderBy: 'date DESC',
      );

      return result;
    } catch (e) {
      print('Error getting holidays: $e');
      return [];
    }
  }

  // ============================= SEARCH METHODS =============================

  /// Search students by name or registration number
  Future<List<Student>> searchStudents(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final db = await database;
      final searchTerm = '%${query.trim()}%';
      
      final result = await db.rawQuery('''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE (s.full_name LIKE ? OR s.reg_number LIKE ?) AND s.is_active = 1
        ORDER BY s.full_name
        LIMIT 20
      ''', [searchTerm, searchTerm]);

      return result.map((map) => Student.fromMap(map)).toList();
    } catch (e) {
      print('Error searching students: $e');
      return [];
    }
  }

  // ============================= BACKUP AND RESTORE METHODS =============================

  /// Get database backup data
  Future<Map<String, List<Map<String, dynamic>>>> getDatabaseBackup() async {
    try {
      final db = await database;
      final backup = <String, List<Map<String, dynamic>>>{};

      final tables = [
        _tableUsers, _tableLevels, _tableClasses, _tableStudents,
        _tableAttendance, _tablePayments, _tableDiscipline, _tableHolidays
      ];

      for (String table in tables) {
        final data = await db.query(table);
        backup[table] = data;
      }

      return backup;
    } catch (e) {
      print('Error creating backup: $e');
      return {};
    }
  }

  /// Clear all data (for testing purposes)
  Future<bool> clearAllData() async {
    try {
      final db = await database;
      final batch = db.batch();

      // Clear data in reverse order of dependencies
      batch.delete(_tableSyncQueue);
      batch.delete(_tableStatistics);
      batch.delete(_tableHolidays);
      batch.delete(_tableDiscipline);
      batch.delete(_tablePayments);
      batch.delete(_tableAttendance);
      batch.delete(_tableStudents);
      batch.delete(_tableClasses);
      batch.delete(_tableLevels);
      batch.delete(_tableUsers);

      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete database file (for complete reset)
  Future<bool> deleteDatabase() async {
    try {
      await close();
      final databasePath = await getDatabasesPath();
      final file = File(databasePath + '/' + _databaseName);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
      return true;
    } catch (e) {
      print('Error deleting database: $e');
      return false;
    }
  }
}

// ============================= RESULT CLASSES =============================

/// Authentication result class
class AuthResult {
  final bool success;
  final String? message;
  final User? user;

  AuthResult._(this.success, this.message, this.user);

  factory AuthResult.success(User user) => AuthResult._(true, null, user);
  factory AuthResult.failure(String message) => AuthResult._(false, message, null);
}

/// Create user result class
class CreateUserResult {
  final bool success;
  final String? message;
  final User? user;

  CreateUserResult._(this.success, this.message, this.user);

  factory CreateUserResult.success(User user) => CreateUserResult._(true, null, user);
  factory CreateUserResult.failure(String message) => CreateUserResult._(false, message, null);
}

/// Database exception class
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}