import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/account_page.dart';
import 'screens/feed_page.dart';
import 'screens/tools_page.dart';
import 'screens/explore_tab.dart';
import 'screens/jobs/job_hub_page.dart';
import 'services/api_service.dart';
import 'services/auth_store.dart';
import 'services/api_url_store.dart';
import 'services/app_review_service.dart';
import 'services/app_update_service.dart';
import 'services/rewarded_ad_service.dart';
import 'theme/app_theme.dart';
import 'widgets/connectivity_banner.dart';
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

    return ConnectivityBanner(
      child: Scaffold(
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
          const ExploreTab(),
          JobHubPage(api: api),
          BusinessDirectoryPage(api: api, token: _token, onRequireLogin: _requireLogin),
        ],
      ),
      bottomNavigationBar: _PremiumBottomBar(
        currentIndex: _tab,
        onTap: (i) {
          HapticService.selectionTap();
          setState(() => _tab = i);
        },
      ),
    ),
    );
  }
}


class _PremiumBottomBar extends StatelessWidget {
  const _PremiumBottomBar({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final void Function(int) onTap;

  static const _items = [
    _NavItem(icon: Icons.home_rounded, outlineIcon: Icons.home_outlined, label: 'Home', gradient: [Color(0xFF0B2C5F), Color(0xFF1A4A8A)]),
    _NavItem(icon: Icons.construction_rounded, outlineIcon: Icons.construction_outlined, label: 'Tools', gradient: [Color(0xFFE65100), Color(0xFFFF9933)]),
    _NavItem(icon: Icons.explore_rounded, outlineIcon: Icons.explore_outlined, label: 'Explore', gradient: [Color(0xFFE91E63), Color(0xFFFF5252)]),
    _NavItem(icon: Icons.work_rounded, outlineIcon: Icons.work_outline_rounded, label: 'Jobs', gradient: [Color(0xFF6A1B9A), Color(0xFF9C27B0)]),
    _NavItem(icon: Icons.storefront_rounded, outlineIcon: Icons.storefront_outlined, label: 'Directory', gradient: [Color(0xFF138808), Color(0xFF2E9D1E)]),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.only(top: 14, bottom: 8, left: 6, right: 6),
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
          width: 1.5,
        ),
        boxShadow: [
          // Main deep shadow (3D depth)
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 30,
            spreadRadius: -2,
            offset: const Offset(0, 12),
          ),
          // Inner glow (3D raised effect)
          BoxShadow(
            color: (isDark ? Colors.white : AppColors.brandNavy).withValues(alpha: 0.03),
            blurRadius: 1,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final isActive = currentIndex == i;
          return _NavItemWidget(item: item, isActive: isActive, onTap: () => onTap(i), isDark: isDark);
        }),
      ),
    );
  }
}

class _NavItemWidget extends StatefulWidget {
  const _NavItemWidget({required this.item, required this.isActive, required this.onTap, required this.isDark});
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3D Floating Icon
              Transform.translate(
                offset: widget.isActive ? const Offset(0, -4) : Offset.zero,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  width: widget.isActive ? 44 : 36,
                  height: widget.isActive ? 44 : 36,
                  decoration: BoxDecoration(
                  gradient: widget.isActive
                      ? LinearGradient(
                          colors: widget.item.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.isActive ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.isActive ? 16 : 12),
                  boxShadow: widget.isActive
                      ? [
                          // 3D raised shadow
                          BoxShadow(
                            color: widget.item.gradient[0].withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: const Offset(0, 6),
                          ),
                          // Bottom highlight (3D depth)
                          BoxShadow(
                            color: widget.item.gradient[1].withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.isActive ? widget.item.icon : widget.item.outlineIcon,
                  size: widget.isActive ? 24 : 22,
                  color: widget.isActive ? Colors.white : (widget.isDark ? Colors.grey[500] : AppColors.textMuted),
                ),
              ),
              ),
              SizedBox(height: widget.isActive ? 6 : 4),
              // Label
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: widget.isActive ? 10 : 9.5,
                  fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w500,
                  color: widget.isActive ? widget.item.gradient[0] : (widget.isDark ? Colors.grey[500] : AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.outlineIcon, required this.label, required this.gradient});
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  final List<Color> gradient;
}
