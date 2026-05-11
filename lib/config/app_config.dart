/// Backend API base (must include `/api`).
/// Default = this PC LAN IP (check `ipconfig` if Wi‑Fi IP changes).
/// Build: `--dart-define=API_BASE_URL=...` · Runtime: Account → Server URL.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'http://192.168.1.12:8000/api',
  );

  /// Site origin for assets/images derived by stripping `/api` from API base.
  static String get webOrigin => webOriginFromApiBase(apiBaseUrl);

  /// Use when API base comes from saved prefs / runtime override.
  static String webOriginFromApiBase(String apiBaseUrl) {
    var u = apiBaseUrl.trim();
    if (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.endsWith('/api')) {
      u = u.substring(0, u.length - 4);
    }
    return u;
  }
}
