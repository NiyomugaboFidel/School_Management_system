import 'package:sqlite_crud_app/SQLite/database_helper.dart';

import '../models/discipline.dart';

/// Service class for managing student discipline records
/// Provides simple actions for discipline management
class DisciplineService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Record a new discipline case - Simple action
  Future<bool> recordDisciplineCase({
    required int studentId,
    required String reason,
    required String severity, // 'Minor', 'Major', 'Severe'
    required String recordedBy,
    int marksDeducted = 0,
    String? actionTaken,
    String? incidentDate,
  }) async {
    try {
      // Validate severity
      if (!['Minor', 'Major', 'Severe'].contains(severity)) {
        throw ArgumentError(
          'Invalid severity level. Must be Minor, Major, or Severe',
        );
      }

      // Use today's date if incident date not provided
      final incident =
          incidentDate ?? DateTime.now().toIso8601String().split('T')[0];

      return await _databaseHelper.recordDiscipline(
        studentId: studentId,
        incidentDate: incident,
        marksDeducted: marksDeducted,
        reason: reason,
        severity: severity,
        recordedBy: recordedBy,
        actionTaken: actionTaken,
      );
    } catch (e) {
      print('Error in DisciplineService.recordDisciplineCase: $e');
      return false;
    }
  }

  /// Get all discipline records for a student - Simple action
  Future<List<DisciplineRecord>> getStudentDisciplineRecords(
    int studentId,
  ) async {
    try {
      return await _databaseHelper.getStudentDisciplineRecords(studentId);
    } catch (e) {
      print('Error in DisciplineService.getStudentDisciplineRecords: $e');
      return [];
    }
  }

  /// Get recent discipline cases across all students - Simple action
  Future<List<DisciplineRecord>> getRecentDisciplineCases({
    int limit = 50,
  }) async {
    try {
      return await _databaseHelper.getRecentDisciplineCases(limit: limit);
    } catch (e) {
      print('Error in DisciplineService.getRecentDisciplineCases: $e');
      return [];
    }
  }

  /// Get total discipline marks deducted for a student - Simple action
  Future<int> getStudentTotalDisciplineMarks(int studentId) async {
    try {
      return await _databaseHelper.getStudentTotalDisciplineMarks(studentId);
    } catch (e) {
      print('Error in DisciplineService.getStudentTotalDisciplineMarks: $e');
      return 0;
    }
  }

  /// Check if student has recent discipline issues - Simple action
  Future<bool> hasRecentDisciplineIssues(int studentId, {int days = 30}) async {
    try {
      final db = await _databaseHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final result = await db.query(
        'discipline',
        where: 'student_id = ? AND incident_date >= ?',
        whereArgs: [studentId, cutoffDate.toIso8601String().split('T')[0]],
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error in DisciplineService.hasRecentDisciplineIssues: $e');
      return false;
    }
  }

  /// Get discipline count by severity for a student - Simple action
  Future<Map<String, int>> getStudentDisciplineCountBySeverity(
    int studentId,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT severity, COUNT(*) as count
        FROM discipline
        WHERE student_id = ?
        GROUP BY severity
      ''',
        [studentId],
      );

      final counts = <String, int>{'Minor': 0, 'Major': 0, 'Severe': 0};

      for (final row in result) {
        final severity = row['severity'] as String;
        final count = (row['count'] as num).toInt();
        counts[severity] = count;
      }

      return counts;
    } catch (e) {
      print(
        'Error in DisciplineService.getStudentDisciplineCountBySeverity: $e',
      );
      return {'Minor': 0, 'Major': 0, 'Severe': 0};
    }
  }

  /// Get discipline cases by date range - Simple action
  Future<List<DisciplineRecord>> getDisciplineCasesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int? studentId,
  }) async {
    try {
      final db = await _databaseHelper.database;
      String query = '''
        SELECT d.*, s.full_name, s.reg_number, c.name as class_name
        FROM discipline d
        JOIN students s ON d.student_id = s.student_id
        JOIN classes c ON s.class_id = c.class_id
        WHERE d.incident_date BETWEEN ? AND ?
      ''';

      List<dynamic> whereArgs = [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ];

      if (studentId != null) {
        query += ' AND d.student_id = ?';
        whereArgs.add(studentId);
      }

      query += ' ORDER BY d.incident_date DESC';

      final result = await db.rawQuery(query, whereArgs);
      return result.map((map) => DisciplineRecord.fromMap(map)).toList();
    } catch (e) {
      print('Error in DisciplineService.getDisciplineCasesByDateRange: $e');
      return [];
    }
  }

  /// Update discipline case resolution status - Simple action
  Future<bool> updateDisciplineCaseResolution(
    int disciplineId,
    bool resolved, {
    String? actionTaken,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final updateData = <String, dynamic>{
        'resolved': resolved ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (actionTaken != null) {
        updateData['action_taken'] = actionTaken;
      }

      final result = await db.update(
        'discipline',
        updateData,
        where: 'id = ?',
        whereArgs: [disciplineId],
      );

      return result > 0;
    } catch (e) {
      print('Error in DisciplineService.updateDisciplineCaseResolution: $e');
      return false;
    }
  }

  /// Get student's discipline summary - Simple action
  Future<DisciplineSummary> getStudentDisciplineSummary(int studentId) async {
    try {
      final records = await getStudentDisciplineRecords(studentId);
      final totalMarks = await getStudentTotalDisciplineMarks(studentId);
      final severityCounts = await getStudentDisciplineCountBySeverity(
        studentId,
      );
      final hasRecent = await hasRecentDisciplineIssues(studentId);

      return DisciplineSummary(
        totalCases: records.length,
        totalMarksDeducted: totalMarks,
        minorCases: severityCounts['Minor'] ?? 0,
        majorCases: severityCounts['Major'] ?? 0,
        severeCases: severityCounts['Severe'] ?? 0,
        hasRecentIssues: hasRecent,
        lastIncidentDate: records.isNotEmpty ? records.first.date : null,
      );
    } catch (e) {
      print('Error in DisciplineService.getStudentDisciplineSummary: $e');
      return DisciplineSummary.empty();
    }
  }

  /// Quick discipline actions based on common scenarios

  /// Record minor discipline case - Quick action
  Future<bool> recordMinorCase(
    int studentId,
    String reason,
    String recordedBy,
  ) async {
    return await recordDisciplineCase(
      studentId: studentId,
      reason: reason,
      severity: 'Minor',
      recordedBy: recordedBy,
      marksDeducted: 1,
    );
  }

  /// Record major discipline case - Quick action
  Future<bool> recordMajorCase(
    int studentId,
    String reason,
    String recordedBy, {
    String? actionTaken,
  }) async {
    return await recordDisciplineCase(
      studentId: studentId,
      reason: reason,
      severity: 'Major',
      recordedBy: recordedBy,
      marksDeducted: 5,
      actionTaken: actionTaken,
    );
  }

  /// Record severe discipline case - Quick action
  Future<bool> recordSevereCase(
    int studentId,
    String reason,
    String recordedBy,
    String actionTaken,
  ) async {
    return await recordDisciplineCase(
      studentId: studentId,
      reason: reason,
      severity: 'Severe',
      recordedBy: recordedBy,
      marksDeducted: 10,
      actionTaken: actionTaken,
    );
  }

  /// Check if student needs attention based on discipline pattern - Simple check
  Future<bool> needsAttention(int studentId) async {
    try {
      final summary = await getStudentDisciplineSummary(studentId);

      // Student needs attention if:
      // - Has severe cases
      // - Has more than 3 major cases
      // - Has more than 5 minor cases
      // - Has recent issues and total marks > 20
      return summary.severeCases > 0 ||
          summary.majorCases > 3 ||
          summary.minorCases > 5 ||
          (summary.hasRecentIssues && summary.totalMarksDeducted > 20);
    } catch (e) {
      print('Error in DisciplineService.needsAttention: $e');
      return false;
    }
  }

  /// Get behavior rating for student - Simple rating
  Future<String> getBehaviorRating(int studentId) async {
    try {
      final summary = await getStudentDisciplineSummary(studentId);

      if (summary.totalCases == 0) {
        return 'Excellent';
      } else if (summary.severeCases == 0 &&
          summary.majorCases <= 1 &&
          summary.minorCases <= 2) {
        return 'Good';
      } else if (summary.severeCases == 0 &&
          summary.majorCases <= 3 &&
          summary.minorCases <= 5) {
        return 'Fair';
      } else {
        return 'Poor';
      }
    } catch (e) {
      print('Error in DisciplineService.getBehaviorRating: $e');
      return 'Unknown';
    }
  }
}

/// Discipline summary model for simple overview
class DisciplineSummary {
  final int totalCases;
  final int totalMarksDeducted;
  final int minorCases;
  final int majorCases;
  final int severeCases;
  final bool hasRecentIssues;
  final DateTime? lastIncidentDate;

  const DisciplineSummary({
    required this.totalCases,
    required this.totalMarksDeducted,
    required this.minorCases,
    required this.majorCases,
    required this.severeCases,
    required this.hasRecentIssues,
    this.lastIncidentDate,
  });

  factory DisciplineSummary.empty() {
    return const DisciplineSummary(
      totalCases: 0,
      totalMarksDeducted: 0,
      minorCases: 0,
      majorCases: 0,
      severeCases: 0,
      hasRecentIssues: false,
      lastIncidentDate: null,
    );
  }

  @override
  String toString() {
    return 'DisciplineSummary(total: $totalCases, marks: $totalMarksDeducted, recent: $hasRecentIssues)';
  }
}
