import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages offline caching of API responses and bookmarks.
/// Uses SharedPreferences for lightweight persistent storage.
class OfflineCacheService {
  static const String _cachePrefix = 'cache_';
  static const String _bookmarksKey = 'bookmarks_v1';
  static const String _cacheTimestampPrefix = 'cache_ts_';
  static const Duration _defaultMaxAge = Duration(hours: 6);

  // ─── API Response Cache ───

  /// Save an API response to cache
  static Future<void> cacheResponse(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(data);
    await prefs.setString('$_cachePrefix$key', jsonStr);
    await prefs.setInt('$_cacheTimestampPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached response (returns null if expired or not found)
  static Future<dynamic> getCachedResponse(String key, {Duration? maxAge}) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_cachePrefix$key');
    if (jsonStr == null) return null;

    // Check if cache is expired
    final timestamp = prefs.getInt('$_cacheTimestampPrefix$key') ?? 0;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final age = maxAge ?? _defaultMaxAge;
    if (DateTime.now().difference(cachedAt) > age) {
      return null; // Expired
    }

    return json.decode(jsonStr);
  }

  /// Get cached response regardless of age (for offline fallback)
  static Future<dynamic> getCachedResponseForce(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_cachePrefix$key');
    if (jsonStr == null) return null;
    return json.decode(jsonStr);
  }

  // ─── Bookmarks / Save for Later ───

  /// Get all bookmarked articles
  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_bookmarksKey);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Add article to bookmarks
  static Future<bool> addBookmark(Map<String, dynamic> article) async {
    final bookmarks = await getBookmarks();
    final slug = article['slug'] as String? ?? '';
    // Don't add duplicates
    if (bookmarks.any((b) => b['slug'] == slug)) return false;

    // Add timestamp
    article['bookmarked_at'] = DateTime.now().toIso8601String();
    bookmarks.insert(0, article); // newest first

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bookmarksKey, json.encode(bookmarks));
    return true;
  }

  /// Remove article from bookmarks
  static Future<void> removeBookmark(String slug) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b['slug'] == slug);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bookmarksKey, json.encode(bookmarks));
  }

  /// Check if article is bookmarked
  static Future<bool> isBookmarked(String slug) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) => b['slug'] == slug);
  }

  /// Clear all cache (not bookmarks)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix) || k.startsWith(_cacheTimestampPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
