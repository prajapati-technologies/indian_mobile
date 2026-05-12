import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:glass_kit/glass_kit.dart';
import '../../providers/local_explorer_provider.dart';
import '../../models/place_model.dart';
import 'place_detail_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final MapController _mapController = MapController();
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All', 'Hospital', 'Restaurant', 'Temple', 'ATM', 'Petrol Pump',
    'Pharmacy', 'Cafe', 'Hotel', 'Bank', 'Park', 'Market'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LocalExplorerProvider>();
      if (provider.currentPosition == null) {
        provider.initializeLocation();
      }
    });
  }

  Color _categoryColor(String category) {
    final colors = {
      'Hospital': Colors.red, 'Restaurant': Colors.orange, 'Temple': Colors.pink,
      'ATM': Colors.blueGrey, 'Petrol Pump': Colors.deepOrange, 'Pharmacy': Colors.green,
      'Cafe': Colors.brown, 'Hotel': Colors.purple, 'Bank': Colors.indigo,
      'Park': Colors.green, 'Market': Colors.amber,
    };
    return colors[category] ?? Colors.blue;
  }

  IconData _categoryIcon(String category) {
    final icons = {
      'Hospital': Icons.local_hospital, 'Restaurant': Icons.restaurant, 'Temple': Icons.temple_hindu,
      'ATM': Icons.credit_card, 'Petrol Pump': Icons.local_gas_station, 'Pharmacy': Icons.medication,
      'Cafe': Icons.coffee, 'Hotel': Icons.hotel, 'Bank': Icons.account_balance,
      'Park': Icons.park, 'Market': Icons.store,
    };
    return icons[category] ?? Icons.place;
  }

  List<PlaceModel> _filteredPlaces(LocalExplorerProvider provider) {
    if (_selectedCategory == 'All') return provider.nearbyPlaces;
    return provider.nearbyPlaces.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalExplorerProvider>(
      builder: (context, provider, _) {
        final places = _filteredPlaces(provider);
        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: provider.currentPosition != null
                      ? LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude)
                      : const LatLng(28.6139, 77.2090),
                  initialZoom: 14.0,
                  onTap: (_, __) => Navigator.of(context).maybePop(),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.indian_information.app',
                  ),
                  MarkerLayer(
                    markers: [
                      if (provider.currentPosition != null)
                        _buildUserMarker(provider.currentPosition!.latitude, provider.currentPosition!.longitude),
                      for (final place in places)
                        _buildPlaceMarker(context, place),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassContainer.clearGlass(
                        height: 48,
                        borderRadius: BorderRadius.circular(16),
                        borderWidth: 0.5,
                        borderColor: Colors.white.withOpacity(0.3),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search nearby...',
                            hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey[500]),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                left: 16,
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat, style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          )),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedCategory = cat),
                          backgroundColor: Colors.white,
                          selectedColor: _categoryColor(cat),
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'locate',
                      onPressed: () async {
                        await provider.refreshLocation();
                        if (provider.currentPosition != null) {
                          _mapController.move(
                            LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude),
                            15.0,
                          );
                        }
                      },
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      heroTag: 'list',
                      onPressed: () => _showPlacesBottomSheet(context, places),
                      child: const Icon(Icons.list),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Marker _buildUserMarker(double lat, double lng) {
    return Marker(
      point: LatLng(lat, lng),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
        ),
        child: const Icon(Icons.navigation, color: Colors.white, size: 14),
      ),
    );
  }

  Marker _buildPlaceMarker(BuildContext context, PlaceModel place) {
    return Marker(
      point: LatLng(place.lat, place.lng),
      child: GestureDetector(
        onTap: () => _showPlaceBottomSheet(context, place),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _categoryColor(place.category),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: _categoryColor(place.category).withOpacity(0.4), blurRadius: 8)],
          ),
          child: Icon(_categoryIcon(place.category), color: Colors.white, size: 18),
        ),
      ),
    );
  }

  void _showPlaceBottomSheet(BuildContext context, PlaceModel place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: place.imageUrl ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(_categoryIcon(place.category), size: 14, color: _categoryColor(place.category)),
                          const SizedBox(width: 4),
                          Text(place.category, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Poppins')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text(' ${place.rating ?? '-'} ', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                          Text('(${place.reviewsCount})', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontFamily: 'Poppins')),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                          Text(' ${place.distance?.toStringAsFixed(1) ?? "-"} km', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Poppins')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async => await launchUrl(Uri.parse('tel:${place.phone ?? ''}')),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call', style: TextStyle(fontFamily: 'Poppins')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async => await launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}')),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Directions', style: TextStyle(fontFamily: 'Poppins')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)));
                },
                child: const Text('View Details →', style: TextStyle(fontFamily: 'Poppins')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlacesBottomSheet(BuildContext context, List<PlaceModel> places) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${places.length} Places Nearby', style: const TextStyle(fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: places.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final place = places[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _categoryColor(place.category).withOpacity(0.2),
                        child: Icon(_categoryIcon(place.category), color: _categoryColor(place.category), size: 20),
                      ),
                      title: Text(place.name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14)),
                      subtitle: Text('${place.distance?.toStringAsFixed(1) ?? "-"} km', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${place.rating ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _mapController.move(LatLng(place.lat, place.lng), 16.0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
