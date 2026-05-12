import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/local_explorer_provider.dart';
import '../../models/place_model.dart';
import '../../theme/app_theme.dart';
import 'category_places_screen.dart';
import 'place_detail_screen.dart';
import 'search_screen.dart';
import 'ai_guide_screen.dart';

class LocalExplorerScreen extends StatefulWidget {
  const LocalExplorerScreen({super.key});

  @override
  State<LocalExplorerScreen> createState() => _LocalExplorerScreenState();
}

class _LocalExplorerScreenState extends State<LocalExplorerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LocalExplorerProvider>();
      if (!provider.isLocationLoading) {
        provider.initializeLocation();
        provider.loadFamousPlaces();
      }
    });
  }

  Future<void> _onRefresh() async {
    final provider = context.read<LocalExplorerProvider>();
    await provider.refreshLocation();
    await provider.loadFamousPlaces();
  }

  void _showEmergencyDialog(BuildContext context, String label, String number) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [Icon(Icons.warning_amber_rounded, color: Colors.red), const SizedBox(width: 8), Text(label)],
        ),
        content: Text('Call $label at $number?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              await launchUrl(Uri.parse('tel:$number'));
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.call),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalExplorerProvider>(
      builder: (context, provider, _) {
        if (provider.isLocationLoading && provider.currentPosition == null) {
          return _buildLoadingSkeleton();
        }
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationBanner(provider),
                _buildSearchBar(context, provider),
                _buildEmergencyQuickAccess(context),
                _buildCategoriesGrid(context, provider),
                _buildFamousPlacesSection(context, provider),
                _buildTrendingNearby(context, provider),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 200, color: Colors.white),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30))),
                  const SizedBox(height: 20),
                  Row(children: List.generate(4, (_) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                  ))),
                  const SizedBox(height: 20),
                  Container(height: 20, width: 200, color: Colors.white),
                  const SizedBox(height: 10),
                  Row(children: List.generate(3, (_) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(width: 150, height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                  ))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBanner(LocalExplorerProvider provider) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1929), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.currentLocationDisplay,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                const Text('☀️ 32°C', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.white54, size: 16),
                const SizedBox(width: 4),
                Text(
                  provider.currentCity?.city ?? 'Detecting...',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _onRefresh,
                  child: const Icon(Icons.refresh, color: Colors.white60, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, LocalExplorerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Transform.translate(
        offset: const Offset(0, -30),
        child: GlassContainer.clearGlass(
          height: 60,
          width: double.infinity,
          borderRadius: BorderRadius.circular(30),
          borderWidth: 0.5,
          borderColor: Colors.white.withOpacity(0.3),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Icon(Icons.search, color: Colors.grey[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search hospitals, food, temples...',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14, fontFamily: 'Poppins'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.mic, color: AppColors.brandNavy),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyQuickAccess(BuildContext context) {
    final emergencies = [
      ('🚓', 'Police', '100'),
      ('🚑', 'Ambulance', '102'),
      ('🚒', 'Fire', '101'),
      ('👩', 'Women Help', '1091'),
      ('🏥', 'Hospital', '108'),
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: emergencies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = emergencies[index];
            return GestureDetector(
              onTap: () => _showEmergencyDialog(context, item.$2, item.$3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(item.$2, style: const TextStyle(fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, LocalExplorerProvider provider) {
    final categories = [
      ('Hospital', Icons.local_hospital, 0xFFFF5252),
      ('Pharmacy', Icons.medication, 0xFF4CAF50),
      ('Doctor', Icons.person, 0xFF2196F3),
      ('Restaurant', Icons.restaurant, 0xFFFF9800),
      ('Cafe', Icons.coffee, 0xFF795548),
      ('Hotel', Icons.hotel, 0xFF9C27B0),
      ('Temple', Icons.temple_hindu, 0xFFE91E63),
      ('Mosque', Icons.mosque, 0xFF009688),
      ('Church', Icons.church, 0xFF3F51B5),
      ('Gurudwara', Icons.temple_buddhist, 0xFFFF5722),
      ('ATM', Icons.credit_card, 0xFF607D8B),
      ('Bank', Icons.account_balance, 0xFF795548),
      ('Petrol Pump', Icons.local_gas_station, 0xFFFF5722),
      ('Parking', Icons.local_parking, 0xFF2196F3),
      ('Bus Stand', Icons.directions_bus, 0xFF4CAF50),
      ('Railway Station', Icons.train, 0xFF9C27B0),
      ('Metro', Icons.subway, 0xFFE91E63),
      ('Airport', Icons.flight, 0xFF3F51B5),
      ('School', Icons.school, 0xFFFF9800),
      ('College', Icons.school, 0xFF009688),
      ('Gym', Icons.fitness_center, 0xFFFF5252),
      ('Park', Icons.park, 0xFF4CAF50),
      ('Shopping Mall', Icons.store_mall_directory, 0xFFE91E63),
      ('Market', Icons.store, 0xFFFF5722),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Explore Categories', style: TextStyle(fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiGuideScreen())),
                child: const Text('AI Guide →', style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 200 + index * 50),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CategoryPlacesScreen(category: cat.$1),
                  )),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(cat.$3).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(cat.$2, color: Color(cat.$3), size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.$1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFamousPlacesSection(BuildContext context, LocalExplorerProvider provider) {
    final places = provider.famousPlaces;
    final city = provider.currentCity?.city ?? 'Your City';

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏆 Famous in $city', style: const TextStyle(fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (provider.isLoading && places.isEmpty)
            SizedBox(
              height: 200,
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (_, __) => Container(
                    width: 160, margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return _buildFamousPlaceCard(context, place);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFamousPlaceCard(BuildContext context, PlaceModel place) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(place: place),
      )),
      child: Hero(
        tag: 'place_${place.id}',
        child: GlassContainer.clearGlass(
          width: 180,
          margin: const EdgeInsets.only(right: 12),
          borderRadius: BorderRadius.circular(20),
          borderWidth: 0.5,
          borderColor: Colors.white.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: place.imageUrl ?? '',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.image, color: Colors.white54)),
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
                          child: Text((place.isOpen == true) ? 'Open' : 'Closed', style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Poppins')),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.white),
                              const SizedBox(width: 2),
                              Text((place.rating ?? 0).toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text('${place.distance?.toStringAsFixed(1) ?? "0.0"} km', style: TextStyle(color: Colors.grey[600], fontSize: 11, fontFamily: 'Poppins')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingNearby(BuildContext context, LocalExplorerProvider provider) {
    final places = provider.nearbyPlaces.where((p) => (p.rating ?? 0) >= 4.0).toList();
    if (places.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔥 Trending Nearby', style: TextStyle(fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: places.length > 6 ? 6 : places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return _buildTrendingCard(context, place);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(BuildContext context, PlaceModel place) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(place: place),
      )),
      child: Hero(
        tag: 'trending_${place.id}',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: place.imageUrl ?? '',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.image, color: Colors.white54)),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.restaurant, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(child: Text(place.category, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontFamily: 'Poppins'))),
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          Text((place.rating ?? 0).toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, fontFamily: 'Poppins')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (place.isOpen == true) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text((place.isOpen == true) ? 'Open' : 'Closed', style: TextStyle(color: (place.isOpen == true) ? Colors.green : Colors.red, fontSize: 10, fontFamily: 'Poppins')),
                          ),
                          const Spacer(),
                          Text('${place.distance?.toStringAsFixed(1) ?? "0.0"} km', style: TextStyle(color: Colors.grey[600], fontSize: 10, fontFamily: 'Poppins')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
