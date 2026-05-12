import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place_model.dart';
import '../services/location_service.dart';
import '../services/overpass_service.dart';

class LocalExplorerProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final OverpassService _overpassService = OverpassService();

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

  String get currentLocationDisplay {
    if (currentCity != null) {
      return '${currentCity!.city}, ${currentCity!.state}';
    }
    return 'Detecting...';
  }

  Future<void> initializeLocation() async {
    isLocationLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentPosition = await _locationService.getCurrentPosition();
      currentCity = await _locationService.getCityFromLatLng(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );
      await loadFavorites();
      await loadRecentSearches();
      await loadFamousPlaces();
      await searchNearby('hospital');
    } catch (e) {
      errorMessage = e.toString();
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
    notifyListeners();
    await initializeLocation();
  }

  Future<void> searchNearby(String category) async {
    if (currentPosition == null) return;

    isLoading = true;
    selectedCategory = category;
    errorMessage = null;
    notifyListeners();

    try {
      nearbyPlaces = await _overpassService.searchNearby(
        currentPosition!.latitude,
        currentPosition!.longitude,
        category,
      );
    } catch (e) {
      errorMessage = 'Failed to search nearby: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> searchByText(String query) async {
    if (currentPosition == null) return;

    isSearching = true;
    errorMessage = null;
    notifyListeners();

    try {
      searchResults = await _overpassService.searchByText(
        query,
        currentPosition!.latitude,
        currentPosition!.longitude,
      );
    } catch (e) {
      errorMessage = 'Search failed: $e';
    }

    isSearching = false;
    notifyListeners();
  }

  Future<void> loadFamousPlaces() async {
    if (currentCity == null || currentCity!.city.isEmpty) return;

    try {
      famousPlaces = await _overpassService.getFamousPlaces(currentCity!.city);
    } catch (_) {}
  }

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
}
