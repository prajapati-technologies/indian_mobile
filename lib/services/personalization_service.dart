import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user's favorite categories for personalized feed.
class PersonalizationService {
  static const String _favCategoriesKey = 'fav_categories';

  /// Get user's favorite category slugs
  static Future<List<String>> getFavoriteCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_favCategoriesKey);
    if (json == null) return [];
    return (jsonDecode(json) as List<dynamic>).cast<String>();
  }

  /// Save user's favorite categories
  static Future<void> saveFavoriteCategories(List<String> slugs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favCategoriesKey, jsonEncode(slugs));
  }

  /// Check if user has set preferences
  static Future<bool> hasPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_favCategoriesKey);
  }

  /// Toggle a category
  static Future<List<String>> toggleCategory(String slug) async {
    final current = await getFavoriteCategories();
    if (current.contains(slug)) {
      current.remove(slug);
    } else {
      current.add(slug);
    }
    await saveFavoriteCategories(current);
    return current;
  }
}
