import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/news_feed_card.dart';
import '../widgets/reels_feed.dart';
import 'category_news_page.dart';
import 'news_detail_page.dart';

/// Home / News tab — layout aligned with web `home.blade.php` (logo header, cards, green accent).
class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.api,
    required this.webOrigin,
    this.onOpenServerSettings,
    this.onOpenAccountTab,
  });

  final ApiService api;

  /// Public site origin (`…/public`) for logo `images/site-logo.png`.
  final String webOrigin;

  /// Switches to Account tab so user can set API URL (real device + PC IP).
  final VoidCallback? onOpenServerSettings;

  /// Same as website header — jump to Account tab.
  final VoidCallback? onOpenAccountTab;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const int _newsBatchSize = 15;

  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  String? _error;
  bool _connectionError = false;
  List<dynamic> _banners = [];
  List<dynamic> _news = [];
  List<dynamic> _categories = [];

  /// View mode: 1 for Reels, 0 for List (Default Reels as per user request)
  int _viewMode = 1;

  // AdMob State
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  final ScrollController _scrollController = ScrollController();

  String get _logoUrl => '${widget.webOrigin}/images/site-logo.png';

  bool get _hasMoreNewsToShow => _currentPage < _lastPage;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _currentPage = 1;
    });
    try {
      final b = await widget.api.getJson('/banners') as Map<String, dynamic>;
      final n = await widget.api.getJson('/news?page=1') as Map<String, dynamic>;
      final c = await widget.api.getJson('/categories') as Map<String, dynamic>;

      setState(() {
        _banners = (b['data'] as List<dynamic>?) ?? [];
        _news = (n['data'] as List<dynamic>?) ?? [];
        _currentPage = (n['current_page'] as int?) ?? 1;
        _lastPage = (n['last_page'] as int?) ?? 1;
        _categories = (c['data'] as List<dynamic>?) ?? [];
        _connectionError = false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _connectionError = e is ApiConnectionException;
        _error = e is ApiConnectionException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreNews() async {
    if (_loadingMore || !_hasMoreNewsToShow) return;
    setState(() {
      _loadingMore = true;
    });
    try {
      final nextPage = _currentPage + 1;
      final n = await widget.api.getJson('/news?page=$nextPage') as Map<String, dynamic>;
      
      setState(() {
        final newItems = (n['data'] as List<dynamic>?) ?? [];
        _news.addAll(newItems);
        _currentPage = (n['current_page'] as int?) ?? nextPage;
        _lastPage = (n['last_page'] as int?) ?? nextPage;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _loadingMore = false;
      });
    }
  }

  void _openCategoriesBottomSheet() {
    final hostContext = context;
    final future = widget.api.getJson('/categories');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.52,
          minChildSize: 0.32,
          maxChildSize: 0.92,
          builder: (ctx, scrollController) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x140B2C5F),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: FutureBuilder<dynamic>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.brandNavy),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    final msg = snapshot.error is ApiConnectionException
                        ? (snapshot.error as ApiConnectionException).message
                        : snapshot.error.toString();
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(msg, style: const TextStyle(color: AppColors.textPrimary)),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                  final j = snapshot.data as Map<String, dynamic>?;
                  final items = (j?['data'] as List<dynamic>?) ?? [];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No categories found',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'All categories',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.brandNavy,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close),
                              color: AppColors.brandNavy,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE8EDF6)),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF0F4FA)),
                          itemBuilder: (context, index) {
                            final row = items[index] as Map<String, dynamic>;
                            final name = row['name'] as String? ?? '';
                            final slug = row['slug'] as String? ?? '';
                            return InkWell(
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                Navigator.of(hostContext).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CategoryNewsPage(
                                      api: widget.api,
                                      slug: slug,
                                      title: name,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: AppColors.brandNavy,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'No new notifications yet. Updates will appear here soon.',
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAds();
    _load();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Image.network(
            _logoUrl,
            height: 62,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, _, _) => Text(
              'Indian Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.brandNavy,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: _viewMode == 0 ? 'Switch to Reels' : 'Switch to List',
            icon: Icon(_viewMode == 0 ? Icons.play_circle_outline : Icons.view_list_outlined),
            color: AppColors.brandNavy,
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 0 ? 1 : 0;
              });
            },
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.brandNavy,
            onPressed: _showNotificationsToast,
          ),
          IconButton(
            tooltip: 'My Account',
            icon: const Icon(Icons.person_outline),
            color: AppColors.brandNavy,
            onPressed: widget.onOpenAccountTab,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _viewMode == 1
                ? ReelsFeed(news: _news, onRefresh: _load)
                : RefreshIndicator(
                    color: AppColors.brandOrange,
                    onRefresh: _load,
                    child: _buildBody(),
                  ),
          ),
          if (_isBannerLoaded && _bannerAd != null && _viewMode == 0)
            Container(
              color: Colors.white,
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
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
      final openAccount = widget.onOpenAccountTab ?? widget.onOpenServerSettings;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        _connectionError ? Icons.wifi_off_rounded : Icons.error_outline,
                        color: AppColors.brandOrange,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _connectionError
                              ? 'Could not reach the server'
                              : 'Could not load news',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.brandNavy,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (_connectionError) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Please check your internet connection and try again.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SelectableText(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. Categories Horizontal List
        if (_categories.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index] as Map<String, dynamic>;
                    final name = cat['name'] as String? ?? '';
                    final slug = cat['slug'] as String? ?? '';
                    return ActionChip(
                      label: Text(name),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.brandNavy),
                      backgroundColor: AppColors.cardMutedBg,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CategoryNewsPage(
                              api: widget.api,
                              slug: slug,
                              title: name,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

        // 2. Banners
        if (_banners.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: PageView.builder(
                itemCount: _banners.length,
                itemBuilder: (context, i) {
                  final ban = _banners[i] as Map<String, dynamic>;
                  final url = ban['image_url'] as String?;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: url != null
                            ? Image.network(url, fit: BoxFit.cover, width: double.infinity)
                            : const SizedBox(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // 3. Top Stories
        if (_news.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Top Stories',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: _openCategoriesBottomSheet,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandOrange,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_news.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final topCount = _news.length > 5 ? 5 : _news.length;
                if (index >= topCount) return null;
                final row = _news[index] as Map<String, dynamic>;
                return Column(
                  children: [
                    NewsFeedCard(
                      item: row,
                      onTap: () {
                        final slug = row['slug'] as String?;
                        if (slug == null) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (ctx) => NewsDetailPage(api: widget.api, slug: slug)),
                        );
                      },
                    ),
                    if (index < topCount - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderLight),
                  ],
                );
              },
              childCount: _news.length > 5 ? 5 : _news.length,
            ),
          ),

        if (_news.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: Material(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Koi news record available nahi hai. Admin panel se "Sync Today\'s News" chalaiye.',
                    style: TextStyle(color: Color(0xFF664D03)),
                  ),
                ),
              ),
            ),
          ),

        // 4. Latest News
        if (_news.length > 5)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Latest News',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
            ),
          ),

        if (_news.length > 5)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final i = index + 5;
                if (i >= _news.length) return null;
                final row = _news[i] as Map<String, dynamic>;
                return Column(
                  children: [
                    NewsFeedCard(
                      item: row,
                      onTap: () {
                        final slug = row['slug'] as String?;
                        if (slug == null) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (ctx) => NewsDetailPage(api: widget.api, slug: slug),
                          ),
                        );
                      },
                    ),
                    if (i < _news.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderLight),
                  ],
                );
              },
              childCount: _news.length - 5,
            ),
          ),

        if (_hasMoreNewsToShow)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: OutlinedButton(
                onPressed: _loadingMore ? null : _loadMoreNews,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandNavy,
                  side: const BorderSide(color: AppColors.brandNavy),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _loadingMore 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Load More'),
              ),
            ),
          ),
        if (_news.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 28),
          ),
      ],
    );
  }
}

