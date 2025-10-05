import '../SQLite/database_helper.dart';
import '../models/attendance.dart';
import '../models/attendance_result.dart';
import 'enhanced_sync_service.dart';

class AttendanceService {
  static AttendanceService? _instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Private constructor for singleton
  AttendanceService._();

  // Singleton instance
  static AttendanceService get instance {
    _instance ??= AttendanceService._();
    return _instance!;
  }

  /// Mark attendance with real-time sync
  Future<AttendanceResult> markAttendance(
    int studentId,
    String status,
    String markedBy, {
    String? notes,
    DateTime? checkInTime,
  }) async {
    try {
      // First mark attendance locally
      final result = await _dbHelper.markAttendance(
        studentId,
        status,
        markedBy,
        notes: notes,
        checkInTime: checkInTime,
      );

      // If successful, try real-time sync
      if (result.isSuccess) {
        try {
          // Get the attendance record for sync
          final today = DateTime.now().toIso8601String().split('T')[0];
          final db = await _dbHelper.database;
          final attendanceRecord = await db.query(
            'attendance_logs',
            where: 'student_id = ? AND date = ?',
            whereArgs: [studentId, today],
          );

          if (attendanceRecord.isNotEmpty) {
            final attendance = AttendanceLog.fromMap(attendanceRecord.first);

            // Queue for sync with enhanced sync service
            await EnhancedSyncService.instance.addToSyncQueue(
              tableName: 'attendance_logs',
              operation: 'insert',
              data: attendance.toMap(),
              userId: markedBy,
              recordId: attendance.id.toString(),
            );
            print('✅ Attendance queued for sync: ${attendance.id}');
          }
        } catch (e) {
          print('❌ Real-time sync failed: $e');
          // Don't fail the attendance marking if sync fails
          // The attendance is still saved locally and will be synced later
        }
      }

      return result;
    } catch (e) {
      print('Error in attendance service: $e');
      return AttendanceResult.failure('Error marking attendance: $e');
    }
  }

  /// Get today's attendance records
  Future<List<AttendanceLog>> getTodayAttendance() async {
    return await _dbHelper.getTodayAttendance();
  }

  /// Get attendance records for a specific date
  Future<List<AttendanceLog>> getAttendanceForDate(DateTime date) async {
    return await _dbHelper.getAttendanceForDate(date);
  }

  /// Get attendance statistics for today
  Future<Map<String, int>> getTodayAttendanceStats() async {
    try {
      final todayAttendance = await getTodayAttendance();

      int present = 0, absent = 0, late = 0, excused = 0;

      for (final attendance in todayAttendance) {
        switch (attendance.status) {
          case AttendanceStatus.present:
            present++;
            break;
          case AttendanceStatus.absent:
            absent++;
            break;
          case AttendanceStatus.late:
            late++;
            break;
          case AttendanceStatus.excused:
            excused++;
            break;
        }
      }

      return {
        'present': present,
        'absent': absent,
        'late': late,
        'excused': excused,
        'total': todayAttendance.length,
      };
    } catch (e) {
      print('Error getting attendance stats: $e');
      return {'present': 0, 'absent': 0, 'late': 0, 'excused': 0, 'total': 0};
    }
  }

  /// Get unsynced attendance records
  Future<List<AttendanceLog>> getUnsyncedAttendance() async {
    return await _dbHelper.getUnsyncedAttendance();
  }

  /// Update attendance sync status
  Future<bool> updateAttendanceSyncStatus(int id, bool synced) async {
    return await _dbHelper.updateAttendanceSyncStatus(id, synced);
  }
}
