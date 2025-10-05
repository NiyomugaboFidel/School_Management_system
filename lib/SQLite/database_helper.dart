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
import '../models/attendance_result.dart';

/// Database Helper for School Management System
/// Handles all database operations including user authentication,
/// student management, attendance tracking, and payments
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static bool _isInitializing = false;

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
    if (_database != null) return _database!;

    // Prevent multiple simultaneous initializations
    if (_isInitializing) {
      // Wait for the current initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _database!;
    }

    _isInitializing = true;
    try {
      _database = await _initDatabase();
      return _database!;
    } finally {
      _isInitializing = false;
    }
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

    // Insert initial data in background to avoid blocking
    _insertInitialDataInBackground(db);
  }

  /// Insert initial data in background to avoid blocking UI
  void _insertInitialDataInBackground(Database db) {
    Future.microtask(() async {
      try {
        await _insertInitialData(db);
        print('Database initialization completed successfully');
      } catch (e) {
        print('Error inserting initial data: $e');
      }
    });
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
        gender TEXT DEFAULT 'Unspecified',
        profile_image TEXT DEFAULT 'https://cdn-icons-png.flaticon.com/512/4537/4537019.png',
        phone_number TEXT,
        address TEXT,
        date_of_birth TEXT,
        role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'teacher', 'user')),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
        last_login TEXT,
        notes TEXT,
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
        gender TEXT DEFAULT 'Unspecified',
        profile_image TEXT DEFAULT 'https://cdn-icons-png.flaticon.com/512/4537/4537019.png',
        phone_number TEXT,
        address TEXT,
        date_of_birth TEXT,
        class_id INTEGER NOT NULL,
        barcode TEXT UNIQUE,
        nfc_tag_id TEXT UNIQUE,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
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
    batch.execute(
      'CREATE INDEX idx_students_class_id ON $_tableStudents(class_id)',
    );
    batch.execute(
      'CREATE INDEX idx_students_reg_number ON $_tableStudents(reg_number)',
    );
    batch.execute(
      'CREATE INDEX idx_students_barcode ON $_tableStudents(barcode)',
    );
    batch.execute(
      'CREATE INDEX idx_students_nfc_tag_id ON $_tableStudents(nfc_tag_id)',
    );

    // Attendance indexes
    batch.execute(
      'CREATE INDEX idx_attendance_student_id ON $_tableAttendance(student_id)',
    );
    batch.execute(
      'CREATE INDEX idx_attendance_date ON $_tableAttendance(date)',
    );
    batch.execute(
      'CREATE INDEX idx_attendance_synced ON $_tableAttendance(synced)',
    );

    // Payments indexes
    batch.execute(
      'CREATE INDEX idx_payments_student_id ON $_tablePayments(student_id)',
    );
    batch.execute(
      'CREATE INDEX idx_payments_date ON $_tablePayments(date_paid)',
    );
    batch.execute(
      'CREATE INDEX idx_payments_synced ON $_tablePayments(synced)',
    );

    // Classes indexes
    batch.execute(
      'CREATE INDEX idx_classes_level_id ON $_tableClasses(level_id)',
    );
    batch.execute(
      'CREATE INDEX idx_classes_active ON $_tableClasses(is_active)',
    );
  }

  /// Insert initial test data
  Future<void> _insertInitialData(Database db) async {
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    // Insert default users for testing
    await _insertDefaultUsers(batch, now);

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

  /// Insert default users for testing
  Future<void> _insertDefaultUsers(Batch batch, String now) async {
    final defaultUsers = [
      {
        'full_name': 'System Administrator',
        'email': 'admin@school.com',
        'usr_name': 'admin',
        'usr_password': _hashPassword('admin123'),
        'role': 'admin',
        'gender': 'Unspecified',
        'profile_image':
            'https://cdn-icons-png.flaticon.com/512/4537/4537019.png',
        'phone_number': '',
        'address': '',
        'date_of_birth': '',
        'is_active': 1,
        'notes': '',
        'created_at': now,
        'updated_at': now,
      },
      {
        'full_name': 'John Teacher',
        'email': 'teacher@school.com',
        'usr_name': 'teacher',
        'usr_password': _hashPassword('teacher123'),
        'role': 'teacher',
        'gender': 'Male',
        'profile_image':
            'https://cdn-icons-png.flaticon.com/512/4537/4537019.png',
        'phone_number': '',
        'address': '',
        'date_of_birth': '',
        'is_active': 1,
        'notes': '',
        'created_at': now,
        'updated_at': now,
      },
      {
        'full_name': 'Regular User',
        'email': 'user@school.com',
        'usr_name': 'user',
        'usr_password': _hashPassword('user123'),
        'role': 'user',
        'gender': 'Female',
        'profile_image':
            'https://cdn-icons-png.flaticon.com/512/4537/4537019.png',
        'phone_number': '',
        'address': '',
        'date_of_birth': '',
        'is_active': 1,
        'notes': '',
        'created_at': now,
        'updated_at': now,
      },
      {
        'full_name': 'Fidele Niyomugabo',
        'email': 'fidele@example.com',
        'usr_name': 'fidele',
        'usr_password': _hashPassword('1234678'),
        'role': 'admin',
        'gender': 'Male',
        'profile_image':
            'https://cdn-icons-png.flaticon.com/512/4537/4537019.png',
        'phone_number': '',
        'address': '',
        'date_of_birth': '',
        'is_active': 1,
        'notes': '',
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final user in defaultUsers) {
      batch.insert(_tableUsers, user);
    }

    print('Default users inserted successfully');
  }

  /// Insert classes for each level and section
  Future<void> _insertClasses(
    Batch batch,
    List<String> levels,
    String now,
  ) async {
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
    final firstNames = [
      'John',
      'Jane',
      'Alice',
      'Bob',
      'Charlie',
      'Diana',
      'Eve',
      'Frank',
      'Grace',
      'Henry',
    ];
    final lastNames = [
      'Smith',
      'Johnson',
      'Brown',
      'Davis',
      'Wilson',
      'Miller',
      'Taylor',
      'Anderson',
      'Thomas',
      'Jackson',
    ];
    final now = DateTime.now().toIso8601String();

    for (int i = 1; i <= 10; i++) {
      final studentId = 20240000 + i;
      final student = _createTestStudent(
        i,
        studentId,
        firstNames,
        lastNames,
        random,
        now,
      );

      await db.insert(_tableStudents, student);
      await _updateClassStudentCount(db, student['class_id'], now);
      await _insertSampleAttendance(db, studentId);
      await _insertSamplePayments(db, studentId);
    }
  }

  /// Create a test student record
  Map<String, dynamic> _createTestStudent(
    int index,
    int studentId,
    List<String> firstNames,
    List<String> lastNames,
    Random random,
    String now,
  ) {
    final firstName = firstNames[index - 1];
    final lastName = lastNames[random.nextInt(lastNames.length)];
    final classId = random.nextInt(18) + 1;
    // Alternate gender for demo
    final gender = index % 2 == 0 ? 'Female' : 'Male';
    // Demo profile images by gender
    final profileImage =
        gender == 'Male'
            ? 'https://cdn-icons-png.flaticon.com/512/4537/4537019.png'
            : 'https://cdn-icons-png.flaticon.com/512/4730/4730811.png'; // You can use a different icon for female if desired
    // Demo addresses
    final addresses = [
      '123 Main St, Kigali',
      '456 Elm St, Huye',
      '789 Oak St, Musanze',
      '101 Pine St, Rubavu',
      '202 Maple St, Rusizi',
      '303 Cedar St, Nyagatare',
      '404 Birch St, Rwamagana',
      '505 Spruce St, Gicumbi',
      '606 Willow St, Muhanga',
      '707 Aspen St, Nyamasheke',
    ];
    final address = addresses[(index - 1) % addresses.length];
    // Demo phone numbers
    final phoneNumber =
        '+2507${random.nextInt(100000000).toString().padLeft(8, '0')}';
    // Demo date of birth (random between 2005-2010)
    final year = 2005 + random.nextInt(6);
    final month = 1 + random.nextInt(12);
    final day = 1 + random.nextInt(28);
    final dateOfBirth =
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    // Demo notes
    final notes = 'Demo student for testing.';

    return {
      'student_id': studentId,
      'reg_number': 'REG${studentId.toString().substring(4)}',
      'full_name': '$firstName $lastName',
      'gender': gender,
      'profile_image': profileImage,
      'phone_number': phoneNumber,
      'address': address,
      'date_of_birth': dateOfBirth,
      'class_id': classId,
      'barcode': 'BC$studentId',
      'nfc_tag_id': 'NFC$studentId',
      'is_active': 1,
      'notes': notes,
      'created_at': now,
      'updated_at': now,
    };
  }

  /// Update class student count
  Future<void> _updateClassStudentCount(
    Database db,
    int classId,
    String now,
  ) async {
    await db.rawUpdate(
      '''
      UPDATE $_tableClasses 
      SET student_count = student_count + 1, updated_at = ?
      WHERE class_id = ?
    ''',
      [now, classId],
    );
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
  Future<bool> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
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
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
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
      final result = await db.rawQuery(
        '''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE s.barcode = ? AND s.is_active = 1
      ''',
        [barcode],
      );

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
      final result = await db.rawQuery(
        '''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE s.nfc_tag_id = ? AND s.is_active = 1
      ''',
        [nfcTagId],
      );

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
      final result = await db.rawQuery(
        '''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE s.student_id = ? AND s.is_active = 1
      ''',
        [studentId],
      );

      return result.isNotEmpty ? Student.fromMap(result.first) : null;
    } catch (e) {
      print('Error getting student by ID: $e');
      return null;
    }
  }

  // ============================= ATTENDANCE METHODS =============================

  /// Mark attendance for a student with duplicate detection and time-based status
  Future<AttendanceResult> markAttendance(
    int studentId,
    String status,
    String markedBy, {
    String? notes,
    DateTime? checkInTime,
  }) async {
    try {
      final db = await database;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final now = checkInTime ?? DateTime.now();
      final nowString = now.toIso8601String();

      // Check if attendance already marked today
      final existing = await db.query(
        _tableAttendance,
        where: 'student_id = ? AND date = ?',
        whereArgs: [studentId, today],
      );

      if (existing.isNotEmpty) {
        final existingRecord = AttendanceLog.fromMap(existing.first);
        final existingTime = existingRecord.markedAt;

        // If existing record is newer, don't update
        if (existingTime.isAfter(now)) {
          return AttendanceResult.duplicate(
            existingStatus: existingRecord.status.toString(),
            existingTime: existingTime,
            newStatus: status,
            newTime: now,
          );
        }

        // Update existing record with newer time
        final result = await db.update(
          _tableAttendance,
          {
            'status': status,
            'marked_by': markedBy,
            'marked_at': nowString,
            'notes': notes,
            'synced': 0,
          },
          where: 'student_id = ? AND date = ?',
          whereArgs: [studentId, today],
        );

        return result > 0
            ? AttendanceResult.updated(
              previousStatus: existingRecord.status.value,
              newStatus: status,
              time: now,
            )
            : AttendanceResult.failure('Failed to update attendance');
      } else {
        // Insert new record
        final result = await db.insert(_tableAttendance, {
          'student_id': studentId,
          'date': today,
          'status': status,
          'marked_by': markedBy,
          'marked_at': nowString,
          'notes': notes,
          'synced': 0,
          'created_at': nowString,
        });

        return result > 0
            ? AttendanceResult.success(status: status, time: now)
            : AttendanceResult.failure('Failed to mark attendance');
      }
    } catch (e) {
      print('Error marking attendance: $e');
      return AttendanceResult.failure('Error marking attendance: $e');
    }
  }

  /// Get today's attendance records
  Future<List<AttendanceLog>> getTodayAttendance() async {
    try {
      final db = await database;
      final today = DateTime.now().toIso8601String().split('T')[0];

      final result = await db.rawQuery(
        '''
        SELECT a.*, s.full_name, s.reg_number, c.name as class_name
        FROM $_tableAttendance a
        JOIN $_tableStudents s ON a.student_id = s.student_id
        JOIN $_tableClasses c ON s.class_id = c.class_id
        WHERE a.date = ?
        ORDER BY a.marked_at DESC
      ''',
        [today],
      );

      return result.map((map) => AttendanceLog.fromMap(map)).toList();
    } catch (e) {
      print('Error getting today\'s attendance: $e');
      return [];
    }
  }

  /// Get attendance records for a specific date
  Future<List<AttendanceLog>> getAttendanceForDate(DateTime date) async {
    try {
      final db = await database;
      final dateString = date.toIso8601String().split('T')[0];

      final result = await db.rawQuery(
        '''
        SELECT a.*, s.full_name, s.reg_number, c.name as class_name
        FROM $_tableAttendance a
        JOIN $_tableStudents s ON a.student_id = s.student_id
        JOIN $_tableClasses c ON s.class_id = c.class_id
        WHERE a.date = ?
        ORDER BY a.marked_at DESC
      ''',
        [dateString],
      );

      return result.map((map) => AttendanceLog.fromMap(map)).toList();
    } catch (e) {
      print('Error getting attendance for date: $e');
      return [];
    }
  }

// REMOVED FOR ATTENDANCE-ONLY:   // ============================= PAYMENT METHODS =============================
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Record a payment
// REMOVED FOR ATTENDANCE-ONLY:   Future<bool> recordPayment(
// REMOVED FOR ATTENDANCE-ONLY:     int studentId,
// REMOVED FOR ATTENDANCE-ONLY:     double amount,
// REMOVED FOR ATTENDANCE-ONLY:     String paymentType,
// REMOVED FOR ATTENDANCE-ONLY:     String paymentMethod, {
// REMOVED FOR ATTENDANCE-ONLY:     String? receiptNumber,
// REMOVED FOR ATTENDANCE-ONLY:     String? parentReason,
// REMOVED FOR ATTENDANCE-ONLY:   }) async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final today = DateTime.now().toIso8601String().split('T')[0];
// REMOVED FOR ATTENDANCE-ONLY:       final now = DateTime.now().toIso8601String();
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.insert(_tablePayments, {
// REMOVED FOR ATTENDANCE-ONLY:         'student_id': studentId,
// REMOVED FOR ATTENDANCE-ONLY:         'amount': amount,
// REMOVED FOR ATTENDANCE-ONLY:         'date_paid': today,
// REMOVED FOR ATTENDANCE-ONLY:         'payment_type': paymentType,
// REMOVED FOR ATTENDANCE-ONLY:         'payment_method': paymentMethod,
// REMOVED FOR ATTENDANCE-ONLY:         'receipt_number': receiptNumber,
// REMOVED FOR ATTENDANCE-ONLY:         'parent_reason': parentReason,
// REMOVED FOR ATTENDANCE-ONLY:         'synced': 0,
// REMOVED FOR ATTENDANCE-ONLY:         'created_at': now,
// REMOVED FOR ATTENDANCE-ONLY:       });
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       return result > 0;
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error recording payment: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return false;
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Get student payments
// REMOVED FOR ATTENDANCE-ONLY:   Future<List<Payment>> getStudentPayments(int studentId) async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.query(
// REMOVED FOR ATTENDANCE-ONLY:         _tablePayments,
// REMOVED FOR ATTENDANCE-ONLY:         where: 'student_id = ?',
// REMOVED FOR ATTENDANCE-ONLY:         whereArgs: [studentId],
// REMOVED FOR ATTENDANCE-ONLY:         orderBy: 'date_paid DESC',
// REMOVED FOR ATTENDANCE-ONLY:       );
// REMOVED FOR ATTENDANCE-ONLY:       return result.map((map) => Payment.fromMap(map)).toList();
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error getting student payments: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return [];
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Get recent payments
// REMOVED FOR ATTENDANCE-ONLY:   Future<List<Payment>> getRecentPayments({int limit = 50}) async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.rawQuery(
// REMOVED FOR ATTENDANCE-ONLY:         '''
// REMOVED FOR ATTENDANCE-ONLY:         SELECT p.*, s.full_name, s.reg_number, c.name as class_name
// REMOVED FOR ATTENDANCE-ONLY:         FROM $_tablePayments p
// REMOVED FOR ATTENDANCE-ONLY:         JOIN $_tableStudents s ON p.student_id = s.student_id
// REMOVED FOR ATTENDANCE-ONLY:         JOIN $_tableClasses c ON s.class_id = c.class_id
// REMOVED FOR ATTENDANCE-ONLY:         ORDER BY p.created_at DESC
// REMOVED FOR ATTENDANCE-ONLY:         LIMIT ?
// REMOVED FOR ATTENDANCE-ONLY:       ''',
// REMOVED FOR ATTENDANCE-ONLY:         [limit],
// REMOVED FOR ATTENDANCE-ONLY:       );
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       return result.map((map) => Payment.fromMap(map)).toList();
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error getting recent payments: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return [];
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Get total payments for a student
// REMOVED FOR ATTENDANCE-ONLY:   Future<double> getStudentTotalPayments(int studentId) async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.rawQuery(
// REMOVED FOR ATTENDANCE-ONLY:         '''
// REMOVED FOR ATTENDANCE-ONLY:         SELECT SUM(amount) as total
// REMOVED FOR ATTENDANCE-ONLY:         FROM $_tablePayments
// REMOVED FOR ATTENDANCE-ONLY:         WHERE student_id = ?
// REMOVED FOR ATTENDANCE-ONLY:       ''',
// REMOVED FOR ATTENDANCE-ONLY:         [studentId],
// REMOVED FOR ATTENDANCE-ONLY:       );
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       if (result.isNotEmpty && result.first['total'] != null) {
// REMOVED FOR ATTENDANCE-ONLY:         return (result.first['total'] as num).toDouble();
// REMOVED FOR ATTENDANCE-ONLY:       }
// REMOVED FOR ATTENDANCE-ONLY:       return 0.0;
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error getting student total payments: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return 0.0;
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   // ============================= DISCIPLINE METHODS =============================
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Record a discipline case
// REMOVED FOR ATTENDANCE-ONLY:   Future<bool> recordDiscipline({
// REMOVED FOR ATTENDANCE-ONLY:     required int studentId,
// REMOVED FOR ATTENDANCE-ONLY:     required String incidentDate,
// REMOVED FOR ATTENDANCE-ONLY:     required int marksDeducted,
// REMOVED FOR ATTENDANCE-ONLY:     required String reason,
// REMOVED FOR ATTENDANCE-ONLY:     required String severity,
// REMOVED FOR ATTENDANCE-ONLY:     required String recordedBy,
// REMOVED FOR ATTENDANCE-ONLY:     String? actionTaken,
// REMOVED FOR ATTENDANCE-ONLY:   }) async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final today = DateTime.now().toIso8601String().split('T')[0];
// REMOVED FOR ATTENDANCE-ONLY:       final now = DateTime.now().toIso8601String();
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.insert(_tableDiscipline, {
// REMOVED FOR ATTENDANCE-ONLY:         'student_id': studentId,
// REMOVED FOR ATTENDANCE-ONLY:         'date': today,
// REMOVED FOR ATTENDANCE-ONLY:         'incident_date': incidentDate,
// REMOVED FOR ATTENDANCE-ONLY:         'marks_deducted': marksDeducted,
// REMOVED FOR ATTENDANCE-ONLY:         'reason': reason,
// REMOVED FOR ATTENDANCE-ONLY:         'severity': severity,
// REMOVED FOR ATTENDANCE-ONLY:         'action_taken': actionTaken,
// REMOVED FOR ATTENDANCE-ONLY:         'recorded_by': recordedBy,
// REMOVED FOR ATTENDANCE-ONLY:         'synced': 0,
// REMOVED FOR ATTENDANCE-ONLY:         'created_at': now,
// REMOVED FOR ATTENDANCE-ONLY:       });
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       return result > 0;
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error recording discipline: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return false;
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Get student discipline records
// REMOVED FOR ATTENDANCE-ONLY:   Future<List<DisciplineRecord>> getStudentDisciplineRecords(
// REMOVED FOR ATTENDANCE-ONLY:     int studentId,
// REMOVED FOR ATTENDANCE-ONLY:   ) async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.query(
// REMOVED FOR ATTENDANCE-ONLY:         _tableDiscipline,
// REMOVED FOR ATTENDANCE-ONLY:         where: 'student_id = ?',
// REMOVED FOR ATTENDANCE-ONLY:         whereArgs: [studentId],
// REMOVED FOR ATTENDANCE-ONLY:         orderBy: 'incident_date DESC',
// REMOVED FOR ATTENDANCE-ONLY:       );
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       return result.map((map) => DisciplineRecord.fromMap(map)).toList();
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error getting student discipline records: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return [];
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Get recent discipline cases
// REMOVED FOR ATTENDANCE-ONLY:   Future<List<DisciplineRecord>> getRecentDisciplineCases({
// REMOVED FOR ATTENDANCE-ONLY:     int limit = 50,
// REMOVED FOR ATTENDANCE-ONLY:   }) async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.rawQuery(
// REMOVED FOR ATTENDANCE-ONLY:         '''
// REMOVED FOR ATTENDANCE-ONLY:         SELECT d.*, s.full_name, s.reg_number, c.name as class_name
// REMOVED FOR ATTENDANCE-ONLY:         FROM $_tableDiscipline d
// REMOVED FOR ATTENDANCE-ONLY:         JOIN $_tableStudents s ON d.student_id = s.student_id
// REMOVED FOR ATTENDANCE-ONLY:         JOIN $_tableClasses c ON s.class_id = c.class_id
// REMOVED FOR ATTENDANCE-ONLY:         ORDER BY d.created_at DESC
// REMOVED FOR ATTENDANCE-ONLY:         LIMIT ?
// REMOVED FOR ATTENDANCE-ONLY:       ''',
// REMOVED FOR ATTENDANCE-ONLY:         [limit],
// REMOVED FOR ATTENDANCE-ONLY:       );
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       return result.map((map) => DisciplineRecord.fromMap(map)).toList();
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error getting recent discipline cases: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return [];
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Get total discipline marks deducted for a student
// REMOVED FOR ATTENDANCE-ONLY:   Future<int> getStudentTotalDisciplineMarks(int studentId) async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.rawQuery(
// REMOVED FOR ATTENDANCE-ONLY:         '''
// REMOVED FOR ATTENDANCE-ONLY:         SELECT SUM(marks_deducted) as total
// REMOVED FOR ATTENDANCE-ONLY:         FROM $_tableDiscipline
// REMOVED FOR ATTENDANCE-ONLY:         WHERE student_id = ?
// REMOVED FOR ATTENDANCE-ONLY:       ''',
// REMOVED FOR ATTENDANCE-ONLY:         [studentId],
// REMOVED FOR ATTENDANCE-ONLY:       );
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       if (result.isNotEmpty && result.first['total'] != null) {
// REMOVED FOR ATTENDANCE-ONLY:         return (result.first['total'] as num).toInt();
// REMOVED FOR ATTENDANCE-ONLY:       }
// REMOVED FOR ATTENDANCE-ONLY:       return 0;
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error getting student total discipline marks: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return 0;
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }

  // ============================= LEVEL AND CLASS METHODS =============================

  /// Get all levels
  Future<List<Level>> getAllLevels() async {
    try {
      final db = await database;
      final result = await db.query(_tableLevels, orderBy: 'name');

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
      final result = await db.rawQuery(
        '''
        SELECT c.*, l.name as level_name
        FROM $_tableClasses c
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE c.level_id = ? AND c.is_active = 1
        ORDER BY c.name
      ''',
        [levelId],
      );

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
      final result = await db.rawQuery(
        '''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE s.class_id = ? AND s.is_active = 1
        ORDER BY s.full_name
      ''',
        [classId],
      );

      return result.map((map) => Student.fromMap(map)).toList();
    } catch (e) {
      print('Error getting students by class: $e');
      return [];
    }
  }

  // ============================= STATISTICS METHODS =============================

  /// Calculate and update student statistics
  Future<bool> updateStudentStatistics(
    int studentId,
    String academicYear,
  ) async {
    try {
      final db = await database;

      // Get attendance statistics
      final attendanceStats = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_records,
          SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) as present_count,
          SUM(CASE WHEN status = 'Absent' THEN 1 ELSE 0 END) as absent_count,
          SUM(CASE WHEN status = 'Late' THEN 1 ELSE 0 END) as late_count,
          SUM(CASE WHEN status = 'Excused' THEN 1 ELSE 0 END) as excused_count
        FROM $_tableAttendance
        WHERE student_id = ?
      ''',
        [studentId],
      );

      // Get discipline statistics
      final disciplineStats = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as discipline_cases,
          SUM(marks_deducted) as total_marks_deducted
        FROM $_tableDiscipline
        WHERE student_id = ?
      ''',
        [studentId],
      );

      if (attendanceStats.isNotEmpty && disciplineStats.isNotEmpty) {
        final attendanceData = attendanceStats.first;
        final disciplineData = disciplineStats.first;

        final totalDays = (attendanceData['total_records'] as num).toInt();
        final presentCount = (attendanceData['present_count'] as num).toInt();
        final absentCount = (attendanceData['absent_count'] as num).toInt();
        final lateCount = (attendanceData['late_count'] as num).toInt();
        final excusedCount = (attendanceData['excused_count'] as num).toInt();
        final disciplineCases =
            (disciplineData['discipline_cases'] as num).toInt();
        final totalMarksDeducted =
            (disciplineData['total_marks_deducted'] as num?)?.toInt() ?? 0;

        final attendancePercentage =
            totalDays > 0 ? (presentCount / totalDays) * 100 : 0.0;
        final behaviorRating = _calculateBehaviorRating(
          disciplineCases,
          totalMarksDeducted,
        );

        // Insert or update statistics
        await db.rawQuery(
          '''
          INSERT OR REPLACE INTO $_tableStatistics (
            student_id, academic_year, total_school_days, present_count, absent_count,
            late_count, excused_count, discipline_cases, total_discipline_marks_deducted,
            attendance_percentage, behavior_rating, last_calculated
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            studentId,
            academicYear,
            totalDays,
            presentCount,
            absentCount,
            lateCount,
            excusedCount,
            disciplineCases,
            totalMarksDeducted,
            attendancePercentage,
            behaviorRating,
            DateTime.now().toIso8601String(),
          ],
        );

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
  Future<Map<String, dynamic>?> getStudentStatistics(
    int studentId,
    String academicYear,
  ) async {
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
  Future<bool> addHoliday(
    String date,
    String reason, {
    String holidayType = 'Public',
  }) async {
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

      final result = await db.rawQuery(
        '''
        SELECT s.*, c.name as class_name, l.name as level_name
        FROM $_tableStudents s
        JOIN $_tableClasses c ON s.class_id = c.class_id
        JOIN $_tableLevels l ON c.level_id = l.level_id
        WHERE (s.full_name LIKE ? OR s.reg_number LIKE ?) AND s.is_active = 1
        ORDER BY s.full_name
        LIMIT 20
      ''',
        [searchTerm, searchTerm],
      );

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
        _tableUsers,
        _tableLevels,
        _tableClasses,
        _tableStudents,
        _tableAttendance,
        _tablePayments,
        _tableDiscipline,
        _tableHolidays,
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
    } catch (e) {
      print('Error deleting database: $e');
      return false;
    }
  }

  // ============================= SYNC METHODS =============================

  /// Get unsynced attendance records
  Future<List<AttendanceLog>> getUnsyncedAttendance() async {
    try {
      final db = await database;
      final result = await db.query(
        _tableAttendance,
        where: 'synced = 0',
        orderBy: 'marked_at DESC',
      );

      return result.map((map) => AttendanceLog.fromMap(map)).toList();
    } catch (e) {
      print('Error getting unsynced attendance: $e');
      return [];
    }
  }

  /// Update attendance sync status
  Future<bool> updateAttendanceSyncStatus(int id, bool synced) async {
    try {
      final db = await database;
      final result = await db.update(
        _tableAttendance,
        {
          'synced': synced ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return result > 0;
    } catch (e) {
      print('Error updating attendance sync status: $e');
      return false;
    }
  }

// REMOVED FOR ATTENDANCE-ONLY:   /// Get unsynced payments
// REMOVED FOR ATTENDANCE-ONLY:   Future<List<Payment>> getUnsyncedPayments() async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.query(
// REMOVED FOR ATTENDANCE-ONLY:         _tablePayments,
// REMOVED FOR ATTENDANCE-ONLY:         where: 'synced = 0',
// REMOVED FOR ATTENDANCE-ONLY:         orderBy: 'date_paid DESC',
// REMOVED FOR ATTENDANCE-ONLY:       );
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       return result.map((map) => Payment.fromMap(map)).toList();
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error getting unsynced payments: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return [];
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Update payment sync status
// REMOVED FOR ATTENDANCE-ONLY:   Future<bool> updatePaymentSyncStatus(int id, bool synced) async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.update(
// REMOVED FOR ATTENDANCE-ONLY:         _tablePayments,
// REMOVED FOR ATTENDANCE-ONLY:         {
// REMOVED FOR ATTENDANCE-ONLY:           'synced': synced ? 1 : 0,
// REMOVED FOR ATTENDANCE-ONLY:           'updated_at': DateTime.now().toIso8601String(),
// REMOVED FOR ATTENDANCE-ONLY:         },
// REMOVED FOR ATTENDANCE-ONLY:         where: 'id = ?',
// REMOVED FOR ATTENDANCE-ONLY:         whereArgs: [id],
// REMOVED FOR ATTENDANCE-ONLY:       );
// REMOVED FOR ATTENDANCE-ONLY:       return result > 0;
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error updating payment sync status: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return false;
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Get unsynced discipline records
// REMOVED FOR ATTENDANCE-ONLY:   Future<List<DisciplineRecord>> getUnsyncedDiscipline() async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.query(
// REMOVED FOR ATTENDANCE-ONLY:         _tableDiscipline,
// REMOVED FOR ATTENDANCE-ONLY:         where: 'synced = 0',
// REMOVED FOR ATTENDANCE-ONLY:         orderBy: 'incident_date DESC',
// REMOVED FOR ATTENDANCE-ONLY:       );
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:       return result.map((map) => DisciplineRecord.fromMap(map)).toList();
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error getting unsynced discipline: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return [];
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }
// REMOVED FOR ATTENDANCE-ONLY: 
// REMOVED FOR ATTENDANCE-ONLY:   /// Update discipline sync status
// REMOVED FOR ATTENDANCE-ONLY:   Future<bool> updateDisciplineSyncStatus(int id, bool synced) async {
// REMOVED FOR ATTENDANCE-ONLY:     try {
// REMOVED FOR ATTENDANCE-ONLY:       final db = await database;
// REMOVED FOR ATTENDANCE-ONLY:       final result = await db.update(
// REMOVED FOR ATTENDANCE-ONLY:         _tableDiscipline,
// REMOVED FOR ATTENDANCE-ONLY:         {
// REMOVED FOR ATTENDANCE-ONLY:           'synced': synced ? 1 : 0,
// REMOVED FOR ATTENDANCE-ONLY:           'updated_at': DateTime.now().toIso8601String(),
// REMOVED FOR ATTENDANCE-ONLY:         },
// REMOVED FOR ATTENDANCE-ONLY:         where: 'id = ?',
// REMOVED FOR ATTENDANCE-ONLY:         whereArgs: [id],
// REMOVED FOR ATTENDANCE-ONLY:       );
// REMOVED FOR ATTENDANCE-ONLY:       return result > 0;
// REMOVED FOR ATTENDANCE-ONLY:     } catch (e) {
// REMOVED FOR ATTENDANCE-ONLY:       print('Error updating discipline sync status: $e');
// REMOVED FOR ATTENDANCE-ONLY:       return false;
// REMOVED FOR ATTENDANCE-ONLY:     }
// REMOVED FOR ATTENDANCE-ONLY:   }

  /// Update student sync status
  Future<bool> updateStudentSyncStatus(int studentId, bool synced) async {
    try {
      final db = await database;
      final result = await db.update(
        _tableStudents,
        {
          'synced': synced ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'student_id = ?',
        whereArgs: [studentId],
      );
      return result > 0;
    } catch (e) {
      print('Error updating student sync status: $e');
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
  factory AuthResult.failure(String message) =>
      AuthResult._(false, message, null);
}

/// Create user result class
class CreateUserResult {
  final bool success;
  final String? message;
  final User? user;

  CreateUserResult._(this.success, this.message, this.user);

  factory CreateUserResult.success(User user) =>
      CreateUserResult._(true, null, user);
  factory CreateUserResult.failure(String message) =>
      CreateUserResult._(false, message, null);
}

/// Database exception class
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
