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
  String? _error;
  List<dynamic> _news = [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final n = await widget.api.getJson('/news/category/${widget.slug}');
      setState(() {
        _news = (n['data'] as List<dynamic>?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e is ApiConnectionException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
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
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _news.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderLight),
      itemBuilder: (context, index) {
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
