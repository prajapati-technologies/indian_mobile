import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/local_explorer_provider.dart';
import '../../models/place_model.dart';
import '../../theme/app_theme.dart';
import 'place_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      context.read<LocalExplorerProvider>().clearSearchResults();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<LocalExplorerProvider>().searchByText(query);
      context.read<LocalExplorerProvider>().addRecentSearch(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalExplorerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildSearchBar(provider),
                Expanded(
                  child: _buildBody(provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(LocalExplorerProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GlassContainer.clearGlass(
        height: 56,
        width: double.infinity,
        borderRadius: BorderRadius.circular(28),
        borderWidth: 0.5,
        borderColor: Colors.white.withOpacity(0.3),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search hospitals, food, temples...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14, fontFamily: 'Poppins'),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[500]),
                onPressed: () {
                  _searchController.clear();
                  provider.clearSearchResults();
                  _searchFocus.requestFocus();
                },
              ),
            IconButton(
              icon: Icon(Icons.mic, color: AppColors.brandNavy),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice search coming soon')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LocalExplorerProvider provider) {
    if (_searchController.text.isEmpty) {
      return _buildInitialState(provider);
    }
    if (provider.isSearching) {
      return _buildLoading();
    }
    if (provider.searchResults.isEmpty) {
      return _buildEmptyState();
    }
    return _buildResultsList(provider.searchResults);
  }

  Widget _buildInitialState(LocalExplorerProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Searches', style: TextStyle(fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => {},
                  child: const Text('Clear All', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: provider.recentSearches.map((s) => ActionChip(
                avatar: Icon(Icons.history, size: 16, color: Colors.grey[500]),
                label: Text(s, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                onPressed: () {
                  _searchController.text = s;
                  provider.searchByText(s);
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          const Text('Popular Categories', style: TextStyle(fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            children: [
              ('🏥', 'Hospital'), ('🍔', 'Restaurant'), ('🕌', 'Temple'), ('🏧', 'ATM'),
              ('⛽', 'Petrol'), ('💊', 'Pharmacy'), ('☕', 'Cafe'), ('🏨', 'Hotel'),
            ].map((e) => GestureDetector(
              onTap: () {
                _searchController.text = e.$2;
                provider.searchByText(e.$2);
              },
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
                    Text(e.$1, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(e.$2, style: const TextStyle(fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(Icons.search, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Search what you need', style: TextStyle(color: Colors.grey[400], fontSize: 16, fontFamily: 'Poppins')),
                Text('Find places, services, and more', style: TextStyle(color: Colors.grey[400], fontSize: 13, fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No results found', style: TextStyle(color: Colors.grey[500], fontSize: 16, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Text('Try a different search term', style: TextStyle(color: Colors.grey[400], fontSize: 13, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<PlaceModel> results) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) => _buildResultCard(context, results[index]),
    );
  }

  Widget _buildResultCard(BuildContext context, PlaceModel place) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(place: place),
      )),
      child: GlassContainer.clearGlass(
        margin: const EdgeInsets.only(bottom: 12),
        borderRadius: BorderRadius.circular(16),
        borderWidth: 0.5,
        borderColor: Colors.white.withOpacity(0.3),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: place.imageUrl ?? '',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 90, height: 90, color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Container(width: 90, height: 90, color: Colors.grey[300], child: const Icon(Icons.image, color: Colors.white54)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(place.category, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontFamily: 'Poppins')),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        Text(' ${place.rating ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Poppins', fontSize: 12)),
                        const SizedBox(width: 12),
                        Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                        Text(' ${place.distance?.toStringAsFixed(1) ?? "-"} km', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontFamily: 'Poppins')),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (place.isOpen == true) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text((place.isOpen == true) ? 'Open' : 'Closed', style: TextStyle(color: (place.isOpen == true) ? Colors.green : Colors.red, fontSize: 10, fontFamily: 'Poppins')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(place.isFavorite ? Icons.favorite : Icons.favorite_border, size: 20),
                    color: place.isFavorite ? Colors.red : Colors.grey[400],
                    onPressed: () => context.read<LocalExplorerProvider>().toggleFavorite(place),
                  ),
                  GestureDetector(
                    onTap: () async => await launchUrl(Uri.parse('tel:${place.phone ?? ''}')),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.call, color: Colors.green, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
