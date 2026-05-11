import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DailyRewardPage extends StatefulWidget {
  final ApiService api;
  final String token;
  final Map<String, dynamic> initialRewardsData;
  final int initialCoins;

  const DailyRewardPage({
    super.key,
    required this.api,
    required this.token,
    required this.initialRewardsData,
    required this.initialCoins,
  });

  @override
  State<DailyRewardPage> createState() => _DailyRewardPageState();
}

class _DailyRewardPageState extends State<DailyRewardPage> {
  late int _coins;
  late int _rewardDayCount;
  late bool _canClaimDaily;
  late int _nextStreakDay;
  bool _isLoading = false;

  final Map<int, int> _rewardConfig = {
    1: 50,
    2: 100,
    3: 150,
    4: 200,
    5: 300,
    6: 400,
    7: 500,
  };

  @override
  void initState() {
    super.initState();
    _coins = widget.initialCoins;
    _canClaimDaily = widget.initialRewardsData['can_claim_daily'] == true;
    _rewardDayCount = widget.initialRewardsData['reward_day_count'] ?? 0;
    _nextStreakDay = widget.initialRewardsData['next_streak_day'] ?? 1;
  }

  Future<void> _claimReward() async {
    if (!_canClaimDaily || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await widget.api.postJson(
        '/rewards/daily',
        {},
        token: widget.token,
      );
      final data = res as Map<String, dynamic>;

      if (data['ok'] == true) {
        setState(() {
          _coins = data['coin_balance'] ?? _coins;
          _rewardDayCount = data['reward_day_count'] ?? _rewardDayCount;
          _canClaimDaily = false;
          _nextStreakDay = _rewardDayCount == 7 ? 1 : _rewardDayCount + 1;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Reward claimed successfully!'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return updated coins on pop
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _coins);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.brandNavy),
          title: const Text(
            'Daily Rewards',
            style: TextStyle(color: AppColors.brandNavy, fontWeight: FontWeight.w700),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.brandOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.brandOrange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_coins',
                        style: const TextStyle(
                          color: AppColors.brandOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text(
                '7-Day Login Streak',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Login daily to earn coins. Complete 7 days for a mega bonus of 700 coins!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Column(
                children: List.generate(7, (index) {
                  final day = index + 1;
                  return _buildTimelineDay(day);
                }),
              ),
              const SizedBox(height: 40),
              if (_canClaimDaily)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandOrange.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _claimReward,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.star, size: 24),
                    label: Text(
                      _isLoading ? 'Claiming...' : 'Claim Day $_nextStreakDay Reward',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'You have claimed today\'s reward!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineDay(int day) {
    bool isClaimed = day < _nextStreakDay;
    bool isToday = day == _nextStreakDay;
    bool isFuture = day > _nextStreakDay;

    // Ensure logic handles post-7-day claim properly
    if (_rewardDayCount == 7 && !_canClaimDaily) {
        isClaimed = true;
        isToday = false;
        isFuture = false;
    }

    Color dotColor = isClaimed
        ? Colors.green.shade500
        : isToday
            ? AppColors.brandOrange
            : Colors.grey.shade400;

    Color lineColor = isClaimed ? Colors.green.shade500 : Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline graphics
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 3,
                    color: day == 1 ? Colors.transparent : (isClaimed || isToday ? Colors.green.shade500 : Colors.grey.shade300),
                  ),
                ),
                Container(
                  width: isToday ? 20 : 14,
                  height: isToday ? 20 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: AppColors.brandOrange.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                    border: isFuture ? Border.all(color: Colors.grey.shade400, width: 2) : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 3,
                    color: day == 7 ? Colors.transparent : (isClaimed ? Colors.green.shade500 : Colors.grey.shade300),
                  ),
                ),
              ],
            ),
          ),
          // Day Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isToday
                      ? const LinearGradient(
                          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isToday ? null : (isClaimed ? Colors.green.shade50 : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday ? AppColors.brandNavy : (isClaimed ? Colors.green.shade200 : Colors.grey.shade300),
                    width: isToday ? 0 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isToday ? AppColors.brandNavy.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day $day',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isToday ? Colors.white : (isClaimed ? Colors.green.shade800 : AppColors.brandNavy),
                          ),
                        ),
                        if (day == 7) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.brandOrange : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+700 MEGA BONUS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isToday ? Colors.white : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '+${_rewardConfig[day]}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: isToday ? AppColors.brandOrange : (isClaimed ? Colors.green.shade700 : AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.monetization_on,
                          color: isToday ? AppColors.brandOrange : (isClaimed ? Colors.green.shade600 : Colors.grey.shade400),
                          size: 24,
                        ),
                        if (isClaimed) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
