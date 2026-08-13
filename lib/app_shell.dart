import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/account_page.dart';
import 'screens/feed_page.dart';
import 'screens/tools_page.dart';
import 'screens/local_explorer/local_explorer_screen.dart';
import 'screens/jobs/job_hub_page.dart';
import 'services/api_service.dart';
import 'services/auth_store.dart';
import 'services/api_url_store.dart';
import 'services/app_review_service.dart';
import 'services/app_update_service.dart';
import 'services/rewarded_ad_service.dart';
import 'theme/app_theme.dart';
import 'screens/business_directory_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  String? _token;
  ApiService? _api;
  String? _bootError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    AppReviewService.trackSession();
    RewardedAdManager.preload(); // Pre-load rewarded ad
    AuthStore.readToken().then((t) {
      if (mounted) {
        setState(() => _token = t);
        // Don't force login on startup - let user browse freely
        // Login will be required only when they try to use protected features
      }
    });
  }

  Future<void> _bootstrap() async {
    try {
      final stored = await ApiUrlStore.read();
      final url =
          (stored != null && stored.isNotEmpty) ? stored : AppConfig.apiBaseUrl;
      if (!mounted) {
        return;
      }
      setState(() {
        _api = ApiService(url);
      });
      // Check for app updates after API is ready
      if (mounted) {
        AppUpdateService.checkForUpdate(context, _api!);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _bootError = e.toString());
    }
  }

  Future<void> _reloadApiAfterUrlChange() async {
    final stored = await ApiUrlStore.read();
    final url =
        (stored != null && stored.isNotEmpty) ? stored : AppConfig.apiBaseUrl;
    await AuthStore.clearToken();
    if (!mounted) {
      return;
    }
    setState(() {
      _api = ApiService(url);
      _token = null;
    });
  }

  void _setToken(String? t) {
    setState(() => _token = t);
    if (t != null) {
      AuthStore.saveToken(t);
    } else {
      AuthStore.clearToken();
    }
  }

  void _requireLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountPage(
          api: _api!,
          token: _token,
          onTokenChanged: _setToken,
          onApiReload: _reloadApiAfterUrlChange,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bootError != null) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(_bootError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (_api == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandNavy),
              const SizedBox(height: 16),
              Text(
                'Connecting…',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final api = _api!;
    final originKey = api.baseUrl;

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          FeedPage(
            key: ValueKey(originKey),
            api: api,
            webOrigin: AppConfig.webOriginFromApiBase(api.baseUrl),
            onOpenAccountTab: _requireLogin,
          ),
          ToolsPage(api: api, token: _token, onRequireLogin: _requireLogin),
          BusinessDirectoryPage(api: api, token: _token, onRequireLogin: _requireLogin),
          JobHubPage(api: api),
          const LocalExplorerScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandNavy.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tricolor strip at top of footer
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(child: Container(height: 3, color: const Color(0xFFFF9933))), // Saffron
                  Expanded(child: Container(height: 3, color: Colors.white)),             // White
                  Expanded(child: Container(height: 3, color: const Color(0xFF138808))), // Green
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) {
                  HapticService.selectionTap();
                  setState(() => _tab = i);
                },
                height: 68,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_rounded, size: 26),
                    selectedIcon: Icon(Icons.home_rounded, size: 28),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.handyman_rounded, size: 26),
                    selectedIcon: Icon(Icons.handyman_rounded, size: 28),
                    label: 'Tools',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.storefront_rounded, size: 26),
                    selectedIcon: Icon(Icons.storefront_rounded, size: 28),
                    label: 'Directory',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.work_rounded, size: 26),
                    selectedIcon: Icon(Icons.work_rounded, size: 28),
                    label: 'Jobs',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.explore_rounded, size: 26),
                    selectedIcon: Icon(Icons.explore_rounded, size: 28),
                    label: 'Explore',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
