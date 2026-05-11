import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'business_list_page.dart';
import 'add_business_page.dart';

class BusinessDirectoryPage extends StatefulWidget {
  final ApiService api;
  final String? token;
  final VoidCallback onRequireLogin;

  const BusinessDirectoryPage({super.key, required this.api, this.token, required this.onRequireLogin});

  @override
  State<BusinessDirectoryPage> createState() => _BusinessDirectoryPageState();
}

class _BusinessDirectoryPageState extends State<BusinessDirectoryPage> {
  bool _loading = true;
  List<dynamic> _categories = [];
  List<dynamic> _featured = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cats = await widget.api.getJson('/businesses/categories');
      final feat = await widget.api.getJson('/businesses?featured=1');
      setState(() {
        _categories = cats as List<dynamic>;
        _featured = feat['data'] as List<dynamic>;
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
      appBar: AppBar(
        title: const Text('Business Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            onPressed: () {
              if (widget.token == null) {
                widget.onRequireLogin();
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddBusinessPage(api: widget.api, token: widget.token!)));
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Categories'),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(),
                  const SizedBox(height: 24),
                  if (_featured.isNotEmpty) ...[
                    _buildSectionTitle('Featured Businesses'),
                    const SizedBox(height: 16),
                    _buildFeaturedList(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return GlassContainer.clearGlass(
      height: 50,
      width: double.infinity,
      borderRadius: BorderRadius.circular(12),
      child: const Row(
        children: [
          SizedBox(width: 12),
          Icon(Icons.search, color: AppColors.brandNavy),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search businesses, services...',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandNavy),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final name = cat['name'] as String? ?? '';
        final iconData = _getIconForCategory(name);
        final iconColor = _getColorForCategory(name);

        return InkWell(
          onTap: () {
            if (widget.token == null) {
              widget.onRequireLogin();
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessListPage(api: widget.api, category: cat, token: widget.token)));
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: iconColor.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Icon(iconData, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featured.length,
        itemBuilder: (context, index) {
          final biz = _featured[index];
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.cardMutedBg,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Center(child: Icon(Icons.storefront, size: 40, color: AppColors.brandNavy)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(biz['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(' ${biz['rating_avg']} ', style: const TextStyle(fontSize: 12)),
                          Text('(${biz['city']})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'plumber': return Icons.plumbing;
      case 'electrician': return Icons.electrical_services;
      case 'carpenter': return Icons.carpenter;
      case 'mechanic': return Icons.car_repair;
      case 'real estate': return Icons.real_estate_agent;
      case 'education': return Icons.school;
      case 'health & hospital': return Icons.local_hospital;
      case 'hotels & restaurants': return Icons.restaurant;
      case 'shopping': return Icons.shopping_bag;
      case 'travel & transport': return Icons.flight_takeoff;
      case 'it services': return Icons.computer;
      case 'home decor': return Icons.chair;
      default: return Icons.business_center;
    }
  }

  Color _getColorForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'plumber': return Colors.blue;
      case 'electrician': return Colors.amber.shade700;
      case 'carpenter': return Colors.brown;
      case 'mechanic': return Colors.grey.shade800;
      case 'real estate': return Colors.indigo;
      case 'education': return Colors.green;
      case 'health & hospital': return Colors.red;
      case 'hotels & restaurants': return Colors.deepOrange;
      case 'shopping': return Colors.pink;
      case 'travel & transport': return Colors.lightBlue;
      case 'it services': return Colors.teal;
      case 'home decor': return Colors.purple;
      default: return AppColors.brandOrange;
    }
  }
}
