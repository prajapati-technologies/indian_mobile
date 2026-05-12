import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/account_page.dart';
import 'screens/categories_page.dart';
import 'screens/feed_page.dart';
import 'screens/games_page.dart';
import 'screens/tools_page.dart';
import 'screens/local_explorer/local_explorer_screen.dart';
import 'services/api_service.dart';
import 'services/auth_store.dart';
import 'services/api_url_store.dart';
import 'theme/app_theme.dart';
import 'screens/home_design/design_dashboard_screen.dart';
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
    AuthStore.readToken().then((t) {
      if (mounted) {
        setState(() => _token = t);
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
          DesignDashboardScreen(api: api, token: _token, onRequireLogin: _requireLogin),
          const LocalExplorerScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Directory',
          ),
          NavigationDestination(
            icon: Icon(Icons.architecture_outlined),
            selectedIcon: Icon(Icons.architecture),
            label: 'Home Design',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
        ],
      ),
    );
  }
}
