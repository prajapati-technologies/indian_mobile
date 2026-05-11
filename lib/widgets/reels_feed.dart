import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ReelsFeed extends StatefulWidget {
  final List<dynamic> news;
  final VoidCallback onRefresh;

  const ReelsFeed({
    super.key,
    required this.news,
    required this.onRefresh,
  });

  @override
  State<ReelsFeed> createState() => _ReelsFeedState();
}

class _ReelsFeedState extends State<ReelsFeed> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.news.isEmpty) {
      return const Center(child: Text('No news available.'));
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _pageController,
      itemCount: widget.news.length,
      itemBuilder: (context, index) {
        final item = widget.news[index] as Map<String, dynamic>;
        return _ReelItem(item: item);
      },
    );
  }
}

class _ReelItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ReelItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final String title = item['ai_title'] ?? item['title'] ?? 'No Title';
    final String summary = item['ai_summary'] ?? item['short_description'] ?? 'No summary available.';
    final String? imageUrl = item['ai_thumbnail_url'] ?? item['image_url'];
    final String source = item['source_name'] ?? 'Unknown Source';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        if (imageUrl != null)
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.black87,
              child: Shimmer.fromColors(
                baseColor: Colors.grey[900]!,
                highlightColor: Colors.grey[800]!,
                child: Container(color: Colors.black),
              ),
            ),
            errorWidget: (context, url, error) => Container(color: Colors.black87),
          )
        else
          Container(color: Colors.black87),

        // Dark Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: 40,
          left: 16,
          right: 70, // Space for side buttons
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source Badge
              GlassContainer.clearGlass(
                height: 28,
                width: 120,
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: Text(
                    source,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 12),
              // Summary
              Text(
                summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Side Interaction Buttons (Placeholder for Social Features)
        Positioned(
          bottom: 100,
          right: 12,
          child: Column(
            children: [
              _SideButton(icon: Icons.favorite_border, label: 'Like'),
              const SizedBox(height: 20),
              _SideButton(icon: Icons.comment_outlined, label: 'Comment'),
              const SizedBox(height: 20),
              _SideButton(icon: Icons.share_outlined, label: 'Share'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SideButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassContainer.clearGlass(
          height: 50,
          width: 50,
          shape: BoxShape.circle,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
