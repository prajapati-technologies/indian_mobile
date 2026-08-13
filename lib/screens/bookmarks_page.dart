import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/offline_cache_service.dart';
import '../theme/app_theme.dart';
import 'news_detail_page.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key, required this.api});
  final ApiService api;

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<Map<String, dynamic>> _bookmarks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookmarks = await OfflineCacheService.getBookmarks();
    setState(() {
      _bookmarks = bookmarks;
      _loading = false;
    });
  }

  Future<void> _removeBookmark(String slug) async {
    await OfflineCacheService.removeBookmark(slug);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from saved'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Saved Articles'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandNavy))
          : _bookmarks.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final article = _bookmarks[index];
                    return _buildCard(article);
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('No saved articles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Tap the bookmark icon on any news article to save it for later', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> article) {
    final title = article['title'] as String? ?? '';
    final slug = article['slug'] as String? ?? '';
    final imageUrl = article['image_url'] as String?;
    final bookmarkedAt = article['bookmarked_at'] as String?;

    String timeAgo = '';
    if (bookmarkedAt != null) {
      try {
        final dt = DateTime.parse(bookmarkedAt);
        timeAgo = 'Saved ${DateFormat('dd MMM').format(dt)}';
      } catch (_) {}
    }

    return Dismissible(
      key: Key(slug),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.red, size: 28),
      ),
      onDismissed: (_) => _removeBookmark(slug),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (slug.isNotEmpty) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => NewsDetailPage(api: widget.api, slug: slug),
                ));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl != null
                        ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder())
                        : _placeholder(),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3)),
                        const SizedBox(height: 6),
                        Text(timeAgo, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  // Remove button
                  IconButton(
                    onPressed: () => _removeBookmark(slug),
                    icon: const Icon(Icons.bookmark_remove_rounded, color: AppColors.brandOrange),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(color: AppColors.pageBackground, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.article_rounded, color: AppColors.textMuted, size: 28),
    );
  }
}
