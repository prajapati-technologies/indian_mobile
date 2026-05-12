import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'calculator_tool_page.dart';
import '../utilities/utility_tool_page.dart';

/// Shared grid card: icon on top, title below — 2 per row.
class _ToolsGridCard extends StatelessWidget {
  const _ToolsGridCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.7), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    height: 1.2,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                      height: 1.2,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  childAspectRatio: 0.8,
);

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key, required this.api, this.token, required this.onRequireLogin});

  final ApiService api;
  final String? token;
  final VoidCallback onRequireLogin;

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  // AdMob State
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  void _loadAds() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white, // Cleaner background
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
          toolbarHeight: 70,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                onPressed: () {},
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('Tools', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brandNavy, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('Smart Tools for Your Daily Needs', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 48), // Balance for center alignment
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.brandOrange, width: 3)),
                  ),
                  labelColor: AppColors.brandOrange,
                  unselectedLabelColor: Colors.black87,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calculate, size: 18, color: AppColors.brandOrange),
                          const SizedBox(width: 6),
                          const Text('Calculator'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group, size: 18, color: Colors.green.shade700),
                          const SizedBox(width: 6),
                          const Text('Unity Tools'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _CalculatorsList(token: widget.token, onRequireLogin: widget.onRequireLogin),
                  _UtilityToolsList(api: widget.api, token: widget.token, onRequireLogin: widget.onRequireLogin),
                ],
              ),
            ),
            if (_isBannerLoaded && _bannerAd != null)
              Container(
                color: Colors.white,
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorsList extends StatelessWidget {
  const _CalculatorsList({required this.token, required this.onRequireLogin});
  final String? token;
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.brandOrange, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Calculator Tools', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text('All types of calculator tools in one place', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            gridDelegate: _gridDelegate,
            itemCount: kCalculatorMenu.length,
            itemBuilder: (context, index) {
              final e = kCalculatorMenu[index];
              return _ToolsGridCard(
                icon: e.icon,
                title: e.title,
                subtitle: e.subtitle,
                color: e.color,
                onTap: () {
                  if (token == null) {
                    onRequireLogin();
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => CalculatorToolPage(
                        calcKey: e.key,
                        title: e.title,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UtilityToolsList extends StatefulWidget {
  const _UtilityToolsList({required this.api, required this.token, required this.onRequireLogin});

  final ApiService api;
  final String? token;
  final VoidCallback onRequireLogin;

  @override
  State<_UtilityToolsList> createState() => _UtilityToolsListState();
}

class _UtilityToolsListState extends State<_UtilityToolsList> {
  bool _loading = true;
  String? _error;
  List<dynamic> _tools = [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final j = await widget.api.getJson('/utilities');
      setState(() {
        _tools = (j['data'] as List<dynamic>?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiConnectionException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.brandOrange,
      onRefresh: _load,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator(color: AppColors.brandNavy)),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.handyman_outlined, color: Colors.green.shade700, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unity Tools', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text('Essential utilities and helpers in one place', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            gridDelegate: _gridDelegate,
            itemCount: _tools.length,
            itemBuilder: (context, index) {
              final colors = [
                Colors.blue.shade600,
                Colors.orange.shade600,
                Colors.purple.shade600,
                Colors.teal.shade600,
                Colors.red.shade600,
                Colors.indigo.shade600,
                Colors.pink.shade600,
                Colors.green.shade600,
              ];
              final itemColor = colors[index % colors.length];
              
              final row = _tools[index] as Map<String, dynamic>;
              final key = row['key'] as String? ?? '';
              final title = row['title'] as String? ?? key;
              final icon = _getIconForKey(key);
              
              return _ToolsGridCard(
                icon: icon,
                title: title,
                subtitle: 'Utility tool',
                color: itemColor,
                onTap: () {
                  if (widget.token == null) {
                    widget.onRequireLogin();
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => UtilityToolPage(
                        toolKey: key,
                        title: title,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForKey(String key) {
    switch (key) {
      case 'pdf-word':
      case 'pdf-merge-split':
        return Icons.picture_as_pdf_outlined;
      case 'image-compressor':
      case 'image-resize-convert':
        return Icons.image_outlined;
      case 'word-count-case':
        return Icons.text_fields;
      case 'image-ocr':
        return Icons.document_scanner_outlined;
      case 'qr-generator':
        return Icons.qr_code_2;
      case 'barcode-generator':
        return Icons.line_weight; // fallback for barcode since barcode_reader might not exist in older flutter
      case 'password-generator':
        return Icons.password;
      case 'password-strength':
        return Icons.shield_outlined;
      case 'hash-generator':
        return Icons.tag;
      case 'base64-encode-decode':
        return Icons.abc;
      case 'image-watermark':
        return Icons.branding_watermark;
      case 'meme-maker':
        return Icons.emoji_emotions_outlined;
      case 'image-to-pdf':
        return Icons.image;
      case 'pdf-watermark':
        return Icons.water_drop;
      case 'pdf-password-protect':
        return Icons.lock_outline;
      default:
        return Icons.handyman_outlined;
    }
  }
}
