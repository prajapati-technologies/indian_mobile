import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'business_detail_page.dart';

class BusinessListPage extends StatefulWidget {
  final ApiService api;
  final Map<String, dynamic> category;
  final String? token;

  const BusinessListPage({super.key, required this.api, required this.category, this.token});

  @override
  State<BusinessListPage> createState() => _BusinessListPageState();
}

class _BusinessListPageState extends State<BusinessListPage> {
  bool _loading = true;
  List<dynamic> _businesses = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.getJson('/businesses?category_id=${widget.category['id']}');
      setState(() {
        _businesses = res['data'] as List<dynamic>;
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
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: Text(widget.category['name'])),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _businesses.isEmpty
              ? const Center(child: Text('No businesses found in this category.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _businesses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final biz = _businesses[index];
                    return InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailPage(api: widget.api, slug: biz['slug'], token: widget.token))),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.cardMutedBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.store, color: AppColors.brandNavy),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(biz['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('${biz['city']}, ${biz['state']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 16, color: Colors.amber),
                                      Text(' ${biz['rating_avg']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      if (biz['is_verified'] == true)
                                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
