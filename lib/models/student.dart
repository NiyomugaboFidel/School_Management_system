import 'dart:convert';

/// Converts JSON string to Student object
Student studentFromJson(String str) => Student.fromMap(json.decode(str));

/// Converts Student object to JSON string
String studentToJson(Student data) => json.encode(data.toMap());

/// Student model class
class Student {
  final int studentId;
  final String regNumber;
  final String fullName;
  final int classId;
  final String? barcode;
  final String? nfcTagId;
  final String? profileImage;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Additional fields from joins
  final String? className;
  final String? levelName;

  const Student({
    required this.studentId,
    required this.regNumber,
    required this.fullName,
    required this.classId,
    this.barcode,
    this.nfcTagId,
    this.profileImage,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.className,
    this.levelName,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      studentId: map['student_id']?.toInt() ?? 0,
      regNumber: map['reg_number']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      classId: map['class_id']?.toInt() ?? 0,
      barcode: map['barcode']?.toString(),
      nfcTagId: map['nfc_tag_id']?.toString(),
      profileImage: map['profile_image']?.toString(),
      isActive: (map['is_active']?.toInt() ?? 1) == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      className: map['class_name']?.toString(),
      levelName: map['level_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'reg_number': regNumber,
      'full_name': fullName,
      'class_id': classId,
      'barcode': barcode,
      'nfc_tag_id': nfcTagId,
      'profile_image': profileImage,
      'is_active': isActive ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Student copyWith({
    int? studentId,
    String? regNumber,
    String? fullName,
    int? classId,
    String? barcode,
    String? nfcTagId,
    String? profileImage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? className,
    String? levelName,
  }) {
    return Student(
      studentId: studentId ?? this.studentId,
      regNumber: regNumber ?? this.regNumber,
      fullName: fullName ?? this.fullName,
      classId: classId ?? this.classId,
      barcode: barcode ?? this.barcode,
      nfcTagId: nfcTagId ?? this.nfcTagId,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      className: className ?? this.className,
      levelName: levelName ?? this.levelName,
    );
  }

  String get displayName => '$fullName ($regNumber)';
  String get fullClassInfo => className != null ? '$levelName $className' : 'Class $classId';

  @override
  String toString() => 'Student(id: $studentId, name: $fullName, reg: $regNumber, class: $className)';
}
