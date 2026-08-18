import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/app_review_service.dart';
import '../theme/app_theme.dart';
import 'daily_reward_page.dart';
import 'edit_profile_page.dart';
import 'leaderboard_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'spin_wheel_page.dart';
import 'earnings_page.dart';
import 'support_page.dart';

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
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _confirmDeleteAccount(String token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Delete Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'This will permanently delete your account and all associated data including coins, rewards, and saved progress.\n\nThis action cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.api.deleteJson('/me/delete', token: token);
      widget.onTokenChanged(null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${e.toString()}')),
        );
      }
    }
  }

  // ignore: unused_element
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

  // ignore: unused_element
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
              onSuccess: (tok) {
                widget.onTokenChanged(tok);
                if (mounted) Navigator.of(context).pop();
              },
              onSwitchToLogin: () => setState(() => _showRegister = false),
            )
          else
            LoginPage(
              api: widget.api,
              onSuccess: (tok) {
                widget.onTokenChanged(tok);
                if (mounted) Navigator.of(context).pop();
              },
              onSwitchToRegister: () => setState(() => _showRegister = true),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0F2C59)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Text('My Account'),
      ),
      body: RefreshIndicator(
        color: AppColors.brandOrange,
        onRefresh: () async {
          await _loadMe();
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
        const SizedBox(height: 20),
        // 2x2 Grid Menu
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            _gridTile(
              icon: Icons.person_rounded,
              label: 'My Profile',
              color: const Color(0xFF0B2C5F),
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
                if (didUpdate == true) _loadMe();
              },
            ),
            _gridTile(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Earnings',
              color: const Color(0xFF138808),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EarningsPage(api: widget.api, token: t),
                )).then((_) => _loadMe());
              },
            ),
            _gridTile(
              icon: Icons.card_giftcard_rounded,
              label: 'Daily Rewards',
              color: const Color(0xFFE65100),
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
            _gridTile(
              icon: Icons.casino_rounded,
              label: 'Daily Spin',
              color: const Color(0xFF6A1B9A),
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
            _gridTile(
              icon: Icons.leaderboard_rounded,
              label: 'Leaderboard',
              color: const Color(0xFFE91E63),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (context) => LeaderboardPage(api: widget.api, token: t)),
                );
              },
            ),
            _gridTile(
              icon: Icons.support_agent_rounded,
              label: 'Support',
              color: const Color(0xFF00838F),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SupportPage()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade600,
            side: BorderSide(color: Colors.red.shade200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        // Account Deletion (Apple requirement)
        TextButton(
          onPressed: () => _confirmDeleteAccount(t),
          child: Text(
            'Delete My Account',
            style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.w500),
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

    return Column(
      children: [
        // Premium Profile Header with Gradient
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B2C5F), Color(0xFF1A4A8A), Color(0xFF2563AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B2C5F).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        child: Text(initial, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(email, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                          if (ref != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.share_rounded, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                                  const SizedBox(width: 6),
                                  SelectableText(ref, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats Row
                Row(
                  children: [
                    _miniStat(Icons.monetization_on_rounded, '$coins', 'Coins', const Color(0xFFFFD700)),
                    _miniStat(Icons.bolt_rounded, '${user['xp'] ?? 0}', 'XP', AppColors.brandOrange),
                    _miniStat(Icons.star_rounded, 'Lv ${user['level'] ?? 1}', 'Level', const Color(0xFF4FC3F7)),
                    _miniStat(Icons.casino_rounded, '$remaining', 'Spins', const Color(0xFF81C784)),
                  ],
                ),
                const SizedBox(height: 16),
                // XP Progress
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Level Progress', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
                        Text('${(user['xp'] ?? 0) % 100}/100 XP', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: ((user['xp'] ?? 0) % 100) / 100.0,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: AppColors.brandOrange,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Daily reward banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: canClaim ? const Color(0xFFFFF8E1) : AppColors.pageBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: canClaim ? AppColors.brandOrange.withValues(alpha: 0.3) : AppColors.borderLight),
          ),
          child: Row(
            children: [
              Icon(
                canClaim ? Icons.card_giftcard_rounded : Icons.check_circle_rounded,
                color: canClaim ? AppColors.brandOrange : AppColors.indiaGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  canClaim ? 'Daily reward available! Claim now →' : 'Daily reward claimed ✓',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: canClaim ? AppColors.brandOrange : AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }



  Widget _gridTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticService.lightTap();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
