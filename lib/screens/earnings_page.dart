import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EarningsPage extends StatefulWidget {
  final ApiService api;
  final String token;

  const EarningsPage({super.key, required this.api, required this.token});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  bool _loading = true;
  String? _error;
  
  Map<String, dynamic>? _user;
  List<dynamic> _transactions = [];
  List<dynamic> _withdrawals = [];
  
  final _withdrawFormKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  String _payoutMethod = 'upi';
  bool _isWithdrawing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final res = await widget.api.getJson('/me', token: widget.token);
      final data = res as Map<String, dynamic>;
      
      setState(() {
        _user = data['user'];
        _transactions = data['transactions'] ?? [];
        _withdrawals = data['withdrawals'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submitWithdrawal() async {
    if (!_withdrawFormKey.currentState!.validate()) return;

    setState(() => _isWithdrawing = true);

    try {
      final res = await widget.api.postJson(
        '/withdrawals',
        {
          'coins': int.parse(_amountCtrl.text.trim()),
          'payout_method': _payoutMethod,
        },
        token: widget.token,
      );
      
      final data = res as Map<String, dynamic>;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Withdrawal requested'), backgroundColor: Colors.green),
        );
        _amountCtrl.clear();
        _loadData(); // Reload to get updated balance and history
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiConnectionException ? e.message : e.toString()),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isWithdrawing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandNavy),
        title: const Text('Earnings & Payouts', style: TextStyle(color: AppColors.brandNavy, fontWeight: FontWeight.bold)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.brandNavy))
        : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            : DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    _buildOverviewCard(),
                    const TabBar(
                      labelColor: AppColors.brandOrange,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppColors.brandOrange,
                      tabs: [
                        Tab(text: 'History'),
                        Tab(text: 'Withdrawals'),
                        Tab(text: 'Request'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildTransactionsTab(),
                          _buildWithdrawalsTab(),
                          _buildWithdrawRequestTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildOverviewCard() {
    final balance = _user?['coin_balance'] ?? 0;
    final total = _user?['total_coins_earned'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNavy.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              const Text('Current Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.brandOrange, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '$balance',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 60, color: Colors.white24),
          Column(
            children: [
              const Text('Total Earned', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '$total',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final t = _transactions[index];
        final coins = t['coins'] ?? 0;
        final isPositive = coins >= 0;
        final dateStr = t['created_at'] != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(t['created_at']).toLocal()) : '';
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isPositive ? Colors.green.shade50 : Colors.red.shade50,
            child: Icon(
              isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          title: Text(t['meta'] ?? t['type'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(dateStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          trailing: Text(
            '${isPositive ? '+' : ''}$coins',
            style: TextStyle(
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWithdrawalsTab() {
    if (_withdrawals.isEmpty) {
      return const Center(child: Text('No withdrawals yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _withdrawals.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final w = _withdrawals[index];
        final coins = w['coins'] ?? 0;
        final status = (w['status'] ?? 'pending').toString().toLowerCase();
        final method = (w['payout_method'] ?? 'bank').toString().toUpperCase();
        final dateStr = w['created_at'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(w['created_at']).toLocal()) : '';
        
        Color statusColor;
        IconData statusIcon;
        if (status == 'approved' || status == 'completed') {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (status == 'rejected' || status == 'failed') {
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
        } else {
          statusColor = Colors.orange;
          statusIcon = Icons.access_time_filled;
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Icon(statusIcon, color: statusColor),
          ),
          title: Text('Withdrawal via $method', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(dateStr, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$coins Coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWithdrawRequestTab() {
    return Form(
      key: _withdrawFormKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Request a Payout',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandNavy),
          ),
          const SizedBox(height: 8),
          const Text(
            'Minimum withdrawal amount is 1000 coins. Please ensure your profile contains accurate payment details.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Coins to Withdraw',
              prefixIcon: const Icon(Icons.monetization_on, color: AppColors.brandOrange),
              filled: true,
              fillColor: AppColors.cardMutedBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.brandOrange, width: 2),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter amount';
              final val = int.tryParse(v);
              if (val == null || val < 1000) return 'Minimum 1000 coins required';
              if (val > (_user?['coin_balance'] ?? 0)) return 'Insufficient balance';
              return null;
            },
          ),
          const SizedBox(height: 24),
          const Text('Payout Method', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandNavy)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardMutedBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _payoutMethod,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'upi', child: Text('UPI Transfer')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _payoutMethod = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandOrange.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: _isWithdrawing ? null : _submitWithdrawal,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isWithdrawing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
