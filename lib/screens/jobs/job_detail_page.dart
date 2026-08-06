import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key, required this.api, required this.slug});

  final ApiService api;
  final String slug;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  Map<String, dynamic>? _post;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.api.getJson('/job-posts/${widget.slug}');
      setState(() {
        _post = (result as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_post?['title'] ?? 'Details', maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandNavy))
          : _error != null
              ? Center(child: Text(_error!))
              : _post == null
                  ? const Center(child: Text('Not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: _buildContent(),
                      ),
                    ),
    );
  }

  Widget _buildContent() {
    final post = _post!;
    final dates = (post['dates'] as List<dynamic>?) ?? [];
    final vacancies = (post['vacancies'] as List<dynamic>?) ?? [];
    final links = (post['links'] as List<dynamic>?) ?? [];
    final faqs = (post['faqs'] as List<dynamic>?) ?? [];
    final selectionModes = (post['selection_modes'] as List<dynamic>?) ?? [];
    final zoneResults = (post['zone_results'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          post['title'] ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brandNavy),
        ),
        const SizedBox(height: 12),

        // Short Info
        if (post['short_information'] != null && (post['short_information'] as String).isNotEmpty) ...[
          _sectionCard('Short Information', Icons.info_rounded, [
            Text(post['short_information'], style: const TextStyle(fontSize: 13, height: 1.5)),
          ]),
          const SizedBox(height: 12),
        ],

        // Important Dates
        if (dates.isNotEmpty) ...[
          _sectionCard('Important Dates', Icons.calendar_month_rounded, [
            ...dates.map((d) => _tableRow(d['label'] ?? '', d['value'] ?? '')),
          ]),
          const SizedBox(height: 12),
        ],

        // Application Fee
        if (post['fee_general'] != null || post['fee_sc_st'] != null) ...[
          _sectionCard('Application Fee', Icons.currency_rupee_rounded, [
            if (post['fee_general'] != null) _tableRow('General / OBC', post['fee_general']),
            if (post['fee_sc_st'] != null) _tableRow('SC / ST / PH', post['fee_sc_st']),
            if (post['fee_refund_general'] != null) _tableRow('Refund (General)', post['fee_refund_general']),
            if (post['fee_refund_sc_st'] != null) _tableRow('Refund (SC/ST)', post['fee_refund_sc_st']),
            if (post['fee_payment_mode'] != null) _tableRow('Payment Mode', post['fee_payment_mode']),
          ]),
          const SizedBox(height: 12),
        ],

        // Age Limit
        if (post['age_minimum'] != null || post['age_maximum'] != null) ...[
          _sectionCard('Age Limit', Icons.person_rounded, [
            if (post['age_minimum'] != null) _tableRow('Minimum Age', post['age_minimum']),
            if (post['age_maximum'] != null) _tableRow('Maximum Age', post['age_maximum']),
            if (post['age_relaxation'] != null) _tableRow('Relaxation', post['age_relaxation']),
          ]),
          const SizedBox(height: 12),
        ],

        // Vacancy Details
        if (vacancies.isNotEmpty) ...[
          _sectionCard('Vacancy Details', Icons.people_rounded, [
            ...vacancies.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(v['post_name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.brandNavy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('${v['no_of_posts'] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
                  ),
                ],
              ),
            )),
          ]),
          const SizedBox(height: 12),
        ],

        // Eligibility
        if (post['eligibility'] != null && (post['eligibility'] as String).isNotEmpty) ...[
          _sectionCard('Eligibility', Icons.school_rounded, [
            Text(post['eligibility'], style: const TextStyle(fontSize: 13, height: 1.5)),
          ]),
          const SizedBox(height: 12),
        ],

        // Selection Mode
        if (selectionModes.isNotEmpty) ...[
          _sectionCard('Mode of Selection', Icons.format_list_numbered_rounded, [
            ...selectionModes.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  CircleAvatar(radius: 12, backgroundColor: AppColors.brandNavy.withValues(alpha: 0.1), child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandNavy))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.value['step_name'] ?? '', style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ]),
          const SizedBox(height: 12),
        ],

        // Zone Results
        if (zoneResults.isNotEmpty) ...[
          _sectionCard('Zone Wise Result/Cutoff', Icons.map_rounded, [
            ...zoneResults.map((z) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(z['zone_name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  if (z['result_link'] != null && (z['result_link'] as String).isNotEmpty)
                    _linkButton('Result', z['result_link']),
                  const SizedBox(width: 6),
                  if (z['cutoff_link'] != null && (z['cutoff_link'] as String).isNotEmpty)
                    _linkButton('Cutoff', z['cutoff_link']),
                ],
              ),
            )),
          ]),
          const SizedBox(height: 12),
        ],

        // How to Apply
        if (post['how_to_apply'] != null && (post['how_to_apply'] as String).isNotEmpty) ...[
          _sectionCard('How to Apply', Icons.edit_note_rounded, [
            Text(post['how_to_apply'], style: const TextStyle(fontSize: 13, height: 1.5)),
          ]),
          const SizedBox(height: 12),
        ],

        // Important Links
        if (links.isNotEmpty) ...[
          _sectionCard('Important Links', Icons.link_rounded, [
            ...links.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _openUrl(l['url'] ?? ''),
                child: Row(
                  children: [
                    const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.brandNavy),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l['title'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.brandNavy, fontWeight: FontWeight.w600, decoration: TextDecoration.underline))),
                  ],
                ),
              ),
            )),
          ]),
          const SizedBox(height: 12),
        ],

        // FAQ
        if (faqs.isNotEmpty) ...[
          _sectionCard('FAQ', Icons.help_outline_rounded, [
            ...faqs.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q: ${f['question'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('A: ${f['answer'] ?? ''}', style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
                ],
              ),
            )),
          ]),
        ],
      ],
    );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.brandNavy),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _tableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          const Text(' : ', style: TextStyle(fontSize: 12)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
        ],
      ),
    );
  }

  Widget _linkButton(String label, String url) {
    return InkWell(
      onTap: () => _openUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.brandNavy.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brandNavy)),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