/// Matches web `.latest-mini-card` + `.latest-mini-title` / `.latest-mini-meta`.
class _LatestMiniCard extends StatelessWidget {
  const _LatestMiniCard({
    required this.item,
    required this.onTap,
    this.compact = false,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  /// Two-column grid: shorter image + tighter text so cells fit [childAspectRatio].
  final bool compact;

  static String _titleWeb(Map<String, dynamic> item) {
    final t = item['title'] as String? ?? '';
    if (t.length <= 80) {
      return t;
    }
    return '${t.substring(0, 80)}…';
  }

  static String? _timeLine(Map<String, dynamic> item) {
    final pub = item['published_at'] as String?;
    if (pub == null || pub.isEmpty) {
      return null;
    }
    final dt = DateTime.tryParse(pub);
    if (dt == null) {
      return null;
    }
    return DateFormat('d MMM, h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleWeb(item);
    final img = item['image_url'] as String?;
    final timeLine = _timeLine(item);
    final imageHeight = compact ? 92.0 : 120.0;
    final pad = compact ? 8.0 : 10.0;
    final titleMaxLines = compact ? 3 : 4;
    final titleSize = compact ? 12.5 : 13.76;
    final metaSize = compact ? 10.5 : 12.0;
    final metaStyle = TextStyle(
      color: const Color(0xFF6B7280),
      fontSize: metaSize,
      height: compact ? 1.2 : 1.35,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8EDF6)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (img != null)
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: Image.network(img, fit: BoxFit.cover),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad, pad, compact ? 6 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: titleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.brandNavy,
                              fontWeight: FontWeight.w600,
                              fontSize: titleSize,
                              height: compact ? 1.2 : 1.25,
                            ),
                      ),
                      if (timeLine != null) ...[
                        SizedBox(height: compact ? 2 : 5),
                        Text(timeLine, style: metaStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
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
