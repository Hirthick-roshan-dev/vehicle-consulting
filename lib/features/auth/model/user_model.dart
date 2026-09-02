import 'user_role.dart';

class UserModel {
  final int id;
  final String username;
  final UserRole role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      username: map['username'] as String,
      role: UserRole.fromString(map['role'] as String),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'role': role.value,
      'is_active': isActive ? 1 : 0,
    };
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isStaff => role == UserRole.staff;
}
