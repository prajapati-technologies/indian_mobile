import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class UserSocialProfilePage extends StatefulWidget {
  final ApiService api;
  final String token;
  final int userId;

  const UserSocialProfilePage({
    super.key,
    required this.api,
    required this.token,
    required this.userId,
  });

  @override
  State<UserSocialProfilePage> createState() => _UserSocialProfilePageState();
}

class _UserSocialProfilePageState extends State<UserSocialProfilePage> {
  bool _loading = true;
  Map<String, dynamic>? _user;
  bool _isFollowing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final j = await widget.api.getJson('/profile/${widget.userId}', token: widget.token);
      setState(() {
        _user = j['user'];
        _isFollowing = j['is_following'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final action = _isFollowing ? 'unfollow' : 'follow';
    try {
      final j = await widget.api.postJson('/users/${widget.userId}/$action', {}, token: widget.token);
      setState(() {
        _isFollowing = j['is_following'];
        if (_user != null) {
          _user!['followers_count'] = j['followers_count'];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

    final name = _user?['name'] ?? 'User';
    final xp = _user?['xp'] ?? 0;
    final level = _user?['level'] ?? 1;
    final followers = _user?['followers_count'] ?? 0;
    final following = _user?['following_count'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: Text(name)),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.brandNavy,
              child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statItem('Followers', '$followers'),
              const SizedBox(width: 24),
              _statItem('Following', '$following'),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing ? Colors.grey : AppColors.brandOrange,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: Text(_isFollowing ? 'Unfollow' : 'Follow', style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassContainer.clearGlass(
              height: 100,
              width: double.infinity,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _badgeIcon(Icons.military_tech, 'Level $level'),
                  _badgeIcon(Icons.bolt, '$xp XP'),
                  _badgeIcon(Icons.emoji_events, '0 Badges'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _badgeIcon(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.brandOrange, size: 30),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
