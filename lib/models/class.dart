class SchoolClass {
  final int classId;
  final String name;
  final int levelId;
  final String section;
  final int studentCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Additional fields from joins
  final String? levelName;

  const SchoolClass({
    required this.classId,
    required this.name,
    required this.levelId,
    required this.section,
    this.studentCount = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.levelName,
  });

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      classId: map['class_id']?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      levelId: map['level_id']?.toInt() ?? 0,
      section: map['section']?.toString() ?? '',
      studentCount: map['student_count']?.toInt() ?? 0,
      isActive: (map['is_active']?.toInt() ?? 1) == 1,
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      levelName: map['level_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'name': name,
      'level_id': levelId,
      'section': section,
      'student_count': studentCount,
      'is_active': isActive ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  SchoolClass copyWith({
    int? classId,
    String? name,
    int? levelId,
    String? section,
    int? studentCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? levelName,
  }) {
    return SchoolClass(
      classId: classId ?? this.classId,
      name: name ?? this.name,
      levelId: levelId ?? this.levelId,
      section: section ?? this.section,
      studentCount: studentCount ?? this.studentCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      levelName: levelName ?? this.levelName,
    );
  }

  String get fullName => levelName != null ? '$levelName $name' : name;

  @override
  String toString() => 'SchoolClass(id: $classId, name: $name, section: $section, students: $studentCount)';
}
