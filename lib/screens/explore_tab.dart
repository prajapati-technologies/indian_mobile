import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place_model.dart';
import '../services/overpass_service.dart';
import '../services/app_review_service.dart';
import '../theme/app_theme.dart';

/// Simplified Explore tab:
/// 1. Shows category grid
/// 2. Tap category → auto-detect GPS → fetch nearby places → show list
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _overpass = OverpassService();
  Position? _position;
  bool _locationLoading = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() { _locationLoading = true; _locationError = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _locationError = 'Location services are disabled'; _locationLoading = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationError = 'Location permission denied'; _locationLoading = false; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _locationError = 'Location permission permanently denied. Enable from Settings.'; _locationLoading = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { _position = pos; _locationLoading = false; });
    } catch (e) {
      setState(() { _locationError = 'Could not get location'; _locationLoading = false; });
    }
  }

  static const _categories = [
    // Most used daily — top priority
    _Cat(icon: Icons.local_hospital_rounded, label: 'Hospital', key: 'hospital', color: Color(0xFFE53935)),
    _Cat(icon: Icons.local_pharmacy_rounded, label: 'Pharmacy', key: 'pharmacy', color: Color(0xFF43A047)),
    _Cat(icon: Icons.local_atm_rounded, label: 'ATM', key: 'atm', color: Color(0xFF6D4C41)),
    _Cat(icon: Icons.local_gas_station_rounded, label: 'Petrol Pump', key: 'petrol_pump', color: Color(0xFF37474F)),
    _Cat(icon: Icons.restaurant_rounded, label: 'Restaurant', key: 'restaurant', color: Color(0xFFFF8F00)),
    _Cat(icon: Icons.account_balance_rounded, label: 'Bank', key: 'bank', color: Color(0xFF5E35B1)),
    _Cat(icon: Icons.local_grocery_store_rounded, label: 'Grocery', key: 'grocery', color: Color(0xFF558B2F)),
    _Cat(icon: Icons.local_police_rounded, label: 'Police', key: 'police', color: Color(0xFF1E88E5)),
    // Daily convenience
    _Cat(icon: Icons.coffee_rounded, label: 'Cafe', key: 'cafe', color: Color(0xFF795548)),
    _Cat(icon: Icons.hotel_rounded, label: 'Hotel', key: 'hotel', color: Color(0xFF8E24AA)),
    _Cat(icon: Icons.local_parking_rounded, label: 'Parking', key: 'parking', color: Color(0xFF0277BD)),
    _Cat(icon: Icons.park_rounded, label: 'Park', key: 'park', color: Color(0xFF2E7D32)),
    // Transport
    _Cat(icon: Icons.directions_bus_rounded, label: 'Bus Stand', key: 'bus_station', color: Color(0xFF00838F)),
    _Cat(icon: Icons.train_rounded, label: 'Railway', key: 'railway_station', color: Color(0xFF4527A0)),
    _Cat(icon: Icons.flight_rounded, label: 'Airport', key: 'airport', color: Color(0xFF1565C0)),
    _Cat(icon: Icons.subway_rounded, label: 'Metro', key: 'metro', color: Color(0xFF00695C)),
    // Education & Health
    _Cat(icon: Icons.school_rounded, label: 'School', key: 'school', color: Color(0xFF0277BD)),
    _Cat(icon: Icons.menu_book_rounded, label: 'College', key: 'college', color: Color(0xFF1B5E20)),
    _Cat(icon: Icons.local_library_rounded, label: 'Library', key: 'library', color: Color(0xFF4E342E)),
    _Cat(icon: Icons.fitness_center_rounded, label: 'Gym', key: 'gym', color: Color(0xFFC62828)),
    // Shopping
    _Cat(icon: Icons.store_mall_directory_rounded, label: 'Mall', key: 'shopping_mall', color: Color(0xFFEF6C00)),
    _Cat(icon: Icons.store_rounded, label: 'Market', key: 'market', color: Color(0xFFE65100)),
    _Cat(icon: Icons.phone_android_rounded, label: 'Mobile Shop', key: 'mobile_phone_shop', color: Color(0xFF263238)),
    _Cat(icon: Icons.content_cut_rounded, label: 'Salon', key: 'salon', color: Color(0xFFAD1457)),
    // Religious
    _Cat(icon: Icons.temple_hindu_rounded, label: 'Temple', key: 'temple', color: Color(0xFFD84315)),
    _Cat(icon: Icons.mosque_rounded, label: 'Mosque', key: 'mosque', color: Color(0xFF00695C)),
    _Cat(icon: Icons.church_rounded, label: 'Church', key: 'church', color: Color(0xFF283593)),
    // Entertainment
    _Cat(icon: Icons.movie_rounded, label: 'Cinema', key: 'cinema', color: Color(0xFFAD1457)),
    _Cat(icon: Icons.attractions_rounded, label: 'Tourist Spot', key: 'tourist_attraction', color: Color(0xFFFF6F00)),
    // Services
    _Cat(icon: Icons.car_repair_rounded, label: 'Mechanic', key: 'mechanic', color: Color(0xFF455A64)),
    _Cat(icon: Icons.local_post_office_rounded, label: 'Post Office', key: 'post_office', color: Color(0xFFBF360C)),
    _Cat(icon: Icons.apartment_rounded, label: 'PG / Room', key: 'pg/room', color: Color(0xFF4527A0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Explore Nearby'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_position != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: const Icon(Icons.location_on_rounded, size: 16, color: AppColors.indiaGreen),
                label: Text('GPS Active', style: TextStyle(fontSize: 11, color: AppColors.indiaGreen)),
                backgroundColor: AppColors.indiaGreen.withValues(alpha: 0.08),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
      body: _locationLoading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.brandNavy),
                SizedBox(height: 16),
                Text('Getting your location...', style: TextStyle(color: AppColors.textMuted)),
              ],
            ))
          : _locationError != null
              ? _buildLocationError()
              : _buildCategoryGrid(),
    );
  }

  Widget _buildLocationError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(_locationError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Enable location to find places near you', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return _buildCategoryItem(cat);
      },
    );
  }

  Widget _buildCategoryItem(_Cat cat) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => _NearbyResultsPage(
            category: cat.label,
            categoryKey: cat.key,
            color: cat.color,
            icon: cat.icon,
            position: _position!,
            overpass: _overpass,
          ),
        ));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(cat.icon, color: cat.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            cat.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _Cat {
  const _Cat({required this.icon, required this.label, required this.key, required this.color});
  final IconData icon;
  final String label;
  final String key;
  final Color color;
}

/// Shows nearby places list for a specific category.
class _NearbyResultsPage extends StatefulWidget {
  const _NearbyResultsPage({
    required this.category,
    required this.categoryKey,
    required this.color,
    required this.icon,
    required this.position,
    required this.overpass,
  });

  final String category;
  final String categoryKey;
  final Color color;
  final IconData icon;
  final Position position;
  final OverpassService overpass;

  @override
  State<_NearbyResultsPage> createState() => _NearbyResultsPageState();
}

class _NearbyResultsPageState extends State<_NearbyResultsPage> {
  List<PlaceModel> _places = [];
  bool _loading = true;
  String? _error;
  int _radiusKm = 10; // Default 10km

  static const _radiusOptions = [2, 5, 10, 20, 50];

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() { _loading = true; _error = null; });
    try {
      debugPrint('🔍 Searching ${widget.categoryKey} at ${widget.position.latitude}, ${widget.position.longitude} radius: ${_radiusKm}km');
      final places = await widget.overpass.searchNearby(
        widget.position.latitude,
        widget.position.longitude,
        widget.categoryKey,
        radius: _radiusKm * 1000,
        limit: 50,
      );
      debugPrint('✅ Found ${places.length} places');
      // Sort by distance
      places.sort((a, b) {
        final dA = Geolocator.distanceBetween(widget.position.latitude, widget.position.longitude, a.lat, a.lng);
        final dB = Geolocator.distanceBetween(widget.position.latitude, widget.position.longitude, b.lat, b.lng);
        return dA.compareTo(dB);
      });
      setState(() { _places = places; _loading = false; });
    } catch (e) {
      debugPrint('❌ Error: $e');
      setState(() { _error = 'Could not find places. Please check internet and try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text('Nearby ${widget.category}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Radius selector
          PopupMenuButton<int>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 20, color: AppColors.brandNavy),
                const SizedBox(width: 4),
                Text('${_radiusKm}km', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
              ],
            ),
            onSelected: (km) {
              setState(() => _radiusKm = km);
              _loadPlaces();
            },
            itemBuilder: (_) => _radiusOptions.map((km) => PopupMenuItem(
              value: km,
              child: Row(
                children: [
                  Icon(km == _radiusKm ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18, color: widget.color),
                  const SizedBox(width: 10),
                  Text('$km km', style: TextStyle(fontWeight: km == _radiusKm ? FontWeight.w700 : FontWeight.w500)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
      body: _loading
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: widget.color),
                const SizedBox(height: 16),
                Text('Finding ${widget.category.toLowerCase()} near you...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ))
          : _error != null
              ? _buildError()
              : _places.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadPlaces,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _places.length,
                        itemBuilder: (context, index) => _buildPlaceCard(_places[index], index),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Could not load results', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _loadPlaces, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 56, color: widget.color.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No ${widget.category.toLowerCase()} found nearby', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Try increasing search area or move to a different location', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(PlaceModel place, int index) {
    final distance = _calculateDistance(place);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDirections(place),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Index + Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('${index + 1}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: widget.color)),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              distance,
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      if (place.address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(place.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                ),
                // Navigate button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.directions_rounded, color: widget.color, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateDistance(PlaceModel place) {
    final distanceInMeters = Geolocator.distanceBetween(
      widget.position.latitude, widget.position.longitude,
      place.lat, place.lng,
    );
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m away';
    }
    return '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
  }

  Future<void> _openDirections(PlaceModel place) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
