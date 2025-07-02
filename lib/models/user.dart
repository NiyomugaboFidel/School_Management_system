// models/user.dart
import 'dart:convert';

/// Converts JSON string to User object
User userFromJson(String str) => User.fromMap(json.decode(str));

/// Converts User object to JSON string
String userToJson(User data) => json.encode(data.toMap());

/// User model class with enhanced features
class User {
  final int? id;
  final String? fullName;
  final String? email;
  final String username;
  final String password;
  final UserRole role;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    this.id,
    this.fullName,
    this.email,
    required this.username,
    required this.password,
    this.role = UserRole.user,
    this.isActive = true,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  /// Create User from Map (database result)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['usr_id']?.toInt(),
      fullName: map['full_name']?.toString(),
      email: map['email']?.toString(),
      username: map['usr_name']?.toString() ?? '',
      password: map['usr_password']?.toString() ?? '',
      role: UserRole.fromString(map['role']?.toString()),
      isActive: (map['is_active']?.toInt() ?? 1) == 1,
      lastLogin:
          map['last_login'] != null
              ? DateTime.tryParse(map['last_login'].toString())
              : null,
      createdAt:
          map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString())
              : null,
      updatedAt:
          map['updated_at'] != null
              ? DateTime.tryParse(map['updated_at'].toString())
              : null,
    );
  }

  /// Convert User to Map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'usr_id': id,
      'full_name': fullName,
      'email': email,
      'usr_name': username,
      'usr_password': password,
      'role': role.value,
      'is_active': isActive ? 1 : 0,
      if (lastLogin != null) 'last_login': lastLogin!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Create a copy of User with modified fields
  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? username,
    String? password,
    UserRole? role,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create User without sensitive data (for API responses)
  User toSafeUser() {
    return copyWith(password: '***');
  }

  /// Get user's display name
  String get displayName => fullName?.isNotEmpty == true ? fullName! : username;

  /// Check if user has admin privileges
  bool get isAdmin => role == UserRole.admin;

  /// Check if user has teacher privileges
  bool get isTeacher => role == UserRole.teacher || isAdmin;

  /// Get formatted last login
  String get formattedLastLogin {
    if (lastLogin == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastLogin!);

    if (difference.inDays > 7) {
      return '${lastLogin!.day}/${lastLogin!.month}/${lastLogin!.year}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Validate user data
  ValidationResult validate() {
    final errors = <String>[];

    // Username validation
    if (username.trim().isEmpty) {
      errors.add('Username is required');
    } else if (username.length < 3) {
      errors.add('Username must be at least 3 characters');
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      errors.add('Username can only contain letters, numbers, and underscores');
    }

    // Password validation
    if (password.isEmpty) {
      errors.add('Password is required');
    } else if (password.length < 6) {
      errors.add('Password must be at least 6 characters');
    }

    // Full name validation
    if (fullName == null || fullName!.trim().isEmpty) {
      errors.add('Full name is required');
    }

    // Email validation
    if (email != null && email!.isNotEmpty) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email!)) {
        errors.add('Invalid email format');
      }
    }

    return ValidationResult(errors.isEmpty, errors);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ email.hashCode;

  @override
  String toString() {
    return 'User(id: $id, username: $username, fullName: $fullName, email: $email, role: ${role.value}, isActive: $isActive)';
  }
}

/// User role enumeration
enum UserRole {
  admin(''),
  teacher('teacher'),
  user('user');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  @override
  String toString() => value;
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult(this.isValid, this.errors);

  String get errorMessage => errors.join('\n');
}
