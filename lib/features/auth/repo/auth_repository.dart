import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/utils/password_hasher.dart';
import '../model/user_model.dart';
import '../model/user_role.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final AppDatabase _appDatabase;

  AuthRepository(this._appDatabase);

  Future<UserModel> login({
    required String username,
    required String password,
    required UserRole selectedRole,
  }) async {
    try {
      final db = await _appDatabase.database;
      final passHash = PasswordHasher.hash(password);

      final results = await db.query(
        DatabaseConstants.tableUsers,
        where: 'LOWER(username) = LOWER(?) AND role = ? AND is_active = 1',
        whereArgs: [username.trim(), selectedRole.value],
      );

      if (results.isEmpty) {
        throw AuthException('User "$username" with role "${selectedRole.displayName}" not found.');
      }

      final userData = results.first;
      final storedHash = userData['password_hash'] as String;

      if (storedHash != passHash) {
        throw AuthException('Incorrect password provided.');
      }

      return UserModel.fromMap(userData);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Database authentication error: ${e.toString()}');
    }
  }

  Future<bool> verifyPasskey({
    required String username,
    required String passkey,
  }) async {
    try {
      final db = await _appDatabase.database;
      final passkeyHash = PasswordHasher.hash(passkey);

      final results = await db.query(
        DatabaseConstants.tableUsers,
        where: 'LOWER(username) = LOWER(?) AND is_active = 1',
        whereArgs: [username.trim()],
      );

      if (results.isEmpty) return false;

      final storedHash = results.first['passkey_hash'] as String;
      return storedHash == passkeyHash;
    } catch (e) {
      throw AuthException('Error verifying passkey.');
    }
  }

  Future<void> changePassword({
    required String username,
    required String newPassword,
  }) async {
    try {
      final db = await _appDatabase.database;
      final newHash = PasswordHasher.hash(newPassword);
      final now = DateTime.now().toIso8601String();

      final count = await db.update(
        DatabaseConstants.tableUsers,
        {
          'password_hash': newHash,
          'updated_at': now,
        },
        where: 'LOWER(username) = LOWER(?)',
        whereArgs: [username.trim()],
      );

      if (count == 0) {
        throw AuthException('User not found to update password.');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to change password: ${e.toString()}');
    }
  }

  Future<void> changePasskey({
    required String username,
    required String newPasskey,
  }) async {
    try {
      final db = await _appDatabase.database;
      final newHash = PasswordHasher.hash(newPasskey);
      final now = DateTime.now().toIso8601String();

      final count = await db.update(
        DatabaseConstants.tableUsers,
        {
          'passkey_hash': newHash,
          'updated_at': now,
        },
        where: 'LOWER(username) = LOWER(?)',
        whereArgs: [username.trim()],
      );

      if (count == 0) {
        throw AuthException('User not found to update passkey.');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to change passkey: ${e.toString()}');
    }
  }

  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseConstants.tableUsers,
        where: 'LOWER(username) = LOWER(?) AND is_active = 1',
        whereArgs: [username.trim()],
      );
      if (results.isEmpty) return null;
      return UserModel.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }
}
