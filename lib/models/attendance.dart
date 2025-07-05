/// Attendance status enumeration
enum AttendanceStatus {
  present('Present'),
  absent('Absent'),
  late('Late'),
  excused('Excused');

  const AttendanceStatus(this.value);
  final String value;

  static AttendanceStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.absent;
    }
  }

  @override
  String toString() => value;
}

/// Attendance log model
class AttendanceLog {
  final int id;
  final int studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String markedBy;
  final DateTime markedAt;
  final String? profileImage;
  final String? notes;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? fullName;
  final String? regNumber;
  final String? className;

  const AttendanceLog({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.markedAt,
    this.profileImage,
    this.notes,
    this.synced = false,
    this.createdAt,
    this.updatedAt,
    this.fullName,
    this.regNumber,
    this.className,
  });

  factory AttendanceLog.fromMap(Map<String, dynamic> map) {
    return AttendanceLog(
      id: map['id']?.toInt() ?? 0,
      studentId: map['student_id']?.toInt() ?? 0,
      date: DateTime.parse(map['date'].toString()),
      status: AttendanceStatus.fromString(map['status']?.toString()),
      markedBy: map['marked_by']?.toString() ?? '',
      markedAt: DateTime.parse(map['marked_at'].toString()),
      profileImage: map['profile_image']?.toString(),
      notes: map['notes']?.toString(),
      synced: (map['synced']?.toInt() ?? 0) == 1,
      createdAt:
          map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString())
              : null,
      updatedAt:
          map['updated_at'] != null
              ? DateTime.tryParse(map['updated_at'].toString())
              : null,
      fullName: map['full_name']?.toString(),
      regNumber: map['reg_number']?.toString(),
      className: map['class_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'date': date.toIso8601String(),
      'status': status.value,
      'marked_by': markedBy,
      'marked_at': markedAt.toIso8601String(),
      'profile_image': profileImage,
      'notes': notes,
      'synced': synced ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  AttendanceLog copyWith({
    int? id,
    int? studentId,
    DateTime? date,
    AttendanceStatus? status,
    String? markedBy,
    DateTime? markedAt,
    String? profileImage,
    String? notes,
    bool? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceLog(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      markedAt: markedAt ?? this.markedAt,
      profileImage: profileImage ?? this.profileImage,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'AttendanceLog(id: $id, student: $studentId, date: $date, status: $status)';
}
