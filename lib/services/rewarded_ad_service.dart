import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

/// Manages rewarded video ads.
/// Usage: Show a rewarded ad before unlocking a premium feature.
/// Call `RewardedAdManager.show()` and check the returned boolean.
class RewardedAdManager {
  static RewardedAd? _rewardedAd;
  static bool _isLoaded = false;

  /// Pre-load a rewarded ad (call early, e.g., in initState)
  static void preload() {
    if (_isLoaded) return;
    AdService.loadRewardedAd((ad) {
      _rewardedAd = ad;
      _isLoaded = true;
    });
  }

  /// Show rewarded ad. Returns true if user watched full ad and earned reward.
  static Future<bool> show(BuildContext context) async {
    if (!_isLoaded || _rewardedAd == null) {
      // Ad not loaded — show loading, try to load quickly
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading ad... try again in a moment'), duration: Duration(seconds: 2)),
      );
      preload(); // Try loading for next time
      return false;
    }

    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isLoaded = false;
        preload(); // Pre-load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isLoaded = false;
        preload();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );

    return rewarded;
  }

  /// Check if ad is ready to show
  static bool get isReady => _isLoaded && _rewardedAd != null;
}
