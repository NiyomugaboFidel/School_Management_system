/// Level model class
class Level {
  final int levelId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Level({
    required this.levelId,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Level.fromMap(Map<String, dynamic> map) {
    return Level(
      levelId: map['level_id']?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level_id': levelId,
      'name': name,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Level copyWith({
    int? levelId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Level(
      levelId: levelId ?? this.levelId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Level(id: $levelId, name: $name)';
}
