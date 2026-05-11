import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'category_news_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key, required this.api});

  final ApiService api;

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final j = await widget.api.getJson('/categories');
      setState(() {
        _items = (j['data'] as List<dynamic>?) ?? [];
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
      appBar: AppBar(title: const Text('Categories')),
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

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final row = _items[index] as Map<String, dynamic>;
        final name = row['name'] as String? ?? '';
        final slug = row['slug'] as String? ?? '';
        return ListTile(
          title: Text(name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => CategoryNewsPage(
                  api: widget.api,
                  slug: slug,
                  title: name,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
