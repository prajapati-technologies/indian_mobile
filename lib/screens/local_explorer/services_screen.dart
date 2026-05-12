import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/local_explorer_provider.dart';
import '../../models/place_model.dart';
import '../../theme/app_theme.dart';
import 'place_detail_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LocalExplorerProvider>();
      if (provider.nearbyPlaces.isEmpty && !provider.isLoading) {
        provider.searchNearby('');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.brandNavy,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          indicatorColor: AppColors.brandNavy,
          tabs: const [
            Tab(icon: Icon(Icons.emergency, size: 20), text: 'Emergency'),
            Tab(icon: Icon(Icons.build, size: 20), text: 'Essential'),
            Tab(icon: Icon(Icons.directions_bus, size: 20), text: 'Transport'),
            Tab(icon: Icon(Icons.account_balance, size: 20), text: 'Government'),
          ],
        ),
      ),
      body: Consumer<LocalExplorerProvider>(
        builder: (context, provider, _) => TabBarView(
          controller: _tabController,
          children: [
            _buildEmergencyTab(provider),
            _buildServiceTab(provider, 'Essential', [
              ('ATM', Icons.credit_card, Colors.blueGrey),
              ('Petrol Pump', Icons.local_gas_station, Colors.deepOrange),
              ('Pharmacy', Icons.medication, Colors.green),
              ('Bank', Icons.account_balance, Colors.indigo),
              ('Courier', Icons.local_post_office, Colors.brown),
            ]),
            _buildServiceTab(provider, 'Transport', [
              ('Bus Stand', Icons.directions_bus, Colors.teal),
              ('Railway Station', Icons.train, Colors.purple),
              ('Metro', Icons.subway, Colors.pink),
              ('Airport', Icons.flight, Colors.blue),
              ('Taxi', Icons.local_taxi, Colors.amber),
            ]),
            _buildServiceTab(provider, 'Government', [
              ('Post Office', Icons.local_post_office, Colors.blue),
              ('Police Station', Icons.local_police, Colors.indigo),
              ('Municipality', Icons.account_balance, Colors.teal),
              ('RTO', Icons.directions_car, Colors.orange),
              ('Passport Office', Icons.badge, Colors.green),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTab(LocalExplorerProvider provider) {
    final emergencies = [
      ('Police', '100', Icons.local_police, Colors.blue),
      ('Ambulance', '102', Icons.local_hospital, Colors.green),
      ('Fire', '101', Icons.fire_extinguisher, Colors.red),
      ('Women Helpline', '1091', Icons.female, Colors.pink),
      ('Hospital', '108', Icons.medical_services, Colors.orange),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Emergency Services', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                      Text('Call these numbers in case of emergency', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...emergencies.map((e) => _buildEmergencyCard(e.$1, e.$2, e.$3, e.$4)),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(String name, String number, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(number, style: TextStyle(color: Colors.grey[600], fontFamily: 'Poppins', fontSize: 13)),
        trailing: ElevatedButton.icon(
          onPressed: () async => await launchUrl(Uri.parse('tel:$number')),
          icon: const Icon(Icons.call, size: 18),
          label: const Text('Call', style: TextStyle(fontFamily: 'Poppins')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTab(LocalExplorerProvider provider, String type, List<dynamic> services) {
    final serviceList = services as List<(String, IconData, Color)>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nearby $type Services', style: const TextStyle(fontSize: 18, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tap to view nearby options', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontFamily: 'Poppins')),
          const SizedBox(height: 16),
          if (provider.isLoading && provider.nearbyPlaces.isEmpty)
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                ),
              ),
            )
          else
            ...serviceList.map((service) {
              final name = service.$1;
              final icon = service.$2;
              final color = service.$3;

              final nearby = provider.nearbyPlaces
                  .where((p) => p.category.toLowerCase().contains(name.toLowerCase().split(' ')[0]))
                  .take(3)
                  .toList();

              return _buildServiceCard(context, provider, name, icon, color, nearby);
            }),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, LocalExplorerProvider provider, String name, IconData icon, Color color, List<PlaceModel> nearby) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                if (nearby.isNotEmpty)
                  Text('${nearby.length} nearby', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontFamily: 'Poppins')),
              ],
            ),
          ),
          if (nearby.isNotEmpty)
            ...nearby.map((place) => InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PlaceDetailScreen(place: place),
              )),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: place.imageUrl ?? '',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(width: 48, height: 48, color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: Colors.grey[300], child: const Icon(Icons.image, size: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Row(
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.amber),
                              Text(' ${place.rating ?? '-'}  •  ${place.distance?.toStringAsFixed(1) ?? "-"} km', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontFamily: 'Poppins')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (place.isOpen == true) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text((place.isOpen == true) ? 'Open' : 'Closed', style: TextStyle(color: (place.isOpen == true) ? Colors.green : Colors.red, fontSize: 10, fontFamily: 'Poppins')),
                    ),
                  ],
                ),
              ),
            ))
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text('No nearby places found', style: TextStyle(color: Colors.grey[400], fontFamily: 'Poppins', fontSize: 13)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    provider.searchNearby(name.split(' ')[0]);
                  },
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Search Nearby', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
