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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.getJson(
        '/job-posts?type=${widget.type}&page=$page',
      );
      final data = result as Map<String, dynamic>;
      setState(() {
        _posts = (data['data'] as List<dynamic>?) ?? [];
        _currentPage = data['meta']?['current_page'] ?? 1;
        _lastPage = data['meta']?['last_page'] ?? 1;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandNavy))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? const Center(child: Text('No posts found'))
                  : RefreshIndicator(
                      onRefresh: () => _load(page: _currentPage),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _posts.length + (_lastPage > _currentPage ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: TextButton(
                                  onPressed: () => _load(page: _currentPage + 1),
                                  child: const Text('Load More'),
                                ),
                              ),
                            );
                          }
                          final post = _posts[index] as Map<String, dynamic>;
                          return _buildPostCard(post);
                        },
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

    String formattedDate = '';
    if (postDate != null) {
      try {
        formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(postDate));
      } catch (_) {}
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final slug = post['slug'] as String? ?? '';
          if (slug.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobDetailPage(api: widget.api, slug: slug),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      ),
                    ),
                  ),
                  if (isFeatured)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (org.isNotEmpty)
                    _chip(Icons.business_rounded, org, AppColors.brandNavy),
                  if (totalPosts != null)
                    _chip(Icons.people_rounded, '$totalPosts Posts', const Color(0xFF138808)),
                  if (formattedDate.isNotEmpty)
                    _chip(Icons.calendar_today_rounded, formattedDate, Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
