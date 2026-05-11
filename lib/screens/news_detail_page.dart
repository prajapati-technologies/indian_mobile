import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';

import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../services/auth_store.dart';
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
      _startTimer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
    final text = 'Read this on India Info Super App: $title\nDownload now to earn rewards and stay updated: https://indiainfo.app';
    
    final result = await Share.share(text);
    
    final token = await AuthStore.readToken();
    if (result.status == ShareResultStatus.success && token != null) {
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
        SelectableText(body, style: Theme.of(context).textTheme.bodyLarge),
        if (link != null && link.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Source link',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SelectableText(link),
        ],

        if (_related.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Text(
            'Related News',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandNavy),
          ),
          const SizedBox(height: 12),
          ..._related.map((item) => _buildRelatedCard(item)).toList(),
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
