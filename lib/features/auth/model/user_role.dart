enum UserRole {
  admin,
  staff;

  static UserRole fromString(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
      default:
        return UserRole.staff;
    }
  }

  String get value => name;
  String get displayName => name[0].toUpperCase() + name.substring(1);
}
