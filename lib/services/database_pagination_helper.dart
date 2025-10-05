import 'package:sqflite/sqflite.dart';
import '../SQLite/database_helper.dart';

/// Paginated query result
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  }) : hasMore = (currentPage * pageSize) < totalCount;

  int get totalPages => (totalCount / pageSize).ceil();
}

/// Database Pagination Helper
/// Provides efficient pagination for large data sets
class DatabasePaginationHelper {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get paginated students
  Future<PaginatedResult<Map<String, dynamic>>> getStudentsPaginated({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
    String? classId,
    String? levelId,
    String orderBy = 'name ASC',
  }) async {
    final db = await _dbHelper.database;

    // Build WHERE clause
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR student_id LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    if (classId != null) {
      whereConditions.add('class_id = ?');
      whereArgs.add(classId);
    }

    if (levelId != null) {
      whereConditions.add('level_id = ?');
      whereArgs.add(levelId);
    }

    final whereClause =
        whereConditions.isEmpty ? null : whereConditions.join(' AND ');

    // Get total count
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM students${whereClause != null ? ' WHERE $whereClause' : ''}',
      whereArgs,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    // Get paginated data
    final offset = (page - 1) * pageSize;
    final results = await db.query(
      'students',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );

    return PaginatedResult(
      items: results,
      totalCount: totalCount,
      currentPage: page,
      pageSize: pageSize,
    );
  }

  /// Get paginated attendance records
  Future<PaginatedResult<Map<String, dynamic>>> getAttendancePaginated({
    int page = 1,
    int pageSize = 50,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String orderBy = 'timestamp DESC',
  }) async {
    final db = await _dbHelper.database;

    // Build WHERE clause
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (studentId != null) {
      whereConditions.add('student_id = ?');
      whereArgs.add(studentId);
    }

    if (startDate != null) {
      whereConditions.add('timestamp >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereConditions.add('timestamp <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (status != null) {
      whereConditions.add('status = ?');
      whereArgs.add(status);
    }

    final whereClause =
        whereConditions.isEmpty ? null : whereConditions.join(' AND ');

    // Get total count
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM attendance_logs${whereClause != null ? ' WHERE $whereClause' : ''}',
      whereArgs,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    // Get paginated data
    final offset = (page - 1) * pageSize;
    final results = await db.query(
      'attendance_logs',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );

    return PaginatedResult(
      items: results,
      totalCount: totalCount,
      currentPage: page,
      pageSize: pageSize,
    );
  }

  /// Get paginated payments
  Future<PaginatedResult<Map<String, dynamic>>> getPaymentsPaginated({
    int page = 1,
    int pageSize = 20,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String orderBy = 'timestamp DESC',
  }) async {
    final db = await _dbHelper.database;

    // Build WHERE clause
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (studentId != null) {
      whereConditions.add('student_id = ?');
      whereArgs.add(studentId);
    }

    if (startDate != null) {
      whereConditions.add('timestamp >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereConditions.add('timestamp <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (status != null) {
      whereConditions.add('status = ?');
      whereArgs.add(status);
    }

    final whereClause =
        whereConditions.isEmpty ? null : whereConditions.join(' AND ');

    // Get total count
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payments${whereClause != null ? ' WHERE $whereClause' : ''}',
      whereArgs,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    // Get paginated data
    final offset = (page - 1) * pageSize;
    final results = await db.query(
      'payments',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );

    return PaginatedResult(
      items: results,
      totalCount: totalCount,
      currentPage: page,
      pageSize: pageSize,
    );
  }

  /// Get paginated discipline records
  Future<PaginatedResult<Map<String, dynamic>>> getDisciplinePaginated({
    int page = 1,
    int pageSize = 20,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    String? severity,
    String orderBy = 'timestamp DESC',
  }) async {
    final db = await _dbHelper.database;

    // Build WHERE clause
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (studentId != null) {
      whereConditions.add('student_id = ?');
      whereArgs.add(studentId);
    }

    if (startDate != null) {
      whereConditions.add('timestamp >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereConditions.add('timestamp <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (severity != null) {
      whereConditions.add('severity = ?');
      whereArgs.add(severity);
    }

    final whereClause =
        whereConditions.isEmpty ? null : whereConditions.join(' AND ');

    // Get total count
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM discipline${whereClause != null ? ' WHERE $whereClause' : ''}',
      whereArgs,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    // Get paginated data
    final offset = (page - 1) * pageSize;
    final results = await db.query(
      'discipline',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );

    return PaginatedResult(
      items: results,
      totalCount: totalCount,
      currentPage: page,
      pageSize: pageSize,
    );
  }

  /// Generic paginated query
  Future<PaginatedResult<Map<String, dynamic>>> getPaginated({
    required String table,
    int page = 1,
    int pageSize = 20,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final db = await _dbHelper.database;

    // Get total count
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    // Get paginated data
    final offset = (page - 1) * pageSize;
    final results = await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );

    return PaginatedResult(
      items: results,
      totalCount: totalCount,
      currentPage: page,
      pageSize: pageSize,
    );
  }
}
