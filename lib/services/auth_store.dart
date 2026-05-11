import 'package:shared_preferences/shared_preferences.dart';

class AuthStore {
  AuthStore._();

  static const _key = 'auth_token';

  static Future<String?> readToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key);
  }

  static Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, token);
  }

  static Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
