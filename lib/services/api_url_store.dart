import 'package:shared_preferences/shared_preferences.dart';

/// Optional override so a physical device can reach your PC without rebuilding.
class ApiUrlStore {
  ApiUrlStore._();

  static const _key = 'api_base_url_v1';

  static Future<String?> read() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key);
  }

  static Future<void> save(String url) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, url.trim());
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
