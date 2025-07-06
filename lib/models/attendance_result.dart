/// Result of attendance marking operation
class AttendanceResult {
  final bool isSuccess;
  final bool isDuplicate;
  final bool isUpdated;
  final String? status;
  final DateTime? time;
  final String? error;
  final String? previousStatus;
  final String? existingStatus;
  final DateTime? existingTime;
  final String? newStatus;
  final DateTime? newTime;

  const AttendanceResult._({
    required this.isSuccess,
    required this.isDuplicate,
    required this.isUpdated,
    this.status,
    this.time,
    this.error,
    this.previousStatus,
    this.existingStatus,
    this.existingTime,
    this.newStatus,
    this.newTime,
  });

  /// Successfully marked new attendance
  factory AttendanceResult.success({
    required String status,
    required DateTime time,
  }) {
    return AttendanceResult._(
      isSuccess: true,
      isDuplicate: false,
      isUpdated: false,
      status: status,
      time: time,
    );
  }

  /// Updated existing attendance
  factory AttendanceResult.updated({
    required String previousStatus,
    required String newStatus,
    required DateTime time,
  }) {
    return AttendanceResult._(
      isSuccess: true,
      isDuplicate: false,
      isUpdated: true,
      status: newStatus,
      time: time,
      previousStatus: previousStatus,
    );
  }

  /// Duplicate attendance detected (existing record is newer)
  factory AttendanceResult.duplicate({
    required String existingStatus,
    required DateTime existingTime,
    required String newStatus,
    required DateTime newTime,
  }) {
    return AttendanceResult._(
      isSuccess: false,
      isDuplicate: true,
      isUpdated: false,
      existingStatus: existingStatus,
      existingTime: existingTime,
      newStatus: newStatus,
      newTime: newTime,
    );
  }

  /// Failed to mark attendance
  factory AttendanceResult.failure(String error) {
    return AttendanceResult._(
      isSuccess: false,
      isDuplicate: false,
      isUpdated: false,
      error: error,
    );
  }

  /// Get message for user
  String get message {
    if (isSuccess) {
      if (isUpdated) {
        return 'Attendance updated: $status at ${_formatTime(time!)}';
      } else {
        return 'Attendance marked: $status at ${_formatTime(time!)}';
      }
    } else if (isDuplicate) {
      return 'Duplicate attendance detected. Existing record ($existingStatus at ${_formatTime(existingTime!)}) is newer than new record ($newStatus at ${_formatTime(newTime!)})';
    } else {
      return error ?? 'Failed to mark attendance';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'AttendanceResult(isSuccess: $isSuccess, isDuplicate: $isDuplicate, isUpdated: $isUpdated, status: $status, error: $error)';
  }
}
