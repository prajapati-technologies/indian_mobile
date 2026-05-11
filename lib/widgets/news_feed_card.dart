import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class NewsFeedCard extends StatelessWidget {
  const NewsFeedCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;

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

  Color _getBadgeColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('sarkari') || lower.contains('yojana')) {
      return const Color(0xFFE6F4EA); // Light Green
    }
    if (lower.contains('job') || lower.contains('recruitment')) {
      return const Color(0xFFE3F2FD); // Light Blue
    }
    if (lower.contains('education') || lower.contains('exam')) {
      return const Color(0xFFF3E5F5); // Light Purple
    }
    return const Color(0xFFFCE4EC); // Default Light Pink/Orange
  }

  Color _getTextColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('sarkari') || lower.contains('yojana')) {
      return const Color(0xFF1E8E3E); // Dark Green
    }
    if (lower.contains('job') || lower.contains('recruitment')) {
      return const Color(0xFF1976D2); // Dark Blue
    }
    if (lower.contains('education') || lower.contains('exam')) {
      return const Color(0xFF7B1FA2); // Dark Purple
    }
    return const Color(0xFFC2185B); // Default Dark Pink
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleWeb(item);
    final img = item['image_url'] as String?;
    final timeLine = _timeLine(item);
    
    // Parse category name from item
    final catObj = item['category'];
    String categoryName = 'NEWS';
    if (catObj is Map && catObj['name'] != null) {
      categoryName = catObj['name'].toString().toUpperCase();
    } else if (catObj is List && catObj.isNotEmpty) {
      categoryName = catObj[0].toString().toUpperCase();
    }

    final int views = (item['views_count'] as int?) ?? 0;
    String viewsCount = views.toString();
    if (views >= 1000) {
      viewsCount = '${(views / 1000).toStringAsFixed(1)}K';
    }

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 80,
                  child: img != null
                      ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.borderLight))
                      : Container(color: AppColors.borderLight),
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Badge and Bookmark
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getBadgeColor(categoryName),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              color: _getTextColor(categoryName),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.bookmark_border,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Bottom row: Time and Views
                    Row(
                      children: [
                        if (timeLine != null)
                          Text(
                            timeLine,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (timeLine != null)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('|', style: TextStyle(color: AppColors.borderLight, fontSize: 11)),
                          ),
                        const Icon(Icons.remove_red_eye_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          viewsCount,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
