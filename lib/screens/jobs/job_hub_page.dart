import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'job_list_page.dart';

class JobHubPage extends StatelessWidget {
  const JobHubPage({super.key, required this.api});

  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs & Results'),
        centerTitle: true,
        backgroundColor: AppColors.brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategoryCard(
            context,
            icon: Icons.work_rounded,
            title: 'Latest Job',
            subtitle: 'Government & Private Jobs',
            color: AppColors.brandNavy,
            type: 'job',
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            context,
            icon: Icons.badge_rounded,
            title: 'Admit Card',
            subtitle: 'Download Exam Admit Cards',
            color: const Color(0xFF138808),
            type: 'admit_card',
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            context,
            icon: Icons.poll_rounded,
            title: 'Result',
            subtitle: 'Check Exam Results & Cutoff',
            color: const Color(0xFFFF9933),
            type: 'result',
          ),
          const SizedBox(height: 12),
          _buildCategoryCard(
            context,
            icon: Icons.school_rounded,
            title: 'Admission',
            subtitle: 'University & School Admissions',
            color: const Color(0xFF6A1B9A),
            type: 'admission',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String type,
  }) {
    return Card(
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobListPage(
                api: api,
                type: type,
                title: title,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
