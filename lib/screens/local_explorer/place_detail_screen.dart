import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glass_kit/glass_kit.dart';
import '../../providers/local_explorer_provider.dart';
import '../../models/place_model.dart';
import '../../theme/app_theme.dart';

class PlaceDetailScreen extends StatelessWidget {
  final PlaceModel place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalExplorerProvider>(
      builder: (context, provider, _) {
        final updatedPlace = provider.favoritePlaces.where((p) => p.id == place.id).isNotEmpty
            ? provider.favoritePlaces.firstWhere((p) => p.id == place.id)
            : place;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, updatedPlace),
              SliverToBoxAdapter(child: _buildBody(context, updatedPlace, provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, PlaceModel place) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.black,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'place_${place.id}',
              child: CachedNetworkImage(
                imageUrl: place.imageUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[800]),
                errorWidget: (_, __, ___) => Container(color: Colors.grey[800], child: const Icon(Icons.image, color: Colors.white38, size: 60)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.brandNavy.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(place.category, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins')),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (place.isOpen == true) ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text((place.isOpen == true) ? 'Open' : 'Closed', style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(place.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('${place.rating ?? '-'}', style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                      Text(' (${place.reviewsCount} reviews)', style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
                      const SizedBox(width: 16),
                      Icon(Icons.location_on, color: Colors.white70, size: 16),
                      Text(' ${place.distance?.toStringAsFixed(1) ?? "0.0"} km', style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
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

  Widget _buildBody(BuildContext context, PlaceModel place, LocalExplorerProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionButtons(context, place, provider),
            const SizedBox(height: 24),
            _buildSectionTitle(Icons.location_on, 'Address'),
            const SizedBox(height: 8),
            GlassContainer.clearGlass(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(16),
              borderWidth: 0.5,
              borderColor: Colors.white.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.address, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: () async {
                          await launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}'));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, color: AppColors.brandNavy),
                            const SizedBox(width: 8),
                            const Text('View on Map', style: TextStyle(fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (place.phone != null && place.phone!.isNotEmpty) ...[
              _buildInfoRow(Icons.phone, 'Phone', place.phone!, () async {
                await launchUrl(Uri.parse('tel:${place.phone}'));
              }),
              const SizedBox(height: 12),
            ],
            if (place.website != null && place.website!.isNotEmpty) ...[
              _buildInfoRow(Icons.language, 'Website', place.website!, () async {
                await launchUrl(Uri.parse(place.website!));
              }),
              const SizedBox(height: 12),
            ],
            _buildSectionTitle(Icons.access_time, 'Opening Hours'),
            const SizedBox(height: 8),
            GlassContainer.clearGlass(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(16),
              borderWidth: 0.5,
              borderColor: Colors.white.withOpacity(0.3),
              child: place.openingHours != null && place.openingHours!.isNotEmpty
                  ? Column(
                      children: place.openingHours!.split(',').map((hour) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('  $hour', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      )).toList(),
                    )
                  : const Text('Hours not available', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            if (place.tags != null && place.tags!.isNotEmpty) ...[
              _buildSectionTitle(Icons.label, 'Tags'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: (place.tags ?? '').split(',').map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tag, style: TextStyle(color: AppColors.brandNavy, fontFamily: 'Poppins', fontSize: 12)),
                )).toList(),
              ),
              const SizedBox(height: 20),
            ],
            _buildSectionTitle(Icons.reviews, 'Reviews'),
            const SizedBox(height: 8),
            GlassContainer.clearGlass(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(16),
              borderWidth: 0.5,
              borderColor: Colors.white.withOpacity(0.3),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${place.rating ?? '-'}', style: const TextStyle(fontSize: 36, fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.amber)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: List.generate(5, (i) => Icon(Icons.star, size: 18, color: i < (place.rating ?? 0).round() ? Colors.amber : Colors.grey[300]))),
                          Text('${place.reviewsCount} reviews', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSimilarPlaces(context, provider),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PlaceModel place, LocalExplorerProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(context, Icons.directions, 'Directions', Colors.blue, () async {
          await launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${place.lat},${place.lng}'));
        }),
        _buildActionButton(context, Icons.call, 'Call', Colors.green, () async {
          if (place.phone != null) await launchUrl(Uri.parse('tel:${place.phone}'));
        }),
        _buildActionButton(context, Icons.share, 'Share', Colors.orange, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature coming soon')));
        }),
        _buildActionButton(
          context,
          place.isFavorite ? Icons.favorite : Icons.favorite_border,
          'Save',
          Colors.red,
          () => provider.toggleFavorite(place),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brandNavy),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, VoidCallback onTap) {
    return GlassContainer.clearGlass(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      borderWidth: 0.5,
      borderColor: Colors.white.withOpacity(0.3),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.brandNavy, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontFamily: 'Poppins')),
                Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            Icon(Icons.open_in_new, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarPlaces(BuildContext context, LocalExplorerProvider provider) {
    final similar = provider.nearbyPlaces
        .where((p) => p.category == place.category && p.id != place.id)
        .take(4)
        .toList();

    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(Icons.explore, 'Similar Places'),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = similar[index];
              return GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => PlaceDetailScreen(place: p),
                )),
                child: SizedBox(
                  width: 140,
                  child: GlassContainer.clearGlass(
                    borderRadius: BorderRadius.circular(16),
                    borderWidth: 0.5,
                    borderColor: Colors.white.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: p.imageUrl ?? '',
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.grey[200]),
                              errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Poppins', fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.star, size: 10, color: Colors.amber),
                                    Text(' ${p.rating ?? '-'}', style: const TextStyle(fontSize: 10, fontFamily: 'Poppins')),
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
            },
          ),
        ),
      ],
    );
  }
}
