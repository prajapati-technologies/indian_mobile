import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glass_kit/glass_kit.dart';
import '../../providers/local_explorer_provider.dart';
import '../../models/place_model.dart';
import '../../theme/app_theme.dart';
import 'place_detail_screen.dart';

class CategoryPlacesScreen extends StatefulWidget {
  final String category;

  const CategoryPlacesScreen({super.key, required this.category});

  @override
  State<CategoryPlacesScreen> createState() => _CategoryPlacesScreenState();
}

class _CategoryPlacesScreenState extends State<CategoryPlacesScreen> {
  bool _showMap = false;
  int _page = 1;
  final ScrollController _scrollController = ScrollController();
  final MapController _mapController = MapController();

  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlaces();
    });
    _scrollController.addListener(_onScroll);
  }

  void _loadPlaces() {
    final provider = context.read<LocalExplorerProvider>();
    provider.searchNearby(widget.category);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _page++;
    await context.read<LocalExplorerProvider>().searchNearby(widget.category);
    setState(() => _isLoadingMore = false);
  }

  IconData _categoryIcon(String cat) {
    final icons = {
      'Hospital': Icons.local_hospital, 'Pharmacy': Icons.medication, 'Restaurant': Icons.restaurant,
      'Cafe': Icons.coffee, 'Hotel': Icons.hotel, 'Temple': Icons.temple_hindu, 'Mosque': Icons.mosque,
      'Church': Icons.church, 'ATM': Icons.credit_card, 'Bank': Icons.account_balance,
      'Petrol Pump': Icons.local_gas_station, 'Parking': Icons.local_parking, 'Bus Stand': Icons.directions_bus,
      'Railway Station': Icons.train, 'Metro': Icons.subway, 'Airport': Icons.flight,
      'School': Icons.school, 'College': Icons.school, 'Gym': Icons.fitness_center,
      'Park': Icons.park, 'Shopping Mall': Icons.store_mall_directory, 'Market': Icons.store,
    };
    return icons[cat] ?? Icons.place;
  }

  Color _categoryColor(String cat) {
    final colors = {
      'Hospital': Colors.red, 'Pharmacy': Colors.green, 'Restaurant': Colors.orange,
      'Cafe': Colors.brown, 'Hotel': Colors.purple, 'Temple': Colors.pink,
      'Mosque': Colors.teal, 'Church': Colors.indigo,
    };
    return colors[cat] ?? Colors.blue;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalExplorerProvider>(
      builder: (context, provider, _) {
        final places = provider.nearbyPlaces;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(widget.category, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(_showMap ? Icons.view_list : Icons.map),
                onPressed: () => setState(() => _showMap = !_showMap),
                tooltip: _showMap ? 'List View' : 'Map View',
              ),
            ],
          ),
          body: _showMap ? _buildMapView(places, provider) : _buildListView(places, provider),
        );
      },
    );
  }

  Widget _buildListView(List<PlaceModel> places, LocalExplorerProvider provider) {
    if (provider.isLoading && places.isEmpty) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(height: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadPlaces(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
        itemCount: places.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == places.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildPlaceCard(context, places[index]);
        },
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, PlaceModel place) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(place: place),
      )),
      child: GlassContainer.clearGlass(
        margin: const EdgeInsets.only(bottom: 16),
        borderRadius: BorderRadius.circular(20),
        borderWidth: 0.5,
        borderColor: Colors.white.withOpacity(0.3),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: place.imageUrl ?? '',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(height: 140, color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(height: 140, color: Colors.grey[300], child: const Icon(Icons.image, color: Colors.white54)),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _categoryColor(place.category).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_categoryIcon(place.category), size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(place.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (place.isOpen == true) ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text((place.isOpen == true) ? 'Open' : 'Closed', style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Poppins')),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 15)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text((place.rating ?? 0).toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(place.address, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'Poppins'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (place.distance != null) ...[
                        const SizedBox(width: 4),
                        Text('${place.distance!.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionButton(Icons.call, 'Call', Colors.green, () async {
                        await launchUrl(Uri.parse('tel:${place.phone ?? ''}'));
                      }),
                      _actionButton(Icons.directions, 'Directions', Colors.blue, () async {
                        await launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}'));
                      }),
                      _actionButton(Icons.share, 'Share', Colors.orange, () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature coming soon')));
                      }),
                      _actionButton(
                        place.isFavorite ? Icons.favorite : Icons.favorite_border,
                        'Save',
                        Colors.red,
                        () => context.read<LocalExplorerProvider>().toggleFavorite(place),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _buildMapView(List<PlaceModel> places, LocalExplorerProvider provider) {
    final userPos = provider.currentPosition;
    final initialCenter = userPos != null
        ? LatLng(userPos.latitude, userPos.longitude)
        : const LatLng(28.6139, 77.2090);

    final markers = <Marker>[
      if (userPos != null)
        Marker(
          point: LatLng(userPos.latitude, userPos.longitude),
          child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
        ),
      for (final place in places)
        Marker(
          point: LatLng(place.lat, place.lng),
          child: GestureDetector(
            onTap: () => _showPlaceBottomSheet(context, place),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _categoryColor(place.category),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(_categoryIcon(place.category), color: Colors.white, size: 16),
            ),
          ),
        ),
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.indian_information.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          top: 100,
          left: 16,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'All', 'Hospital', 'Restaurant', 'Temple', 'ATM', 'Petrol Pump', 'Park'
              ].map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                  selected: cat == 'All' || cat == widget.category,
                  onSelected: (_) {},
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.brandNavy.withOpacity(0.2),
                  checkmarkColor: AppColors.brandNavy,
                ),
              )).toList(),
            ),
          ),
        ),
        Positioned(
          bottom: 32,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () async {
              await provider.refreshLocation();
              if (provider.currentPosition != null) {
                _mapController.move(LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude), 15.0);
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  void _showPlaceBottomSheet(BuildContext context, PlaceModel place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: place.imageUrl ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          Text('${place.rating} (${place.reviewsCount})', style: const TextStyle(fontSize: 12, fontFamily: 'Poppins')),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on, size: 14, color: Colors.grey),
                          Text('${place.distance?.toStringAsFixed(1) ?? "-"} km', style: const TextStyle(fontSize: 12, fontFamily: 'Poppins')),
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
                ElevatedButton.icon(
                  onPressed: () async => await launchUrl(Uri.parse('tel:${place.phone ?? ''}')),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call', style: TextStyle(fontFamily: 'Poppins')),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: () async => await launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}')),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions', style: TextStyle(fontFamily: 'Poppins')),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
