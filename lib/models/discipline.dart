/// Discipline record model class
class DisciplineRecord {
  final int id;
  final int studentId;
  final String type;
  final String description;
  final String actionTaken;
  final String recordedBy;
  final DateTime date;
  final bool resolved;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DisciplineRecord({
    required this.id,
    required this.studentId,
    required this.type,
    required this.description,
    required this.actionTaken,
    required this.recordedBy,
    required this.date,
    this.resolved = false,
    this.createdAt,
    this.updatedAt,
  });

  factory DisciplineRecord.fromMap(Map<String, dynamic> map) {
    return DisciplineRecord(
      id: map['id']?.toInt() ?? 0,
      studentId: map['student_id']?.toInt() ?? 0,
      type: map['type']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      actionTaken: map['action_taken']?.toString() ?? '',
      recordedBy: map['recorded_by']?.toString() ?? '',
      date: DateTime.parse(map['date'].toString()),
      resolved: (map['resolved']?.toInt() ?? 0) == 1,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'type': type,
      'description': description,
      'action_taken': actionTaken,
      'recorded_by': recordedBy,
      'date': date.toIso8601String(),
      'resolved': resolved ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  DisciplineRecord copyWith({
    int? id,
    int? studentId,
    String? type,
    String? description,
    String? actionTaken,
    String? recordedBy,
    DateTime? date,
    bool? resolved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DisciplineRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      type: type ?? this.type,
      description: description ?? this.description,
      actionTaken: actionTaken ?? this.actionTaken,
      recordedBy: recordedBy ?? this.recordedBy,
      date: date ?? this.date,
      resolved: resolved ?? this.resolved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'DisciplineRecord(id: $id, student: $studentId, type: $type, resolved: $resolved)';
}
