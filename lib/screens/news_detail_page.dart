import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';
import '../services/offline_cache_service.dart';
import '../theme/app_theme.dart';

class NewsDetailPage extends StatefulWidget {
  const NewsDetailPage({super.key, required this.api, required this.slug});

  final ApiService api;
  final String slug;

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  List<dynamic> _related = [];
  bool _isBookmarked = false;

  // News Read Reward State
  Timer? _timer;
  int _secondsElapsed = 0;
  int _targetSeconds = 0;
  bool _rewardClaimed = false;

  // AdMob State
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final j = await widget.api.getJson('/news/${widget.slug}');
      setState(() {
        _data = j['data'] as Map<String, dynamic>?;
        _related = (j['related'] as List<dynamic>?) ?? [];
        _loading = false;
      });
      _checkBookmark();
      _startTimer();
    } catch (e) {
      // Try offline cache fallback
      final cached = await OfflineCacheService.getCachedResponseForce('news_${widget.slug}');
      if (cached != null) {
        setState(() {
          _data = (cached as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
          _related = (cached['related'] as List<dynamic>?) ?? [];
          _loading = false;
          _error = null;
        });
        _checkBookmark();
      } else {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }

    // Cache the response for offline use
    if (_data != null) {
      OfflineCacheService.cacheResponse('news_${widget.slug}', {'data': _data, 'related': _related});
    }
  }

  Future<void> _checkBookmark() async {
    final bookmarked = await OfflineCacheService.isBookmarked(widget.slug);
    if (mounted) setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _toggleBookmark() async {
    if (_data == null) return;
    if (_isBookmarked) {
      await OfflineCacheService.removeBookmark(widget.slug);
      if (mounted) {
        setState(() => _isBookmarked = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from saved'), duration: Duration(seconds: 1)),
        );
      }
    } else {
      final article = {
        'title': _data!['title'],
        'slug': _data!['slug'] ?? widget.slug,
        'image_url': _data!['image_url'],
        'published_at': _data!['published_at'],
        'category': _data!['category'],
      };
      await OfflineCacheService.addBookmark(article);
      if (mounted) {
        setState(() => _isBookmarked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved for later ✓'), duration: Duration(seconds: 1)),
        );
      }
    }
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

  void _startTimer() {
    _timer?.cancel();
    if (_data != null && _data!['read_time'] != null) {
      int readTimeMins = _data!['read_time'] as int;
      _targetSeconds = (readTimeMins * 60 * 0.75).toInt();
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _secondsElapsed++;
        });

        if (_secondsElapsed >= _targetSeconds && !_rewardClaimed) {
          _claimReward();
          timer.cancel();
        }
      });
    }
  }

  Future<void> _claimReward() async {
    final token = await AuthStore.readToken();
    if (token == null) return; // Must be logged in

    try {
      final res = await widget.api.postJson(
        '/news/reward',
        {'news_id': _data!['id']},
        token: token,
      );
      if (mounted && res != null && res['coins_earned'] != null) {
        setState(() {
          _rewardClaimed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 8),
                Text(res['message'] ?? 'Coin earned for reading!'),
              ],
            ),
            backgroundColor: AppColors.brandNavy,
          ),
        );
      }
    } catch (e) {
      // Ignored if already claimed or other error
      debugPrint('Failed to claim news reward: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _shareArticle() async {
    if (_data == null) return;
    
    final title = _data!['title'] ?? 'News Update';
    final slug = _data!['slug'] ?? widget.slug;
    final newsUrl = 'https://indiainformations.com/news/$slug';
    final text = '$title\n\nRead more: $newsUrl\n\nDownload India Informations App for latest news & tools!';
    
    await Share.share(text, subject: title);
    
    final token = await AuthStore.readToken();
    if (token != null) {
      try {
        final res = await widget.api.postJson('/gamification/share', {
          'content_type': 'news',
          'content_id': widget.slug,
        }, token: token);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(res['message'] ?? 'Earned XP & Coins for sharing!'),
              ],
            ),
            backgroundColor: AppColors.brandNavy,
          ));
        }
      } catch (_) {
        // Ignore API errors if sharing tracking fails
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _data?['title'] as String? ?? 'Article';
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            color: _isBookmarked ? AppColors.brandOrange : null,
            onPressed: _toggleBookmark,
            tooltip: _isBookmarked ? 'Remove from saved' : 'Save for later',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareArticle,
            tooltip: 'Share & Earn',
          ),
        ],
      ),
      body: Column(
        children: [
          // Reading Progress Bar
          if (!_loading && _targetSeconds > 0 && !_rewardClaimed)
            LinearProgressIndicator(
              value: (_secondsElapsed / _targetSeconds).clamp(0.0, 1.0),
              backgroundColor: AppColors.borderLight,
              color: AppColors.brandOrange,
              minHeight: 4,
            ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(),
            ),
          ),

          // AdMob Banner
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              tooltip: 'Home',
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareArticle,
              tooltip: 'Share',
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_outline),
              onPressed: () {},
              tooltip: 'Save',
            ),
            IconButton(
              icon: const Icon(Icons.text_increase),
              onPressed: () {},
              tooltip: 'Font Size',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
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

    final d = _data!;
    final img = d['image_url'] as String?;
    final body = d['full_description'] as String? ?? '';
    final source = d['source_name'] as String?;
    final link = d['link'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (img != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(img, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          d['title'] as String? ?? '',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        if (source != null)
          Text(
            source,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        if (d['read_time'] != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.timer, size: 14, color: AppColors.brandOrange),
              const SizedBox(width: 4),
              Text(
                '${d['read_time']} min read',
                style: const TextStyle(fontSize: 12, color: AppColors.brandOrange, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        HtmlWidget(
          body,
          textStyle: Theme.of(context).textTheme.bodyLarge,
        ),
        if (link != null && link.isNotEmpty && !link.startsWith('manual://')) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final title = d['title'] as String? ?? 'Article';
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      body: WebViewWidget(
                        controller: WebViewController()
                          ..setJavaScriptMode(JavaScriptMode.unrestricted)
                          ..loadRequest(Uri.parse(link)),
                      ),
                      bottomNavigationBar: _buildBottomBar(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Read Full Article'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],

        if (_related.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Text(
            'Related News',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandNavy),
          ),
          const SizedBox(height: 12),
          ..._related.map((item) => _buildRelatedCard(item)),
        ],
      ],
    );
  }

  Widget _buildRelatedCard(dynamic item) {
    final title = item['title'] as String? ?? '';
    final slug = item['slug'] as String? ?? '';
    final imageUrl = item['image_url'] as String?;
    final date = item['published_at'] != null ? item['published_at'].toString().split('T')[0] : '';

    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (ctx) => NewsDetailPage(api: widget.api, slug: slug)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
