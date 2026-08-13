import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

/// Checks for app updates by comparing local version with server version.
/// Backend should expose a `/api/app-version` endpoint returning:
/// { "latest_version": "1.0.1", "min_version": "1.0.0", "update_url_ios": "...", "update_url_android": "..." }
class AppUpdateService {
  static const String _currentVersion = '1.0.0'; // Update this with each release

  /// Check for updates and show dialog if needed
  static Future<void> checkForUpdate(BuildContext context, ApiService api) async {
    try {
      final result = await api.getJson('/app-version');
      if (result == null) return;

      final data = result as Map<String, dynamic>;
      final latestVersion = data['latest_version'] as String? ?? _currentVersion;
      final minVersion = data['min_version'] as String? ?? '0.0.0';
      final updateUrl = data['update_url_ios'] as String? ?? '';

      final isForceUpdate = _compareVersions(_currentVersion, minVersion) < 0;
      final isOptionalUpdate = _compareVersions(_currentVersion, latestVersion) < 0;

      if (!context.mounted) return;

      if (isForceUpdate) {
        _showForceUpdateDialog(context, updateUrl);
      } else if (isOptionalUpdate) {
        _showOptionalUpdateDialog(context, updateUrl);
      }
    } catch (_) {
      // Silently fail — don't block app usage
    }
  }

  static void _showForceUpdateDialog(BuildContext context, String updateUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.system_update_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Update Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Text(
            'A new version of India Informations is available. Please update to continue using the app.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => _openStore(updateUrl),
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showOptionalUpdateDialog(BuildContext context, String updateUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.upgrade_rounded, color: Colors.blue),
            SizedBox(width: 10),
            Text('Update Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'A newer version is available with new features and improvements. Would you like to update?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openStore(updateUrl);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  static Future<void> _openStore(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Compare two version strings (e.g., "1.0.0" vs "1.0.1")
  /// Returns negative if v1 < v2, 0 if equal, positive if v1 > v2
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1 - p2;
    }
    return 0;
  }
}
