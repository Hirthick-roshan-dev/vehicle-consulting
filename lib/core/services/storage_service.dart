import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyCurrentUsername = 'current_username';
  static const String _keyCurrentRole = 'current_role';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  String? get currentUsername => _prefs.getString(_keyCurrentUsername);
  String? get currentRole => _prefs.getString(_keyCurrentRole);

  Future<void> saveSession({required String username, required String role}) async {
    await _prefs.setBool(_keyIsLoggedIn, true);
    await _prefs.setString(_keyCurrentUsername, username);
    await _prefs.setString(_keyCurrentRole, role);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyIsLoggedIn);
    await _prefs.remove(_keyCurrentUsername);
    await _prefs.remove(_keyCurrentRole);
  }
}
