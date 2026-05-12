import 'dart:math';

class PlaceModel {
  final String id;
  final String name;
  final String category;
  final String subcategory;
  final double lat;
  final double lng;
  final String address;
  final String? phone;
  final String? website;
  final double? rating;
  final int? reviewsCount;
  final String? openingHours;
  final bool? isOpen;
  final double? distance;
  final String? imageUrl;
  final String? tags;
  bool isFavorite;
  final String? placeId;
  final DateTime? lastUpdated;

  PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory = '',
    required this.lat,
    required this.lng,
    this.address = '',
    this.phone,
    this.website,
    this.rating,
    this.reviewsCount,
    this.openingHours,
    this.isOpen,
    this.distance,
    this.imageUrl,
    this.tags,
    this.isFavorite = false,
    this.placeId,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'subcategory': subcategory,
    'lat': lat,
    'lng': lng,
    'address': address,
    'phone': phone,
    'website': website,
    'rating': rating,
    'reviewsCount': reviewsCount,
    'openingHours': openingHours,
    'isOpen': isOpen,
    'distance': distance,
    'imageUrl': imageUrl,
    'tags': tags,
    'isFavorite': isFavorite,
    'placeId': placeId,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] ?? '',
      phone: json['phone'],
      website: json['website'],
      rating: json['rating']?.toDouble(),
      reviewsCount: json['reviewsCount'] as int?,
      openingHours: json['openingHours'],
      isOpen: json['isOpen'] as bool?,
      distance: json['distance']?.toDouble(),
      imageUrl: json['imageUrl'],
      tags: json['tags'],
      isFavorite: json['isFavorite'] ?? false,
      placeId: json['placeId'],
      lastUpdated: json['lastUpdated'] != null ? DateTime.tryParse(json['lastUpdated']) : null,
    );
  }

  factory PlaceModel.fromOverpassJson(Map<String, dynamic> json, {double? userLat, double? userLng}) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};
    final lat = (json['lat'] as num?)?.toDouble() ?? 0;
    final lng = (json['lon'] as num?)?.toDouble() ?? 0;
    final double? dist;
    if (userLat != null && userLng != null && lat != 0 && lng != 0) {
      dist = _haversine(userLat, userLng, lat, lng);
    } else {
      dist = null;
    }

    final category = _inferCategory(tags);

    return PlaceModel(
      id: json['id'].toString(),
      name: tags['name'] ?? tags['name:en'] ?? 'Unknown',
      category: category,
      subcategory: tags['amenity'] ?? tags['shop'] ?? tags['tourism'] ?? tags['leisure'] ?? '',
      lat: lat,
      lng: lng,
      address: [
        tags['addr:full'], tags['addr:street'], tags['addr:city']
      ].whereType<String>().join(', '),
      phone: tags['phone'] ?? tags['contact:phone'],
      website: tags['website'] ?? tags['contact:website'],
      rating: tags['rating'] != null ? double.tryParse(tags['rating'].toString()) : null,
      reviewsCount: tags['reviews'] != null ? int.tryParse(tags['reviews'].toString()) : null,
      openingHours: tags['opening_hours'],
      isOpen: null,
      distance: dist != null ? (dist * 1000).roundToDouble() / 1000 : null,
      imageUrl: tags['image'] ?? tags['wikimedia_commons'],
      tags: tags.entries.map((e) => '${e.key}=${e.value}').join(', '),
      placeId: json['id'].toString(),
      lastUpdated: DateTime.now(),
    );
  }

  static String _inferCategory(Map<String, dynamic> tags) {
    if (tags['amenity'] == 'hospital') return 'hospital';
    if (tags['amenity'] == 'police') return 'police';
    if (tags['amenity'] == 'pharmacy') return 'pharmacy';
    if (tags['amenity'] == 'fuel') return 'petrol_pump';
    if (tags['amenity'] == 'atm') return 'atm';
    if (tags['amenity'] == 'restaurant') return 'restaurant';
    if (tags['amenity'] == 'cafe') return 'cafe';
    if (tags['tourism'] == 'hotel') return 'hotel';
    if (tags['tourism'] == 'hostel') return 'hostel';
    if (tags['shop'] == 'mall') return 'shopping_mall';
    if (tags['amenity'] == 'place_of_worship') {
      final rel = tags['religion'];
      if (rel == 'hindu') return 'temple';
      if (rel == 'christian') return 'church';
      if (rel == 'muslim') return 'mosque';
      if (rel == 'sikh') return 'gurudwara';
    }
    if (tags['building'] == 'temple' || tags['temple'] == 'yes') return 'temple';
    if (tags['building'] == 'church' || tags['church'] == 'yes') return 'church';
    if (tags['building'] == 'mosque' || tags['mosque'] == 'yes') return 'mosque';
    if (tags['tourism'] == 'attraction' || tags['tourism'] == 'viewpoint') return 'tourist_attraction';
    if (tags['historic'] != null && tags['historic']!.isNotEmpty) return 'tourist_attraction';
    if (tags['leisure'] == 'park') return 'park';
    if (tags['amenity'] == 'cinema') return 'cinema';
    if (tags['leisure'] == 'fitness_centre' || tags['amenity'] == 'gym') return 'gym';
    if (tags['amenity'] == 'school') return 'school';
    if (tags['amenity'] == 'college') return 'college';
    if (tags['amenity'] == 'library') return 'library';
    if (tags['shop'] == 'hairdresser' || tags['shop'] == 'beauty') return 'salon';
    if (tags['shop'] == 'car_repair') return 'mechanic';
    if (tags['shop'] == 'supermarket' || tags['shop'] == 'grocery') return 'grocery';
    if (tags['shop'] == 'mobile_phone') return 'mobile_phone_shop';
    if (tags['amenity'] == 'courier' || tags['amenity'] == 'parcel_locker') return 'courier';
    if (tags['shop'] == 'estate_agent') return 'real_estate';
    if (tags['office'] == 'employment_agency') return 'job';
    if (tags['office'] == 'government') return 'government_office';
    if (tags['amenity'] == 'bus_station') return 'bus_station';
    if (tags['railway'] == 'station') return 'railway_station';
    if (tags['amenity'] == 'bank') return 'bank';
    if (tags['amenity'] == 'marketplace') return 'market';
    return tags['amenity'] ?? tags['shop'] ?? tags['tourism'] ?? tags['leisure'] ?? 'other';
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double deg) => deg * pi / 180;

  PlaceModel copyWith({
    String? id,
    String? name,
    String? category,
    String? subcategory,
    double? lat,
    double? lng,
    String? address,
    String? phone,
    String? website,
    double? rating,
    int? reviewsCount,
    String? openingHours,
    bool? isOpen,
    double? distance,
    String? imageUrl,
    String? tags,
    bool? isFavorite,
    String? placeId,
    DateTime? lastUpdated,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      openingHours: openingHours ?? this.openingHours,
      isOpen: isOpen ?? this.isOpen,
      distance: distance ?? this.distance,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      placeId: placeId ?? this.placeId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class CityInfo {
  final String city;
  final String state;
  final String country;
  final double lat;
  final double lng;
  final String? displayName;
  final String? imageUrl;

  CityInfo({
    required this.city,
    required this.state,
    this.country = 'India',
    required this.lat,
    required this.lng,
    this.displayName,
    this.imageUrl,
  });

  factory CityInfo.fromNominatimJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    String city = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['municipality'] ??
        address['county'] ??
        '';
    String state = address['state'] ?? '';
    String country = address['country'] ?? 'India';

    return CityInfo(
      city: city,
      state: state,
      country: country,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lon'] as num?)?.toDouble() ?? 0,
      displayName: json['display_name'],
      imageUrl: null,
    );
  }
}
