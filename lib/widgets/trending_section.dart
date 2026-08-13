import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/news_detail_page.dart';
import 'optimized_image.dart';

/// Shows "Trending Now" section — most viewed news in last 24hrs.
class TrendingSection extends StatefulWidget {
  const TrendingSection({super.key, required this.api});
  final ApiService api;

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  List<dynamic> _trending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.api.getJson('/news/trending');
      final data = result as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _trending = (data['data'] as List<dynamic>?) ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _trending.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department_rounded, size: 18, color: Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trending Now',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('🔥 ${_trending.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trending.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildTrendingCard(_trending[index] as Map<String, dynamic>, index),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCard(Map<String, dynamic> item, int index) {
    final title = item['title'] as String? ?? '';
    final slug = item['slug'] as String? ?? '';
    final imageUrl = item['image_url'] as String?;
    final readTime = item['read_time'] as int? ?? 1;
    final views = item['views_count'] as int? ?? 0;

    return GestureDetector(
      onTap: () {
        if (slug.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailPage(api: widget.api, slug: slug)));
        }
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with rank badge
            Stack(
              children: [
                OptimizedImage(imageUrl: imageUrl, width: 260, height: 100, borderRadius: 16),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('#${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text('$readTime min read', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(width: 10),
                      Icon(Icons.visibility_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text('${views > 999 ? '${(views / 1000).toStringAsFixed(1)}K' : views}', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
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
