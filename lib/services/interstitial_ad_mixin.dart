import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

/// Mixin that loads an interstitial ad and shows it when user leaves the page.
/// Usage: Add `with InterstitialAdMixin` to your State class,
/// call `loadInterstitial()` in initState and `showInterstitialAndPop()` instead of Navigator.pop.
mixin InterstitialAdMixin<T extends StatefulWidget> on State<T> {
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoaded = false;
  static int _adCounter = 0; // Show ad every 2nd time (not every time)

  void loadInterstitial() {
    AdService.loadInterstitialAd((ad) {
      _interstitialAd = ad;
      _isInterstitialLoaded = true;
    });
  }

  void disposeInterstitial() {
    _interstitialAd?.dispose();
  }

  /// Call this when user presses back. Shows ad every 2nd tool usage.
  void showInterstitialAndPop() {
    _adCounter++;
    if (_isInterstitialLoaded && _interstitialAd != null && _adCounter % 2 == 0) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          if (mounted) Navigator.of(context).pop();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          if (mounted) Navigator.of(context).pop();
        },
      );
      _interstitialAd!.show();
    } else {
      Navigator.of(context).pop();
    }
  }
}
