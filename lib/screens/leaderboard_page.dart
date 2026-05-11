import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'user_social_profile_page.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key, required this.api, required this.token});

  final ApiService api;
  final String token;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _earners = [];
  List<dynamic> _referrers = [];
  List<dynamic> _xpList = [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final j = await widget.api.getJson('/leaderboard', token: widget.token);
      setState(() {
        _earners = (j['top_earners'] as List<dynamic>?) ?? [];
        _referrers = (j['top_referrers'] as List<dynamic>?) ?? [];
        _xpList = (j['top_xp'] as List<dynamic>?) ?? [];
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
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandNavy),
        title: const Text('Leaderboard', style: TextStyle(color: AppColors.brandNavy, fontWeight: FontWeight.bold)),
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
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.brandNavy,
                          indicator: BoxDecoration(
                            color: AppColors.brandOrange,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          tabs: [
                            Tab(text: 'Earners'),
                            Tab(text: 'Referrers'),
                            Tab(text: 'Global XP'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildLeaderboardList(_earners, type: 'coins'),
                            _buildLeaderboardList(_referrers, type: 'refs'),
                            _buildLeaderboardList(_xpList, type: 'xp'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLeaderboardList(List<dynamic> users, {required String type}) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brandOrange,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final u = users[index] as Map<String, dynamic>;
          final int rank = index + 1;
          
          Color cardColor = Colors.white;
          Color rankColor = AppColors.brandNavy;
          IconData? rankIcon;

          if (rank == 1) {
            cardColor = Colors.amber.shade50;
            rankColor = Colors.amber.shade700;
            rankIcon = Icons.workspace_premium;
          } else if (rank == 2) {
            cardColor = Colors.blueGrey.shade50;
            rankColor = Colors.blueGrey.shade600;
            rankIcon = Icons.workspace_premium;
          } else if (rank == 3) {
            cardColor = Colors.orange.shade50;
            rankColor = Colors.brown.shade600;
            rankIcon = Icons.workspace_premium;
          }

          String valueText = '';
          String subLabel = '';
          
          if (type == 'coins') {
            valueText = '${u['total_coins_earned'] ?? 0} Coins';
            subLabel = 'Earned';
          } else if (type == 'refs') {
            valueText = '${u['referred_users_count'] ?? 0} Refs';
            subLabel = 'Referred';
          } else {
            valueText = '${u['xp'] ?? 0} XP';
            subLabel = 'Level ${u['level'] ?? 1}';
          }

          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: rank <= 3 ? Border.all(color: rankColor.withValues(alpha: 0.3), width: 1.5) : Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => UserSocialProfilePage(
                      api: widget.api,
                      token: widget.token,
                      userId: u['id'],
                    ),
                  ),
                );
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rank <= 3 ? rankColor : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: rankIcon != null
                      ? Icon(rankIcon, color: Colors.white, size: 20)
                      : Text(
                          '$rank',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              title: Text(
                u['name'] as String? ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandNavy),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    valueText,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: rank <= 3 ? rankColor : AppColors.brandOrange,
                    ),
                  ),
                  Text(subLabel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
