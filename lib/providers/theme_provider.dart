import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages theme mode (light/dark/system).
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  ThemeProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'dark') {
      _mode = ThemeMode.dark;
    } else if (saved == 'light') {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.dark:
        await prefs.setString(_key, 'dark');
      case ThemeMode.light:
        await prefs.setString(_key, 'light');
      case ThemeMode.system:
        await prefs.setString(_key, 'system');
    }
  }
}
