import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../services/offline_cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/news_feed_card.dart';
import '../widgets/trending_section.dart';
import 'bookmarks_page.dart';
import 'category_news_page.dart';
import 'news_detail_page.dart';
import 'search_page.dart';
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

      // Cache for offline use
      OfflineCacheService.cacheResponse('feed_banners', b);
      OfflineCacheService.cacheResponse('feed_featured', f);
      OfflineCacheService.cacheResponse('feed_categories', c);
    } catch (e) {
      // Try loading from offline cache
      final cachedB = await OfflineCacheService.getCachedResponseForce('feed_banners');
      final cachedF = await OfflineCacheService.getCachedResponseForce('feed_featured');
      final cachedC = await OfflineCacheService.getCachedResponseForce('feed_categories');

      if (cachedF != null || cachedC != null) {
        setState(() {
          _banners = (cachedB != null ? (cachedB as Map<String, dynamic>)['data'] as List<dynamic>? : null) ?? [];
          _featuredSections = (cachedF != null ? (cachedF as Map<String, dynamic>)['data'] as List<dynamic>? : null) ?? [];
          _categories = (cachedC != null ? (cachedC as Map<String, dynamic>)['data'] as List<dynamic>? : null) ?? [];
          _connectionError = false;
          _loading = false;
        });
      } else {
        setState(() {
          _connectionError = e is ApiConnectionException;
          _error = e is ApiConnectionException ? e.message : e.toString();
          _loading = false;
        });
      }
    }
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
              'India Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.brandNavy,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            color: AppColors.brandNavy,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => SearchPage(api: widget.api),
              ));
            },
          ),
          IconButton(
            tooltip: 'Saved Articles',
            icon: const Icon(Icons.bookmark_rounded),
            color: AppColors.brandNavy,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BookmarksPage(api: widget.api),
              ));
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

        // 2.5 Trending Now Section
        SliverToBoxAdapter(
          child: TrendingSection(api: widget.api),
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
