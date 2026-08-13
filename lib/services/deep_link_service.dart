import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/news_detail_page.dart';
import '../screens/jobs/job_detail_page.dart';
import 'api_service.dart';

/// Handles deep links and universal links.
/// URLs like:
///   https://indiainformations.com/news/{slug}  → opens NewsDetailPage
///   https://indiainformations.com/jobs/{slug}  → opens JobDetailPage
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._();
  factory DeepLinkService() => _instance;
  DeepLinkService._();

  GlobalKey<NavigatorState>? navigatorKey;
  ApiService? api;

  void init({required GlobalKey<NavigatorState> navKey, required ApiService apiService}) {
    navigatorKey = navKey;
    api = apiService;
    _listenToLinks();
  }

  void _listenToLinks() {
    // Listen for incoming links when app is already running
    const channel = MethodChannel('com.indiainformations.app/deeplink');
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final url = call.arguments as String?;
        if (url != null) handleUrl(url);
      }
    });
  }

  /// Parse URL and navigate to appropriate screen
  void handleUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || api == null || navigatorKey?.currentState == null) return;

    final path = uri.path;
    final nav = navigatorKey!.currentState!;

    // News detail: /news/{slug}
    if (path.startsWith('/news/')) {
      final slug = path.replaceFirst('/news/', '');
      if (slug.isNotEmpty) {
        nav.push(MaterialPageRoute(builder: (_) => NewsDetailPage(api: api!, slug: slug)));
      }
    }
    // Job detail: /jobs/{slug}
    else if (path.startsWith('/jobs/')) {
      final slug = path.replaceFirst('/jobs/', '');
      if (slug.isNotEmpty) {
        nav.push(MaterialPageRoute(builder: (_) => JobDetailPage(api: api!, slug: slug)));
      }
    }
  }
}
