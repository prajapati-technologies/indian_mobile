import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class BusinessDetailPage extends StatefulWidget {
  final ApiService api;
  final String slug;
  final String? token;

  const BusinessDetailPage({super.key, required this.api, required this.slug, this.token});

  @override
  State<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends State<BusinessDetailPage> {
  bool _loading = true;
  Map<String, dynamic>? _biz;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.getJson('/businesses/${widget.slug}');
      setState(() {
        _biz = res as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _launchCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _launchWhatsApp(String phone) async {
    final url = Uri.parse('https://wa.me/91$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _shareListing() async {
    final text = 'Check out ${_biz!['name']} on India Info Super App!\nDownload now and use my referral code to get bonus coins: https://indiainfo.app';
    
    final result = await Share.share(text);
    
    if (result.status == ShareResultStatus.success && widget.token != null) {
      try {
        final res = await widget.api.postJson('/gamification/share', {
          'content_type': 'business',
          'content_id': widget.slug,
        }, token: widget.token);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? 'Thanks for sharing!'),
            backgroundColor: Colors.green,
          ));
        }
      } catch (_) {
        // Ignore API errors if sharing tracking fails
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareListing,
        icon: const Icon(Icons.share),
        label: const Text('Share & Earn'),
        backgroundColor: AppColors.brandOrange,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.brandNavy,
                child: const Center(child: Icon(Icons.store, size: 80, color: Colors.white)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_biz!['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      if (_biz!['is_verified'] == true) const Icon(Icons.verified, color: Colors.blue),
                    ],
                  ),
                  if (_biz!['tagline'] != null) ...[
                    const SizedBox(height: 4),
                    Text(_biz!['tagline'], style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ],
                  const SizedBox(height: 8),
                  Text(_biz!['category']['name'], style: const TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _actionButton(Icons.call, 'Call', Colors.blue, () => _launchCall(_biz!['phone'])),
                      const SizedBox(width: 12),
                      _actionButton(Icons.chat, 'WhatsApp', Colors.green, () => _launchWhatsApp(_biz!['phone'])),
                      const SizedBox(width: 12),
                      _actionButton(Icons.language, 'Website', Colors.orange, () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_biz!['is_ai_processed'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.purple.shade200)),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 12, color: Colors.purple.shade400),
                              const SizedBox(width: 4),
                              Text('AI Optimized', style: TextStyle(fontSize: 10, color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_biz!['ai_description'] ?? _biz!['description'] ?? 'No description provided.', style: const TextStyle(color: Colors.black87, height: 1.5)),
                  
                  if (_biz!['seo_keywords'] != null && (_biz!['seo_keywords'] as List).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_biz!['seo_keywords'] as List).map((k) => Chip(
                        label: Text(k.toString(), style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.cardMutedBg,
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text('Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${_biz!['address']}, ${_biz!['city']}, ${_biz!['state']} - ${_biz!['pincode']}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
