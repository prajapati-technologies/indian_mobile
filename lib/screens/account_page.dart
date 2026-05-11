import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:glass_kit/glass_kit.dart';
import 'daily_reward_page.dart';
import 'edit_profile_page.dart';
import 'leaderboard_page.dart';
import 'login_page.dart';
import 'news_detail_page.dart';
import 'register_page.dart';
import 'spin_wheel_page.dart';
import 'earnings_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.api,
    required this.token,
    required this.onTokenChanged,
    this.onApiReload,
  });

  final ApiService api;
  final String? token;
  final void Function(String? token) onTokenChanged;

  /// Called after user saves a new API base URL (parent should recreate [ApiService]).
  final Future<void> Function()? onApiReload;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _loadingMe = false;
  Map<String, dynamic>? _payload;
  String? _meError;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  @override
  void didUpdateWidget(AccountPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      _loadMe();
    }
  }

  Future<void> _loadMe() async {
    final t = widget.token;
    if (t == null || t.isEmpty) {
      setState(() {
        _payload = null;
        _meError = null;
      });
      return;
    }
    setState(() {
      _loadingMe = true;
      _meError = null;
    });
    try {
      final j = await widget.api.getJson('/me', token: t) as Map<String, dynamic>;
      setState(() {
        _payload = j;
        _loadingMe = false;
      });
    } catch (e) {
      setState(() {
        _meError = e is ApiConnectionException ? e.message : e.toString();
        _loadingMe = false;
      });
    }
  }

  Future<void> _logout() async {
    final t = widget.token;
    if (t != null) {
      try {
        await widget.api.postJson('/auth/logout', {}, token: t);
      } catch (_) {}
    }
    widget.onTokenChanged(null);
  }

  Future<void> _claim() async {
    final t = widget.token;
    if (t == null) {
      return;
    }
    try {
      await widget.api.postJson('/rewards/daily', {}, token: t);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily reward claimed')),
      );
      await _loadMe();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_parseMsg(e.body))),
      );
    }
  }

  Future<void> _spin() async {
    final t = widget.token;
    if (t == null) {
      return;
    }
    try {
      final j = await widget.api.postJson('/rewards/spin', {}, token: t) as Map<String, dynamic>;
      if (!mounted) {
        return;
      }
      final ok = j['ok'] == true;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(j['message']?.toString() ?? 'Spin failed')),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.celebration, color: Theme.of(context).colorScheme.secondary, size: 40),
          title: const Text('Spin result'),
          content: Text(
            '${j['label']}\n+${j['coins']} coins\nBalance: ${j['coin_balance']}',
            style: const TextStyle(height: 1.35),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      await _loadMe();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_parseMsg(e.body))),
      );
    }
  }

  String _parseMsg(String body) {
    try {
      final m = json.decode(body) as Map<String, dynamic>;
      return m['message']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }

  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.token;

    if (t == null) {
      return Stack(
        children: [
          if (_showRegister)
            RegisterPage(
              api: widget.api,
              onSuccess: (tok) => widget.onTokenChanged(tok),
              onSwitchToLogin: () => setState(() => _showRegister = false),
            )
          else
            LoginPage(
              api: widget.api,
              onSuccess: (tok) => widget.onTokenChanged(tok),
              onSwitchToRegister: () => setState(() => _showRegister = true),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Text('My Account'),
      ),
      body: RefreshIndicator(
        color: AppColors.brandOrange,
        onRefresh: () async {
          if (t != null) {
            await _loadMe();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildSignedInPanel(context, t),
          ],
        ),
      ),
    );
  }


  Widget _buildSignedInPanel(BuildContext context, String t) {
    if (_loadingMe) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
      );
    }
    if (_meError != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Could not load profile',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandNavy,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _meError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadMe,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_payload == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _profileCard(context, _payload!),
        const SizedBox(height: 24),
        _linkTile(
          context,
          icon: Icons.person_outline,
          label: 'My Profile',
          onTap: () async {
            if (_payload == null) return;
            final didUpdate = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (ctx) => EditProfilePage(
                  api: widget.api,
                  token: t,
                  initialUser: _payload!['user'] ?? {},
                ),
              ),
            );
            if (didUpdate == true) {
              _loadMe();
            }
          },
        ),
        const SizedBox(height: 12),
        _linkTile(
          context,
          icon: Icons.account_balance_wallet_outlined,
          label: 'Earnings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EarningsPage(api: widget.api, token: t),
              ),
            ).then((_) => _loadMe());
          },
        ),
        const SizedBox(height: 12),
        _linkTile(
          context,
          icon: Icons.card_giftcard,
          label: 'Daily Rewards',
          onTap: () async {
            if (_payload == null) return;
            final resultCoins = await Navigator.of(context).push<int>(
              MaterialPageRoute(
                builder: (ctx) => DailyRewardPage(
                  api: widget.api,
                  token: t,
                  initialRewardsData: _payload!['rewards'] ?? {},
                  initialCoins: _payload!['user']?['coin_balance'] ?? 0,
                ),
              ),
            );
            if (resultCoins != null) _loadMe();
          },
        ),
        const SizedBox(height: 12),
        _linkTile(
          context,
          icon: Icons.casino_outlined,
          label: 'Daily Spin',
          onTap: () async {
            if (_payload == null) return;
            final resultCoins = await Navigator.of(context).push<int>(
              MaterialPageRoute(
                builder: (ctx) => SpinWheelPage(
                  api: widget.api,
                  token: t,
                  initialCoins: _payload!['user']?['coin_balance'] ?? 0,
                  initialRemainingSpins: _payload!['spin']?['remaining_spins'] ?? 0,
                  initialBonusSpins: _payload!['spin']?['bonus_spins'] ?? 0,
                ),
              ),
            );
            if (resultCoins != null) _loadMe();
          },
        ),
        const SizedBox(height: 12),
        _linkTile(
          context,
          icon: Icons.leaderboard_outlined,
          label: 'Leaderboard',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => LeaderboardPage(
                  api: widget.api,
                  token: t,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _linkTile(
          context,
          icon: Icons.support_agent_outlined,
          label: 'Support Tickets',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support Tickets coming soon!')),
            );
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, size: 20),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brandNavy,
            side: const BorderSide(color: AppColors.borderLight),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _profileCard(BuildContext context, Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    final rewards = j['rewards'] as Map<String, dynamic>? ?? {};
    final spin = j['spin'] as Map<String, dynamic>? ?? {};
    final name = user['name'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final coins = user['coin_balance'];
    final ref = user['referral_code'] as String?;
    final canClaim = rewards['can_claim_daily'] == true;
    final remaining = spin['remaining_spins'];

    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBE6F8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNavy.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brandNavy, AppColors.brandOrange],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandNavy.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.cardMutedBg,
                          foregroundColor: AppColors.brandNavy,
                          child: Text(
                            initial,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.brandNavy,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                            if (ref != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.cardMutedBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: SelectableText(
                                  'Referral: $ref',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brandNavy,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _statTile(
                          icon: Icons.star_outline,
                          label: 'Level',
                          value: '${user['level'] ?? 1}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statTile(
                          icon: Icons.bolt_outlined,
                          label: 'Total XP',
                          value: '${user['xp'] ?? 0}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // XP Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Level Progress', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                          Text('${user['xp'] % 100}/100 XP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandOrange)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (user['xp'] % 100) / 100.0,
                          backgroundColor: AppColors.cardMutedBg,
                          color: AppColors.brandOrange,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _statTile(
                          icon: Icons.monetization_on_outlined,
                          label: 'Coins',
                          value: '$coins',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statTile(
                          icon: Icons.casino_outlined,
                          label: 'Spins left',
                          value: '$remaining',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardMutedBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          canClaim ? Icons.notifications_active_outlined : Icons.check_circle_outline,
                          color: canClaim ? AppColors.brandOrange : AppColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            canClaim
                                ? 'Aaj daily reward claim kar sakte ho.'
                                : 'Aaj ka daily reward claim ho chuka hai.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  height: 1.35,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardMutedBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brandOrange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.brandNavy,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }



  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDBE6F8)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandNavy.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardMutedBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.brandNavy, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandNavy,
                        ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.brandOrange, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
