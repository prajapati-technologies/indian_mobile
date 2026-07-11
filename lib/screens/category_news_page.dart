import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/news_feed_card.dart';
import 'news_detail_page.dart';

class CategoryNewsPage extends StatefulWidget {
  const CategoryNewsPage({
    super.key,
    required this.api,
    required this.slug,
    required this.title,
  });

  final ApiService api;
  final String slug;
  final String title;

  @override
  State<CategoryNewsPage> createState() => _CategoryNewsPageState();
}

class _CategoryNewsPageState extends State<CategoryNewsPage> {
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<dynamic> _news = [];
  int _currentPage = 1;
  int _lastPage = 1;
  final ScrollController _scrollController = ScrollController();

  bool get _hasMore => _currentPage < _lastPage;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _currentPage = 1;
    });
    try {
      final n = await widget.api.getJson('/news/category/${widget.slug}?page=1');
      _handleResponse(n);
    } catch (e) {
      setState(() {
        _error = e is ApiConnectionException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  void _handleResponse(dynamic n) {
    final data = n as Map<String, dynamic>;
    setState(() {
      _news = (data['data'] as List<dynamic>?) ?? [];
      _currentPage = (data['current_page'] as int?) ?? 1;
      _lastPage = (data['last_page'] as int?) ?? 1;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = _currentPage + 1;
      final n = await widget.api.getJson('/news/category/${widget.slug}?page=$next');
      final data = n as Map<String, dynamic>;
      final newItems = (data['data'] as List<dynamic>?) ?? [];
      setState(() {
        _news.addAll(newItems);
        _currentPage = (data['current_page'] as int?) ?? next;
        _lastPage = (data['last_page'] as int?) ?? next;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
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
    if (_news.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(child: Text('No articles in this category.')),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _news.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderLight),
      itemBuilder: (context, index) {
        if (index == _news.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final item = _news[index] as Map<String, dynamic>;
        return NewsFeedCard(
          item: item,
          onTap: () {
            final slug = item['slug'] as String?;
            if (slug == null) return;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => NewsDetailPage(api: widget.api, slug: slug),
              ),
            );
          },
        );
      },
    );
  }
}
