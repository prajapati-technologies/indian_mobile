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
import 'jobs/job_list_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.api,
    required this.webOrigin,
    this.onOpenServerSettings,
    this.onOpenAccountTab,
  });

  final ApiService api;
  final String webOrigin;
  final VoidCallback? onOpenServerSettings;
  final VoidCallback? onOpenAccountTab;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  bool _loading = true;
  String? _error;
  bool _connectionError = false;
  List<dynamic> _banners = [];
  List<dynamic> _categories = [];
  List<dynamic> _featuredSections = [];

  int _viewMode = 0;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  String get _logoUrl => '${widget.webOrigin}/images/site-logo.png';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.getJson('/banners'),
        widget.api.getJson('/news/featured-categories'),
        widget.api.getJson('/categories'),
      ]);
      final b = results[0] as Map<String, dynamic>;
      final f = results[1] as Map<String, dynamic>;
      final c = results[2] as Map<String, dynamic>;

      setState(() {
        _banners = (b['data'] as List<dynamic>?) ?? [];
        _featuredSections = (f['data'] as List<dynamic>?) ?? [];
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
            child: RefreshIndicator(
              color: AppColors.brandOrange,
              onRefresh: _load,
              child: _buildBody(),
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

        // 3. Featured Category Sections
        if (_featuredSections.isEmpty && _categories.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'No featured categories. Admin panel me categories ko featured mark karein.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          ),

        ..._featuredSections.map((section) {
          final catName = section['name'] as String? ?? '';
          final catSlug = section['slug'] as String? ?? '';
          final newsList = (section['news'] as List<dynamic>?) ?? [];
          if (newsList.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

          return SliverMainAxisGroup(
            slivers: [
              // Category header with View More
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          catName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CategoryNewsPage(
                                api: widget.api,
                                slug: catSlug,
                                title: catName,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brandOrange,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View More', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // News cards for this category
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = newsList[index] as Map<String, dynamic>;
                    return Column(
                      children: [
                        NewsFeedCard(
                          item: item,
                          onTap: () {
                            final slug = item['slug'] as String?;
                            if (slug == null) return;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (ctx) => NewsDetailPage(api: widget.api, slug: slug)),
                            );
                          },
                        ),
                        if (index < newsList.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderLight),
                      ],
                    );
                  },
                  childCount: newsList.length,
                ),
              ),
            ],
          );
        }),

        if (_featuredSections.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(height: 12),
          ),

        // 4. Latest Jobs Section on Home
        SliverToBoxAdapter(
          child: _LatestJobsHomeSection(api: widget.api),
        ),

        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 28),
        ),
      ],
    );
  }
}

class _LatestMiniCard extends StatelessWidget {
  const _LatestMiniCard({
    required this.item,
    required this.onTap,
    this.compact = false,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;

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

class _LatestJobsHomeSection extends StatefulWidget {
  const _LatestJobsHomeSection({required this.api});
  final ApiService api;

  @override
  State<_LatestJobsHomeSection> createState() => _LatestJobsHomeSectionState();
}

class _LatestJobsHomeSectionState extends State<_LatestJobsHomeSection> {
  List<dynamic> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final result = await widget.api.getJson('/job-posts/latest');
      final data = result as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _jobs = (data['data'] as List<dynamic>?) ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _jobs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.work_rounded, size: 22, color: AppColors.brandNavy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Latest Jobs & Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => JobListPage(api: widget.api, type: 'job', title: 'Latest Job'),
                  ));
                },
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
        ..._jobs.take(5).map((job) {
          final j = job as Map<String, dynamic>;
          final title = j['title'] as String? ?? '';
          final org = j['organization_name'] as String? ?? '';
          final type = j['type'] as String? ?? 'job';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  final slug = j['slug'] as String? ?? '';
                  if (slug.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => JobListPage(api: widget.api, type: type, title: _typeLabel(type)),
                    ));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _typeColor(type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_typeIcon(type), size: 20, color: _typeColor(type)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandNavy)),
                            if (org.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(org, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _typeColor(type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_typeLabel(type), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _typeColor(type))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'admit_card': return 'Admit Card';
      case 'result': return 'Result';
      case 'admission': return 'Admission';
      default: return 'Job';
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'admit_card': return const Color(0xFF138808);
      case 'result': return const Color(0xFFFF9933);
      case 'admission': return const Color(0xFF6A1B9A);
      default: return AppColors.brandNavy;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'admit_card': return Icons.badge_rounded;
      case 'result': return Icons.poll_rounded;
      case 'admission': return Icons.school_rounded;
      default: return Icons.work_rounded;
    }
  }
}
