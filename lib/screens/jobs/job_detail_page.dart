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
    final title = _post?['title'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title.isNotEmpty ? title : 'Post Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandNavy))
          : _error != null
              ? _buildError()
              : _post == null
                  ? const Center(child: Text('Not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.brandOrange,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _buildSections(),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Failed to load', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSections() {
    final post = _post!;
    final dates = (post['dates'] as List<dynamic>?) ?? [];
    final vacancies = (post['vacancies'] as List<dynamic>?) ?? [];
    final links = (post['links'] as List<dynamic>?) ?? [];
    final faqs = (post['faqs'] as List<dynamic>?) ?? [];
    final selectionModes = (post['selection_modes'] as List<dynamic>?) ?? [];
    final zoneResults = (post['zone_results'] as List<dynamic>?) ?? [];

    return [
      // Title Card
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post['title'] ?? '',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.brandNavy, height: 1.3),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (post['organization_name'] != null)
                  _infoBadge(Icons.business_rounded, post['organization_name'], AppColors.brandNavy),
                if (post['total_posts'] != null)
                  _infoBadge(Icons.people_rounded, '${post['total_posts']} Posts', AppColors.indiaGreen),
                if (post['advt_no'] != null)
                  _infoBadge(Icons.tag_rounded, post['advt_no'], AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),

      // Short Information
      if (post['short_information'] != null && (post['short_information'] as String).isNotEmpty)
        _section('Short Information', Icons.info_outline_rounded, [
          Text(post['short_information'], style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textPrimary)),
        ]),

      // Important Dates
      if (dates.isNotEmpty)
        _section('Important Dates', Icons.calendar_month_rounded, [
          ...dates.map((d) => _dataRow(d['label'] ?? '', d['value'] ?? '')),
        ]),

      // Application Fee
      if (post['fee_general'] != null || post['fee_sc_st'] != null)
        _section('Application Fee', Icons.currency_rupee_rounded, [
          if (post['fee_general'] != null) _dataRow('General / OBC', post['fee_general']),
          if (post['fee_sc_st'] != null) _dataRow('SC / ST / PH', post['fee_sc_st']),
          if (post['fee_refund_general'] != null) _dataRow('Refund (General)', post['fee_refund_general']),
          if (post['fee_refund_sc_st'] != null) _dataRow('Refund (SC/ST)', post['fee_refund_sc_st']),
          if (post['fee_payment_mode'] != null) _dataRow('Payment Mode', post['fee_payment_mode']),
        ]),

      // Age Limit
      if (post['age_minimum'] != null || post['age_maximum'] != null)
        _section('Age Limit', Icons.person_rounded, [
          if (post['age_minimum'] != null) _dataRow('Minimum Age', post['age_minimum']),
          if (post['age_maximum'] != null) _dataRow('Maximum Age', post['age_maximum']),
          if (post['age_relaxation'] != null) _dataRow('Age Relaxation', post['age_relaxation']),
        ]),

      // Vacancy Details
      if (vacancies.isNotEmpty)
        _section('Vacancy Details', Icons.people_alt_rounded, [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Post Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandNavy))),
                      SizedBox(width: 50, child: Text('Posts', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandNavy))),
                    ],
                  ),
                ),
                ...vacancies.map((v) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderLight))),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(v['post_name'] ?? '', style: const TextStyle(fontSize: 12, height: 1.3))),
                      SizedBox(
                        width: 50,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.indiaGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text('${v['no_of_posts'] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.indiaGreen)),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ]),

      // Eligibility
      if (post['eligibility'] != null && (post['eligibility'] as String).isNotEmpty)
        _section('Eligibility', Icons.school_rounded, [
          Text(post['eligibility'], style: const TextStyle(fontSize: 13, height: 1.6)),
        ]),

      // Mode of Selection
      if (selectionModes.isNotEmpty)
        _section('Mode of Selection', Icons.format_list_numbered_rounded, [
          ...selectionModes.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandNavy))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value['step_name'] ?? '', style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
        ]),

      // Zone Results
      if (zoneResults.isNotEmpty)
        _section('Zone Wise Result / Cutoff', Icons.map_rounded, [
          ...zoneResults.map((z) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(z['zone_name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                if (z['result_link'] != null && (z['result_link'] as String).isNotEmpty)
                  _actionChip('Result', z['result_link'], AppColors.brandNavy),
                const SizedBox(width: 6),
                if (z['cutoff_link'] != null && (z['cutoff_link'] as String).isNotEmpty)
                  _actionChip('Cutoff', z['cutoff_link'], AppColors.indiaGreen),
              ],
            ),
          )),
        ]),

      // How to Apply
      if (post['how_to_apply'] != null && (post['how_to_apply'] as String).isNotEmpty)
        _section('How to Apply', Icons.edit_note_rounded, [
          Text(post['how_to_apply'], style: const TextStyle(fontSize: 13, height: 1.6)),
        ]),

      // Important Links
      if (links.isNotEmpty)
        _section('Important Links', Icons.link_rounded, [
          ...links.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.brandNavy.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openUrl(l['url'] ?? ''),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.brandNavy),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandNavy)),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ]),

      // FAQ
      if (faqs.isNotEmpty)
        _section('Frequently Asked Questions', Icons.help_outline_rounded, [
          ...faqs.asMap().entries.map((e) => _FaqTile(index: e.key, question: e.value['question'] ?? '', answer: e.value['answer'] ?? '')),
        ]),

      const SizedBox(height: 20),
    ];
  }

  // ─── Helper Widgets ───

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.brandNavy),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          const Text(' :  ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3))),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionChip(String label, String url, Color color) {
    return InkWell(
      onTap: () => _openUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.index, required this.question, required this.answer});
  final int index;
  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _expanded ? AppColors.brandNavy.withValues(alpha: 0.2) : Colors.transparent),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Q${widget.index + 1}. ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
                    Expanded(child: Text(widget.question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.brandNavy,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(widget.answer, style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
