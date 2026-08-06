import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/place_model.dart';
import '../services/city_explorer_api_service.dart';
import '../services/location_service.dart';
import '../services/overpass_service.dart';

class LocalExplorerProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final OverpassService _overpassService = OverpassService();
  late final CityExplorerApiService _apiService;

  LocalExplorerProvider() {
    final webOrigin = AppConfig.webOrigin;
    _apiService = CityExplorerApiService('$webOrigin/api/v1/city-explorer');
  }

  /// Allow injecting a custom API base (e.g. from runtime URL override).
  LocalExplorerProvider.withBaseUrl(String apiBaseUrl) {
    final webOrigin = AppConfig.webOriginFromApiBase(apiBaseUrl);
    _apiService = CityExplorerApiService('$webOrigin/api/v1/city-explorer');
  }

  // ─── State ─────────────────────────────────────────────────────────────────

  Position? currentPosition;
  CityInfo? currentCity;
  bool isLoading = false;
  bool isLocationLoading = false;
  List<PlaceModel> nearbyPlaces = [];
  List<PlaceModel> famousPlaces = [];
  List<PlaceModel> searchResults = [];
  String? selectedCategory;
  List<String> recentSearches = [];
  List<PlaceModel> favoritePlaces = [];
  String? errorMessage;
  PlaceModel? selectedPlace;
  bool isSearching = false;

  /// City detail from backend (includes categories).
  Map<String, dynamic>? cityDetail;

  /// All categories for current city.
  List<Map<String, dynamic>> categories = [];

  /// All available cities (for city picker).
  List<Map<String, dynamic>> availableCities = [];

  /// Whether the detected city was found on the backend.
  bool cityFoundOnBackend = true;

  /// Current city slug used for API calls.
  String? _currentCitySlug;
  String? get currentCitySlug => _currentCitySlug;

  // ─── Computed ──────────────────────────────────────────────────────────────

  String get currentLocationDisplay {
    if (currentCity != null) {
      return '${currentCity!.city}, ${currentCity!.state}';
    }
    if (!cityFoundOnBackend && availableCities.isNotEmpty) {
      return 'Select a City';
    }
    return 'Detecting...';
  }

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> initializeLocation() async {
    isLocationLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Get GPS position
      currentPosition = await _locationService.getCurrentPosition();

      // Step 2: Reverse geocode to get city name
      currentCity = await _locationService.getCityFromLatLng(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );

      // Step 3: Convert city name to slug and fetch from backend
      _currentCitySlug = _toSlug(currentCity!.city);

      try {
        await _loadCityFromBackend(_currentCitySlug!);
        cityFoundOnBackend = true;
      } on CityExplorerApiException catch (e) {
        if (e.isNotFound) {
          // City not found on backend – load city list for picker
          cityFoundOnBackend = false;
          await loadAvailableCities();
        } else {
          rethrow;
        }
      }

      // Step 4: Load local data
      await loadFavorites();
      await loadRecentSearches();
    } catch (e) {
      // Location failed (simulator or permission denied) — show city picker
      errorMessage = null;
      cityFoundOnBackend = false;
      await loadAvailableCities();
      await loadFavorites();
      await loadRecentSearches();
    }

    isLocationLoading = false;
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    currentPosition = null;
    currentCity = null;
    nearbyPlaces = [];
    famousPlaces = [];
    searchResults = [];
    selectedCategory = null;
    errorMessage = null;
    cityDetail = null;
    categories = [];
    cityFoundOnBackend = true;
    _currentCitySlug = null;
    notifyListeners();
    await initializeLocation();
  }

  // ─── City Management ───────────────────────────────────────────────────────

  /// Load city detail (categories) from backend.
  Future<void> _loadCityFromBackend(String slug) async {
    cityDetail = await _apiService.getCityDetail(slug);
    categories = ((cityDetail?['categories'] as List<dynamic>?) ?? [])
        .map((c) => c as Map<String, dynamic>)
        .toList();
    notifyListeners();
  }

  /// Switch to a different city (from picker).
  Future<void> selectCity(String slug, {String? cityName, String? stateName}) async {
    isLocationLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _currentCitySlug = slug;
      await _loadCityFromBackend(slug);
      cityFoundOnBackend = true;

      // Update currentCity display info if provided
      if (cityName != null) {
        currentCity = CityInfo(
          city: cityName,
          state: stateName ?? cityDetail?['state'] ?? '',
          lat: (cityDetail?['latitude'] as num?)?.toDouble() ?? 0,
          lng: (cityDetail?['longitude'] as num?)?.toDouble() ?? 0,
        );
      }

      // Clear old data
      nearbyPlaces = [];
      famousPlaces = [];
      searchResults = [];
      selectedCategory = null;
    } catch (e) {
      errorMessage = 'Failed to load city: $e';
    }

    isLocationLoading = false;
    notifyListeners();
  }

  /// Load all available cities for the city picker.
  Future<void> loadAvailableCities() async {
    try {
      final cities = await _apiService.getAllCities(countryId: 1);
      availableCities = cities
          .map((c) => c as Map<String, dynamic>)
          .toList();
      notifyListeners();
    } catch (e) {
      // Silently fail – picker will be empty
    }
  }

  // ─── Places by Category ────────────────────────────────────────────────────

  /// Load places for a category from the backend API.
  /// Load places for a category — tries backend first, falls back to Overpass (nearby GPS).
  Future<void> searchNearby(String category) async {
    isLoading = true;
    selectedCategory = category;
    errorMessage = null;
    notifyListeners();

    try {
      // Try backend API first (if city is known)
      if (_currentCitySlug != null) {
        final categorySlug = _toSlug(category);
        final response = await _apiService.getPlaces(_currentCitySlug!, categorySlug);
        final data = response['data'] as Map<String, dynamic>? ?? {};

        final places = <PlaceModel>[];

        final sponsored = data['sponsored'] as List<dynamic>? ?? [];
        for (final item in sponsored) {
          places.add(_placeFromApiListing(item as Map<String, dynamic>, isSponsored: true));
        }

        final featured = data['featured'] as List<dynamic>? ?? [];
        for (final item in featured) {
          places.add(_placeFromApiListing(item as Map<String, dynamic>, isFeatured: true));
        }

        final normal = data['normal'] as Map<String, dynamic>? ?? {};
        final normalData = normal['data'] as List<dynamic>? ?? [];
        for (final item in normalData) {
          places.add(_placeFromApiListing(item as Map<String, dynamic>));
        }

        if (places.isNotEmpty) {
          nearbyPlaces = places;
          _markFavorites(nearbyPlaces);
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Fallback: Use Overpass (OpenStreetMap) for nearby GPS-based results
      if (currentPosition != null) {
        nearbyPlaces = await _overpassService.searchNearby(
          currentPosition!.latitude,
          currentPosition!.longitude,
          category,
        );
        _markFavorites(nearbyPlaces);
      } else {
        nearbyPlaces = [];
      }
    } catch (e) {
      // Final fallback — try Overpass if backend failed
      if (currentPosition != null) {
        try {
          nearbyPlaces = await _overpassService.searchNearby(
            currentPosition!.latitude,
            currentPosition!.longitude,
            category,
          );
          _markFavorites(nearbyPlaces);
        } catch (_) {
          nearbyPlaces = [];
          errorMessage = 'Could not find nearby places. Check your connection.';
        }
      } else {
        nearbyPlaces = [];
        errorMessage = 'Location not available. Please enable GPS.';
      }
    }

    isLoading = false;
    notifyListeners();
  }

  /// Load famous places (top-rated) for the current city.
  /// Uses the first available category or a general approach.
  Future<void> loadFamousPlaces() async {
    if (_currentCitySlug == null) return;

    try {
      // Use search with empty query won't work. Instead, load from a popular category
      // or just use the first category that has places.
      if (categories.isNotEmpty) {
        final topCategory = categories.firstWhere(
          (c) => (c['count'] as int? ?? 0) > 0,
          orElse: () => categories.first,
        );
        final slug = topCategory['slug'] as String? ?? '';
        if (slug.isNotEmpty) {
          final response = await _apiService.getPlaces(_currentCitySlug!, slug, perPage: 10);
          final data = response['data'] as Map<String, dynamic>? ?? {};

          final places = <PlaceModel>[];
          final sponsored = data['sponsored'] as List<dynamic>? ?? [];
          for (final item in sponsored) {
            places.add(_placeFromApiListing(item as Map<String, dynamic>, isSponsored: true));
          }
          final featured = data['featured'] as List<dynamic>? ?? [];
          for (final item in featured) {
            places.add(_placeFromApiListing(item as Map<String, dynamic>, isFeatured: true));
          }
          final normal = data['normal'] as Map<String, dynamic>? ?? {};
          final normalData = normal['data'] as List<dynamic>? ?? [];
          for (final item in normalData) {
            places.add(_placeFromApiListing(item as Map<String, dynamic>));
          }

          famousPlaces = places;
          _markFavorites(famousPlaces);
          notifyListeners();
        }
      }
    } catch (_) {
      // Non-critical – just leave famousPlaces empty
    }
  }

  // ─── Place Detail ──────────────────────────────────────────────────────────

  /// Load full place detail from the backend.
  Future<PlaceModel?> loadPlaceDetail(String slug) async {
    try {
      final data = await _apiService.getPlaceDetail(slug);
      final place = _placeFromApiDetail(data);
      selectedPlace = place;
      notifyListeners();
      return place;
    } catch (e) {
      errorMessage = 'Failed to load place: ${_friendlyError(e)}';
      notifyListeners();
      return null;
    }
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  Future<void> searchByText(String query) async {
    if (query.trim().isEmpty) return;

    isSearching = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await _apiService.search(query, citySlug: _currentCitySlug);
      searchResults = results
          .map((item) => _placeFromSearchResult(item as Map<String, dynamic>))
          .toList();
      _markFavorites(searchResults);
      await addRecentSearch(query);
    } catch (e) {
      errorMessage = 'Search failed: ${_friendlyError(e)}';
    }

    isSearching = false;
    notifyListeners();
  }

  // ─── Leads & Reviews ───────────────────────────────────────────────────────

  /// Submit an enquiry for a place. Returns OTP reference on success.
  Future<Map<String, dynamic>> submitEnquiry(Map<String, dynamic> data) async {
    return _apiService.submitEnquiry(data);
  }

  /// Verify OTP for lead submission.
  Future<Map<String, dynamic>> verifyOtp(String otpReference, String otp) async {
    return _apiService.verifyOtp(otpReference, otp);
  }

  /// Resend OTP.
  Future<Map<String, dynamic>> resendOtp(String otpReference) async {
    return _apiService.resendOtp(otpReference);
  }

  /// Submit a review for a place.
  Future<Map<String, dynamic>> submitReview(Map<String, dynamic> data) async {
    return _apiService.submitReview(data);
  }

  // ─── Favorites (Local Storage) ─────────────────────────────────────────────

  void toggleFavorite(PlaceModel place) {
    final index = favoritePlaces.indexWhere((p) => p.id == place.id);
    if (index >= 0) {
      favoritePlaces.removeAt(index);
      place.isFavorite = false;
    } else {
      place.isFavorite = true;
      favoritePlaces.add(place);
    }
    _saveFavorites();
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList('favorite_places');
      if (data != null) {
        favoritePlaces = data
            .map((s) => PlaceModel.fromJson(json.decode(s) as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      favoritePlaces = [];
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = favoritePlaces.map((p) => json.encode(p.toJson())).toList();
      await prefs.setStringList('favorite_places', data);
    } catch (_) {}
  }

  // ─── Recent Searches (Local Storage) ───────────────────────────────────────

  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      recentSearches = prefs.getStringList('recent_searches') ?? [];
    } catch (_) {
      recentSearches = [];
    }
  }

  Future<void> addRecentSearch(String query) async {
    recentSearches.remove(query);
    recentSearches.insert(0, query);
    if (recentSearches.length > 20) {
      recentSearches = recentSearches.sublist(0, 20);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', recentSearches);
    } catch (_) {}
  }

  // ─── UI Helpers ────────────────────────────────────────────────────────────

  void clearSearchResults() {
    searchResults = [];
    isSearching = false;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void setSelectedPlace(PlaceModel? place) {
    selectedPlace = place;
    notifyListeners();
  }

  // ─── Private: Model Mapping ────────────────────────────────────────────────

  /// Convert a place listing (from /cities/{slug}/places/{cat}) to PlaceModel.
  PlaceModel _placeFromApiListing(Map<String, dynamic> json, {bool isSponsored = false, bool isFeatured = false}) {
    final String adLabel = isSponsored ? 'sponsored' : (isFeatured ? 'featured' : '');
    return PlaceModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      category: selectedCategory ?? '',
      subcategory: adLabel,
      lat: 0,
      lng: 0,
      address: json['address'] ?? '',
      phone: json['phone'],
      website: json['website'],
      rating: (json['rating_avg'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] as int? ?? json['rating_count'] as int?,
      imageUrl: json['cover_image'] ?? json['logo'],
      placeId: json['slug'],
      tags: json['tagline'],
    );
  }

  /// Convert a place detail response to PlaceModel.
  PlaceModel _placeFromApiDetail(Map<String, dynamic> json) {
    return PlaceModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      category: (json['category'] as Map<String, dynamic>?)?['name'] ?? '',
      subcategory: (json['category'] as Map<String, dynamic>?)?['slug'] ?? '',
      lat: (json['latitude'] as num?)?.toDouble() ?? 0,
      lng: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'] ?? '',
      phone: json['phone'],
      website: json['website'],
      rating: (json['rating_avg'] as num?)?.toDouble(),
      reviewsCount: json['rating_count'] as int?,
      openingHours: _formatWorkingHours(json['working_hours']),
      imageUrl: json['cover_image'] ?? json['logo'],
      placeId: json['slug'],
      tags: json['tagline'],
    );
  }

  /// Convert a search result item to PlaceModel.
  PlaceModel _placeFromSearchResult(Map<String, dynamic> json) {
    return PlaceModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['category_slug'] ?? '',
      lat: 0,
      lng: 0,
      address: json['address'] ?? '',
      phone: json['phone'],
      rating: (json['rating_avg'] as num?)?.toDouble(),
      imageUrl: json['logo'],
      placeId: json['slug'],
      tags: json['tagline'],
    );
  }

  /// Mark places that are in favorites.
  void _markFavorites(List<PlaceModel> places) {
    final favoriteIds = favoritePlaces.map((f) => f.id).toSet();
    for (final place in places) {
      place.isFavorite = favoriteIds.contains(place.id);
    }
  }

  /// Convert a city name to a URL slug.
  String _toSlug(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'[\s]+'), '-');
  }

  /// Format working_hours JSON to display string.
  String? _formatWorkingHours(dynamic workingHours) {
    if (workingHours == null) return null;
    if (workingHours is String) return workingHours;
    if (workingHours is Map) {
      // e.g. { "monday": "9:00-18:00", ... }
      final entries = (workingHours as Map<String, dynamic>).entries;
      if (entries.isEmpty) return null;
      return entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return workingHours.toString();
  }

  /// Human-friendly error message.
  String _friendlyError(dynamic e) {
    if (e is CityExplorerApiException) {
      return e.message;
    }
    return e.toString().replaceAll('Exception: ', '');
  }
}
