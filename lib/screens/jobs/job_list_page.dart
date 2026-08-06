import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'job_detail_page.dart';

class JobListPage extends StatefulWidget {
  const JobListPage({
    super.key,
    required this.api,
    required this.type,
    required this.title,
  });

  final ApiService api;
  final String type;
  final String title;

  @override
  State<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends State<JobListPage> {
  List<dynamic> _posts = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1, bool append = false}) async {
    if (!append) {
      setState(() { _loading = true; _error = null; });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final result = await widget.api.getJson(
        '/job-posts?type=${widget.type}&page=$page',
      );
      final data = result as Map<String, dynamic>;
      final newPosts = (data['data'] as List<dynamic>?) ?? [];
      setState(() {
        if (append) {
          _posts.addAll(newPosts);
        } else {
          _posts = newPosts;
        }
        _currentPage = data['meta']?['current_page'] ?? 1;
        _lastPage = data['meta']?['last_page'] ?? 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandNavy))
          : _error != null
              ? _buildError()
              : _posts.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () => _load(),
                      color: AppColors.brandOrange,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _posts.length + (_lastPage > _currentPage ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return _buildLoadMore();
                          }
                          final post = _posts[index] as Map<String, dynamic>;
                          return _buildPostCard(post);
                        },
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Could not load data', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.inbox_rounded, size: 56, color: AppColors.textMuted.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Center(child: Text('No ${widget.title.toLowerCase()} posts found', style: TextStyle(color: AppColors.textMuted, fontSize: 14))),
        const SizedBox(height: 8),
        Center(child: Text('Check back later for updates', style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 12))),
      ],
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _loadingMore
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandNavy))
            : OutlinedButton.icon(
                onPressed: () => _load(page: _currentPage + 1, append: true),
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: const Text('Load More'),
              ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final title = post['title'] as String? ?? '';
    final org = post['organization_name'] as String? ?? '';
    final totalPosts = post['total_posts'] as int?;
    final postDate = post['post_date'] as String?;
    final isFeatured = post['is_featured'] as bool? ?? false;
    final category = post['category'] as String? ?? '';
    final state = post['state'] as String? ?? '';

    String formattedDate = '';
    if (postDate != null) {
      try {
        formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(postDate));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isFeatured ? AppColors.saffron.withValues(alpha: 0.4) : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final slug = post['slug'] as String? ?? '';
            if (slug.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JobDetailPage(api: widget.api, slug: slug)),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.brandNavy,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (isFeatured)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.saffron.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: AppColors.saffron, size: 12),
                            SizedBox(width: 2),
                            Text('HOT', style: TextStyle(color: AppColors.saffron, fontSize: 9, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Meta chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (org.isNotEmpty)
                      _metaChip(Icons.business_rounded, org, AppColors.brandNavy),
                    if (totalPosts != null)
                      _metaChip(Icons.people_alt_rounded, '$totalPosts Posts', AppColors.indiaGreen),
                    if (formattedDate.isNotEmpty)
                      _metaChip(Icons.calendar_today_rounded, formattedDate, AppColors.textMuted),
                    if (category.isNotEmpty)
                      _metaChip(Icons.label_rounded, category, const Color(0xFF6A1B9A)),
                    if (state.isNotEmpty)
                      _metaChip(Icons.location_on_rounded, state, AppColors.brandOrange),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
