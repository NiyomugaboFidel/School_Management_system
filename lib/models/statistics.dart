import 'dart:convert';

/// Statistics model class
class Statistics {
  final int id;
  final int studentId;
  final String academicYear;
  final int totalSchoolDays;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int disciplineCases;
  final int totalDisciplineMarksDeducted;
  final double attendancePercentage;
  final String? behaviorRating;
  final DateTime lastCalculated;

  const Statistics({
    required this.id,
    required this.studentId,
    required this.academicYear,
    required this.totalSchoolDays,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.disciplineCases,
    required this.totalDisciplineMarksDeducted,
    required this.attendancePercentage,
    this.behaviorRating,
    required this.lastCalculated,
  });

  factory Statistics.fromMap(Map<String, dynamic> map) {
    return Statistics(
      id: map['id']?.toInt() ?? 0,
      studentId: map['student_id']?.toInt() ?? 0,
      academicYear: map['academic_year']?.toString() ?? '',
      totalSchoolDays: map['total_school_days']?.toInt() ?? 0,
      presentCount: map['present_count']?.toInt() ?? 0,
      absentCount: map['absent_count']?.toInt() ?? 0,
      lateCount: map['late_count']?.toInt() ?? 0,
      excusedCount: map['excused_count']?.toInt() ?? 0,
      disciplineCases: map['discipline_cases']?.toInt() ?? 0,
      totalDisciplineMarksDeducted: map['total_discipline_marks_deducted']?.toInt() ?? 0,
      attendancePercentage: (map['attendance_percentage'] is double)
        ? map['attendance_percentage']
        : (map['attendance_percentage'] is int)
          ? (map['attendance_percentage'] as int).toDouble()
          : double.tryParse(map['attendance_percentage']?.toString() ?? '0.0') ?? 0.0,
      behaviorRating: map['behavior_rating']?.toString(),
      lastCalculated: DateTime.tryParse(map['last_calculated']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'academic_year': academicYear,
      'total_school_days': totalSchoolDays,
      'present_count': presentCount,
      'absent_count': absentCount,
      'late_count': lateCount,
      'excused_count': excusedCount,
      'discipline_cases': disciplineCases,
      'total_discipline_marks_deducted': totalDisciplineMarksDeducted,
      'attendance_percentage': attendancePercentage,
      'behavior_rating': behaviorRating,
      'last_calculated': lastCalculated.toIso8601String(),
    };
  }

  Statistics copyWith({
    int? id,
    int? studentId,
    String? academicYear,
    int? totalSchoolDays,
    int? presentCount,
    int? absentCount,
    int? lateCount,
    int? excusedCount,
    int? disciplineCases,
    int? totalDisciplineMarksDeducted,
    double? attendancePercentage,
    String? behaviorRating,
    DateTime? lastCalculated,
  }) {
    return Statistics(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      academicYear: academicYear ?? this.academicYear,
      totalSchoolDays: totalSchoolDays ?? this.totalSchoolDays,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      lateCount: lateCount ?? this.lateCount,
      excusedCount: excusedCount ?? this.excusedCount,
      disciplineCases: disciplineCases ?? this.disciplineCases,
      totalDisciplineMarksDeducted: totalDisciplineMarksDeducted ?? this.totalDisciplineMarksDeducted,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      behaviorRating: behaviorRating ?? this.behaviorRating,
      lastCalculated: lastCalculated ?? this.lastCalculated,
    );
  }

  @override
  String toString() => 'Statistics(id: $id, studentId: $studentId, year: $academicYear, attendance: $attendancePercentage, behavior: $behaviorRating)';
}
