import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'job_list_page.dart';

class JobHubPage extends StatefulWidget {
  const JobHubPage({super.key, required this.api});

  final ApiService api;

  @override
  State<JobHubPage> createState() => _JobHubPageState();
}

class _JobHubPageState extends State<JobHubPage> {
  List<dynamic> _latestJobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    try {
      final result = await widget.api.getJson('/job-posts/latest');
      final data = result as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _latestJobs = (data['data'] as List<dynamic>?) ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Jobs & Career'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _loadLatest,
        color: AppColors.brandOrange,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Banner
            _buildHeader(),
            const SizedBox(height: 20),

            // Category Grid
            const Text(
              'Browse by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildCategoryGrid(),
            const SizedBox(height: 24),

            // Latest Updates
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.brandOrange, size: 20),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Latest Updates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLatestSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2C5F), Color(0xFF1A4A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2C5F).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jobs & Career',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Latest Govt Jobs, Admit Cards,\nResults & Admissions',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _buildCategoryCard(
          icon: Icons.description_rounded,
          title: 'Latest Job',
          subtitle: 'Govt & Private',
          gradient: const [Color(0xFF0B2C5F), Color(0xFF1A4A8A)],
          type: 'job',
        ),
        _buildCategoryCard(
          icon: Icons.badge_rounded,
          title: 'Admit Card',
          subtitle: 'Download Now',
          gradient: const [Color(0xFF138808), Color(0xFF2E9D1E)],
          type: 'admit_card',
        ),
        _buildCategoryCard(
          icon: Icons.emoji_events_rounded,
          title: 'Result',
          subtitle: 'Check Results',
          gradient: const [Color(0xFFE65100), Color(0xFFFF9933)],
          type: 'result',
        ),
        _buildCategoryCard(
          icon: Icons.school_rounded,
          title: 'Admission',
          subtitle: 'Apply Now',
          gradient: const [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
          type: 'admission',
        ),
      ],
    );
  }

  Widget _buildLatestSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator(color: AppColors.brandNavy)),
      );
    }

    if (_latestJobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(Icons.post_add_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text('No posts available yet', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('New updates will appear here', style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 11)),
          ],
        ),
      );
    }

    return Column(
      children: _latestJobs.take(8).map((job) => _buildJobCard(job as Map<String, dynamic>)).toList(),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required String type,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobListPage(api: widget.api, type: type, title: title),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final title = job['title'] as String? ?? '';
    final org = job['organization_name'] as String? ?? '';
    final type = job['type'] as String? ?? 'job';
    final totalPosts = job['total_posts'] as int?;
    final isFeatured = job['is_featured'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobListPage(api: widget.api, type: type, title: _typeLabel(type)),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _typeGradient(type),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(type), color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (org.isNotEmpty) ...[
                            Icon(Icons.business_rounded, size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(org, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ),
                          ],
                          if (totalPosts != null) ...[
                            if (org.isNotEmpty) const SizedBox(width: 8),
                            Icon(Icons.people_rounded, size: 11, color: AppColors.indiaGreen),
                            const SizedBox(width: 3),
                            Text('$totalPosts', style: TextStyle(fontSize: 11, color: AppColors.indiaGreen, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (isFeatured) const Icon(Icons.star_rounded, color: AppColors.saffron, size: 16),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _typeGradient(type)[0].withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _typeLabel(type),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _typeGradient(type)[0]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'admit_card': return 'Admit Card';
      case 'result': return 'Result';
      case 'admission': return 'Admission';
      default: return 'Job';
    }
  }

  List<Color> _typeGradient(String type) {
    switch (type) {
      case 'admit_card': return const [Color(0xFF138808), Color(0xFF2E9D1E)];
      case 'result': return const [Color(0xFFE65100), Color(0xFFFF9933)];
      case 'admission': return const [Color(0xFF6A1B9A), Color(0xFF9C27B0)];
      default: return const [Color(0xFF0B2C5F), Color(0xFF1A4A8A)];
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'admit_card': return Icons.badge_rounded;
      case 'result': return Icons.emoji_events_rounded;
      case 'admission': return Icons.school_rounded;
      default: return Icons.description_rounded;
    }
  }
}
