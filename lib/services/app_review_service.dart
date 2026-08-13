import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages in-app review prompts.
/// Shows review dialog after user has:
/// - Used app 3+ times (sessions)
/// - Been using for 3+ days since install
/// - Not been asked in last 30 days
class AppReviewService {
  static const String _sessionCountKey = 'review_session_count';
  static const String _firstOpenKey = 'review_first_open';
  static const String _lastPromptKey = 'review_last_prompt';

  /// Call this on every app open (in main or app_shell initState)
  static Future<void> trackSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Track first open date
    if (!prefs.containsKey(_firstOpenKey)) {
      await prefs.setInt(_firstOpenKey, DateTime.now().millisecondsSinceEpoch);
    }

    // Increment session count
    final count = (prefs.getInt(_sessionCountKey) ?? 0) + 1;
    await prefs.setInt(_sessionCountKey, count);

    // Check if we should show review
    if (_shouldPrompt(prefs, count)) {
      await _showReview(prefs);
    }
  }

  static bool _shouldPrompt(SharedPreferences prefs, int sessionCount) {
    // Need at least 3 sessions
    if (sessionCount < 3) return false;

    // Need at least 3 days since first open
    final firstOpen = prefs.getInt(_firstOpenKey) ?? 0;
    final daysSinceInstall = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(firstOpen),
    ).inDays;
    if (daysSinceInstall < 3) return false;

    // Don't ask again within 30 days
    final lastPrompt = prefs.getInt(_lastPromptKey) ?? 0;
    if (lastPrompt > 0) {
      final daysSinceLastPrompt = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastPrompt),
      ).inDays;
      if (daysSinceLastPrompt < 30) return false;
    }

    // Only prompt on sessions 3, 10, 25, 50... (not every time)
    return sessionCount == 3 || sessionCount == 10 || sessionCount == 25 || sessionCount % 50 == 0;
  }

  static Future<void> _showReview(SharedPreferences prefs) async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      await prefs.setInt(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);
    }
  }
}

/// Haptic feedback utilities for premium feel
class HapticService {
  /// Light tap feedback (buttons, selections)
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact (important actions like bookmark, submit)
  static void mediumTap() {
    HapticFeedback.mediumImpact();
  }

  /// Selection changed (tab switch, category select)
  static void selectionTap() {
    HapticFeedback.selectionClick();
  }

  /// Success (form submitted, saved)
  static void success() {
    HapticFeedback.heavyImpact();
  }
}
