import 'dart:async';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/app_review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/optimized_image.dart';
import 'news_detail_page.dart';
import 'jobs/job_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.api});
  final ApiService api;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() { _results = []; _error = null; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query.trim());
    });
  }

  Future<void> _search(String query) async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.api.getJson('/news?search=$query&per_page=10'),
        widget.api.getJson('/job-posts?search=$query&per_page=5'),
      ]);

      final newsData = results[0] as Map<String, dynamic>;
      final jobsData = results[1] as Map<String, dynamic>;

      final combined = <dynamic>[];
      // Add news results with type marker
      for (final item in (newsData['data'] as List<dynamic>?) ?? []) {
        (item as Map<String, dynamic>)['_type'] = 'news';
        combined.add(item);
      }
      // Add job results with type marker
      for (final item in (jobsData['data'] as List<dynamic>?) ?? []) {
        (item as Map<String, dynamic>)['_type'] = 'job';
        combined.add(item);
      }

      setState(() { _results = combined; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search news, jobs, tools...',
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 20),
              onPressed: () {
                _controller.clear();
                setState(() { _results = []; });
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandOrange));
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error', style: TextStyle(color: AppColors.textMuted)));
    }
    if (_controller.text.trim().length < 2) {
      return _buildHints();
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No results for "${_controller.text}"', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildResultItem(_results[index] as Map<String, dynamic>),
    );
  }

  Widget _buildHints() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Try searching for:', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['UPSC', 'Railway', 'SSC', 'Bank Jobs', 'Technology', 'Cricket', 'EMI Calculator'].map((tag) {
              return ActionChip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  HapticService.lightTap();
                  _controller.text = tag;
                  _onSearchChanged(tag);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> item) {
    final type = item['_type'] as String? ?? 'news';
    final title = item['title'] as String? ?? '';
    final slug = item['slug'] as String? ?? '';
    final imageUrl = item['image_url'] as String?;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: OptimizedImage(
        imageUrl: imageUrl,
        width: 56,
        height: 56,
        borderRadius: 8,
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: type == 'job' ? AppColors.indiaGreen.withValues(alpha: 0.1) : AppColors.brandNavy.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            type == 'job' ? 'JOB' : 'NEWS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: type == 'job' ? AppColors.indiaGreen : AppColors.brandNavy,
            ),
          ),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
      onTap: () {
        HapticService.lightTap();
        if (type == 'job') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailPage(api: widget.api, slug: slug)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailPage(api: widget.api, slug: slug)));
        }
      },
    );
  }
}
