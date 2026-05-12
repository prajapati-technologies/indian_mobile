import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/place_model.dart';

class OverpassService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';

  static const Map<String, List<String>> _categoryTags = {
    'hospital': ['["amenity"="hospital"]'],
    'police': ['["amenity"="police"]'],
    'pharmacy': ['["amenity"="pharmacy"]'],
    'petrol_pump': ['["amenity"="fuel"]'],
    'atm': ['["amenity"="atm"]'],
    'restaurant': ['["amenity"="restaurant"]'],
    'cafe': ['["amenity"="cafe"]'],
    'hotel': ['["tourism"="hotel"]'],
    'hostel': ['["tourism"="hostel"]'],
    'shopping_mall': ['["shop"="mall"]', '["shop"="shopping_mall"]'],
    'temple': ['["amenity"="place_of_worship"]["religion"="hindu"]', '["building"="temple"]'],
    'church': ['["amenity"="place_of_worship"]["religion"="christian"]', '["building"="church"]'],
    'mosque': ['["amenity"="place_of_worship"]["religion"="muslim"]', '["building"="mosque"]'],
    'gurudwara': ['["amenity"="place_of_worship"]["religion"="sikh"]', '["building"="gurudwara"]'],
    'tourist_attraction': ['["tourism"="attraction"]', '["tourism"="viewpoint"]', '["historic"="monument"]'],
    'park': ['["leisure"="park"]'],
    'cinema': ['["amenity"="cinema"]'],
    'gym': ['["leisure"="fitness_centre"]', '["amenity"="gym"]'],
    'school': ['["amenity"="school"]'],
    'college': ['["amenity"="college"]'],
    'library': ['["amenity"="library"]'],
    'salon': ['["shop"="hairdresser"]', '["shop"="beauty"]', '["shop"="hairdresser_supply"]'],
    'mechanic': ['["shop"="car_repair"]', '["amenity"="car_repair"]'],
    'grocery': ['["shop"="supermarket"]', '["shop"="grocery"]', '["shop"="convenience"]'],
    'mobile_phone_shop': ['["shop"="mobile_phone"]'],
    'courier': ['["amenity"="courier"]', '["amenity"="parcel_locker"]'],
    'pg/room': ['["tourism"="hostel"]["name"~"PG|pg|Paying Guest|paying guest",i]', '["amenity"="hostel"]["name"~"PG|pg|Paying Guest",i]'],
    'real_estate': ['["shop"="estate_agent"]', '["office"="real_estate"]'],
    'job': ['["office"="employment_agency"]', '["office"="recruitment"]'],
    'government_office': ['["office"="government"]', '["amenity"="public_building"]'],
    'bus_station': ['["amenity"="bus_station"]', '["highway"="bus_stop"]'],
    'railway_station': ['["railway"="station"]'],
    'bank': ['["amenity"="bank"]'],
    'market': ['["shop"="mall"]', '["amenity"="marketplace"]'],
  };

  static const List<String> _allCategories = [
    'hospital', 'police', 'pharmacy', 'atm', 'restaurant', 'cafe',
    'hotel', 'shopping_mall', 'temple', 'church', 'mosque', 'park',
    'bank', 'bus_station', 'railway_station', 'grocery', 'school',
  ];

  Future<List<PlaceModel>> searchNearby(
    double lat,
    double lng,
    String category, {
    int radius = 2000,
    int limit = 30,
  }) async {
    final tags = category == 'all' ? _allCategories : [category];
    final tagFilters = <String>[];

    for (final t in tags) {
      final tagList = _categoryTags[t] ?? _categoryTags['other'] ?? ['["amenity"~"."]'];
      for (final tg in tagList) {
        tagFilters.add(tg);
      }
    }

    if (tagFilters.isEmpty) return [];

    final unionParts = StringBuffer();
    for (final tag in tagFilters) {
      unionParts.writeln('  node$tag(around:$radius,$lat,$lng);');
      unionParts.writeln('  way$tag(around:$radius,$lat,$lng);');
    }

    final query = '''
[out:json][timeout:25];
(
${unionParts.toString().trim()}
);
out body $limit;
''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      );

      if (response.statusCode != 200) return [];

      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? [];
      final places = <PlaceModel>[];
      final seen = <String>{};

      for (final el in elements) {
        final place = PlaceModel.fromOverpassJson(el as Map<String, dynamic>, userLat: lat, userLng: lng);
        if (place.name == 'Unknown' || place.name.isEmpty) continue;
        if (seen.contains(place.id)) continue;
        seen.add(place.id);
        places.add(place);
        if (places.length >= limit) break;
      }

      places.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
      return places;
    } catch (_) {
      return [];
    }
  }

  Future<List<PlaceModel>> searchByText(
    String query,
    double lat,
    double lng, {
    int limit = 20,
  }) async {
    final places = <PlaceModel>[];
    final seen = <String>{};

    try {
      final overpassQuery = '''
[out:json][timeout:25];
(
  node["name"~"${_escapeRegex(query)}",i](around:5000,$lat,$lng);
  way["name"~"${_escapeRegex(query)}",i](around:5000,$lat,$lng);
);
out body $limit;
''';

      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': overpassQuery},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>? ?? [];

        for (final el in elements) {
          final place = PlaceModel.fromOverpassJson(el as Map<String, dynamic>, userLat: lat, userLng: lng);
          if (place.name == 'Unknown' || place.name.isEmpty) continue;
          if (seen.contains(place.id)) continue;
          seen.add(place.id);
          places.add(place);
          if (places.length >= limit) break;
        }
      }
    } catch (_) {}

    if (places.length < limit) {
      try {
        final nominatimUrl = Uri.parse(
          '$_nominatimUrl/search?q=${Uri.encodeQueryComponent(query)}'
          '&format=jsonv2&limit=${limit - places.length}&lat=$lat&lon=$lng'
          '&accept-language=en',
        );
        final nomResponse = await http.get(
          nominatimUrl,
          headers: {'User-Agent': 'IndianInformationApp/1.0'},
        );

        if (nomResponse.statusCode == 200) {
          final results = json.decode(utf8.decode(nomResponse.bodyBytes)) as List<dynamic>;
          for (final r in results) {
            final m = r as Map<String, dynamic>;
            final osmId = '${m['osm_type']?[0] ?? 'n'}${m['osm_id']}';
            if (seen.contains(osmId)) continue;
            seen.add(osmId);

            final cat = m['type'] as String? ?? m['category'] as String? ?? 'other';
            final place = PlaceModel(
              id: osmId,
              name: m['display_name']?.toString().split(',').first ?? 'Unknown',
              category: cat,
              lat: (m['lat'] as num).toDouble(),
              lng: (m['lon'] as num).toDouble(),
              address: m['display_name'] ?? '',
              distance: _haversine(lat, lng, (m['lat'] as num).toDouble(), (m['lon'] as num).toDouble()),
            );
            places.add(place);
            if (places.length >= limit) break;
          }
        }
      } catch (_) {}
    }

    return places;
  }

  Future<List<PlaceModel>> getFamousPlaces(String city, {int limit = 15}) async {
    final key = city.toLowerCase().trim();
    final data = _famousPlacesData[key];
    if (data == null) return [];
    final places = data.take(limit).toList();
    return places;
  }

  static String _escapeRegex(String s) {
    return s.replaceAll(RegExp(r'[.*+?^${}()|[\]\\]'), r'\$&');
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (r * c * 1000).roundToDouble() / 1000;
  }

  static double _toRadians(double deg) => deg * pi / 180;

  static final Map<String, List<PlaceModel>> _famousPlacesData = {
    'delhi': [
      PlaceModel(id: 'dl1', name: 'Red Fort', category: 'tourist_attraction', lat: 28.6562, lng: 77.2410, address: 'Netaji Subhash Marg, Chandni Chowk, Delhi', rating: 4.6, reviewsCount: 87500, openingHours: '9:30 AM – 4:30 PM (Tue–Sun)', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Red_Fort_in_Delhi_03.jpg/800px-Red_Fort_in_Delhi_03.jpg'),
      PlaceModel(id: 'dl2', name: 'Qutub Minar', category: 'tourist_attraction', lat: 28.5244, lng: 77.1855, address: 'Mehrauli, Delhi', rating: 4.7, reviewsCount: 72400, openingHours: '7:00 AM – 5:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Qutb_Minar_2011.jpg/800px-Qutb_Minar_2011.jpg'),
      PlaceModel(id: 'dl3', name: 'India Gate', category: 'tourist_attraction', lat: 28.6129, lng: 77.2295, address: 'Rajpath, Delhi', rating: 4.5, reviewsCount: 112300, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/India_Gate_in_New_Delhi_03.jpg/800px-India_Gate_in_New_Delhi_03.jpg'),
      PlaceModel(id: 'dl4', name: 'Akshardham Temple', category: 'temple', lat: 28.6127, lng: 77.2773, address: 'Noida Mor, Delhi', rating: 4.8, reviewsCount: 67800, openingHours: '9:30 AM – 6:30 PM (Tue–Sun)', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Akshardham_Delhi.jpg/800px-Akshardham_Delhi.jpg'),
      PlaceModel(id: 'dl5', name: 'Lotus Temple', category: 'temple', lat: 28.5535, lng: 77.2588, address: 'Kalkaji, Delhi', rating: 4.6, reviewsCount: 54300, openingHours: '9:00 AM – 5:30 PM (Tue–Sun)', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/Lotus_temple_Delhi_2018.jpg/800px-Lotus_temple_Delhi_2018.jpg'),
    ],
    'mumbai': [
      PlaceModel(id: 'mum1', name: 'Gateway of India', category: 'tourist_attraction', lat: 18.9220, lng: 72.8347, address: 'Apollo Bandar, Colaba, Mumbai', rating: 4.6, reviewsCount: 97600, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Gateway_of_India_%28photo_by_Aaryaman%29.jpg/800px-Gateway_of_India_%28photo_by_Aaryaman%29.jpg'),
      PlaceModel(id: 'mum2', name: 'Marine Drive', category: 'tourist_attraction', lat: 18.9440, lng: 72.8227, address: 'Marine Drive, Mumbai', rating: 4.7, reviewsCount: 83400, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Marine_Drive_skyline_2022.jpg/800px-Marine_Drive_skyline_2022.jpg'),
      PlaceModel(id: 'mum3', name: 'Chhatrapati Shivaji Terminus', category: 'railway_station', lat: 18.9398, lng: 72.8355, address: 'Fort, Mumbai', rating: 4.5, reviewsCount: 45600, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/CST_Building_%28cropped%29.jpg/800px-CST_Building_%28cropped%29.jpg'),
      PlaceModel(id: 'mum4', name: 'Siddhivinayak Temple', category: 'temple', lat: 19.0170, lng: 72.8300, address: 'Prabhadevi, Mumbai', rating: 4.7, reviewsCount: 51200, openingHours: '5:30 AM – 9:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Siddhivinayak_Temple_Mumbai.jpg/800px-Siddhivinayak_Temple_Mumbai.jpg'),
    ],
    'bangalore': [
      PlaceModel(id: 'blr1', name: 'Lalbagh Botanical Garden', category: 'park', lat: 12.9507, lng: 77.5848, address: 'Mavalli, Bengaluru', rating: 4.6, reviewsCount: 65400, openingHours: '6:00 AM – 7:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6c/Lal_Bagh_Glass_House_2018.jpg/800px-Lal_Bagh_Glass_House_2018.jpg'),
      PlaceModel(id: 'blr2', name: 'Bangalore Palace', category: 'tourist_attraction', lat: 12.9987, lng: 77.5920, address: 'Vasanth Nagar, Bengaluru', rating: 4.4, reviewsCount: 38900, openingHours: '10:00 AM – 5:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Bangalore_Palace_2018.jpg/800px-Bangalore_Palace_2018.jpg'),
      PlaceModel(id: 'blr3', name: 'Vidhana Soudha', category: 'government_office', lat: 12.9791, lng: 77.5913, address: 'Ambedkar Veedhi, Bengaluru', rating: 4.5, reviewsCount: 21500, openingHours: 'Exterior viewable anytime', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Vidhana_Soudha_2019.jpg/800px-Vidhana_Soudha_2019.jpg'),
      PlaceModel(id: 'blr4', name: 'Cubbon Park', category: 'park', lat: 12.9763, lng: 77.5929, address: 'Kasturba Road, Bengaluru', rating: 4.5, reviewsCount: 47800, openingHours: '6:00 AM – 6:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Cubbon_Park_2018.jpg/800px-Cubbon_Park_2018.jpg'),
    ],
    'hyderabad': [
      PlaceModel(id: 'hyd1', name: 'Charminar', category: 'tourist_attraction', lat: 17.3616, lng: 78.4747, address: 'Charminar, Hyderabad', rating: 4.6, reviewsCount: 78900, openingHours: '9:00 AM – 5:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Charminar_June_2022.jpg/800px-Charminar_June_2022.jpg'),
      PlaceModel(id: 'hyd2', name: 'Golconda Fort', category: 'tourist_attraction', lat: 17.3833, lng: 78.4011, address: 'Ibrahim Bagh, Hyderabad', rating: 4.5, reviewsCount: 54300, openingHours: '9:00 AM – 5:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Golconda_Fort_04.jpg/800px-Golconda_Fort_04.jpg'),
      PlaceModel(id: 'hyd3', name: 'Hussain Sagar Lake', category: 'park', lat: 17.4239, lng: 78.4737, address: 'Tank Bund, Hyderabad', rating: 4.4, reviewsCount: 34500, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Hussain_Sagar_at_Night.jpg/800px-Hussain_Sagar_at_Night.jpg'),
    ],
    'chennai': [
      PlaceModel(id: 'chn1', name: 'Marina Beach', category: 'park', lat: 13.0500, lng: 80.2824, address: 'Marina Beach, Chennai', rating: 4.5, reviewsCount: 89500, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Marina_Beach_Chennai_2018.jpg/800px-Marina_Beach_Chennai_2018.jpg'),
      PlaceModel(id: 'chn2', name: 'Kapaleeshwarar Temple', category: 'temple', lat: 13.0338, lng: 80.2685, address: 'Mylapore, Chennai', rating: 4.6, reviewsCount: 32400, openingHours: '5:00 AM – 12:00 PM, 4:00 PM – 9:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Kapaleeswarar_Temple_2018.jpg/800px-Kapaleeswarar_Temple_2018.jpg'),
      PlaceModel(id: 'chn3', name: 'Fort St. George', category: 'tourist_attraction', lat: 13.0797, lng: 80.2870, address: 'Fort St George, Chennai', rating: 4.3, reviewsCount: 18700, openingHours: '10:00 AM – 5:00 PM (Fri–Wed)', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Fort_St_George_Chennai.jpg/800px-Fort_St_George_Chennai.jpg'),
    ],
    'kolkata': [
      PlaceModel(id: 'kol1', name: 'Victoria Memorial', category: 'tourist_attraction', lat: 22.5448, lng: 88.3426, address: 'Maidan, Kolkata', rating: 4.7, reviewsCount: 61200, openingHours: '10:00 AM – 5:00 PM (Tue–Sun)', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Victoria_Memorial_Kolkata.jpg/800px-Victoria_Memorial_Kolkata.jpg'),
      PlaceModel(id: 'kol2', name: 'Howrah Bridge', category: 'tourist_attraction', lat: 22.5851, lng: 88.3469, address: 'Howrah, Kolkata', rating: 4.5, reviewsCount: 45600, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Howrah_Bridge_at_night.jpg/800px-Howrah_Bridge_at_night.jpg'),
      PlaceModel(id: 'kol3', name: 'Dakshineswar Kali Temple', category: 'temple', lat: 22.6555, lng: 88.3574, address: 'Dakshineswar, Kolkata', rating: 4.6, reviewsCount: 28900, openingHours: '5:00 AM – 9:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Dakshineswar_Temple_2018.jpg/800px-Dakshineswar_Temple_2018.jpg'),
    ],
    'jaipur': [
      PlaceModel(id: 'jai1', name: 'Hawa Mahal', category: 'tourist_attraction', lat: 26.9239, lng: 75.8267, address: 'Badi Chaupar, Jaipur', rating: 4.5, reviewsCount: 56700, openingHours: '9:00 AM – 4:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Hawa_Mahal_2018.jpg/800px-Hawa_Mahal_2018.jpg'),
      PlaceModel(id: 'jai2', name: 'Amber Fort', category: 'tourist_attraction', lat: 26.9855, lng: 75.8513, address: 'Amer, Jaipur', rating: 4.7, reviewsCount: 72400, openingHours: '8:00 AM – 5:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Amber_Fort_2018.jpg/800px-Amber_Fort_2018.jpg'),
      PlaceModel(id: 'jai3', name: 'City Palace Jaipur', category: 'tourist_attraction', lat: 26.9255, lng: 75.8237, address: 'Tripolia Bazar, Jaipur', rating: 4.6, reviewsCount: 41200, openingHours: '9:30 AM – 5:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/City_Palace_Jaipur_2018.jpg/800px-City_Palace_Jaipur_2018.jpg'),
      PlaceModel(id: 'jai4', name: 'Jantar Mantar', category: 'tourist_attraction', lat: 26.9249, lng: 75.8245, address: 'Gangori Bazaar, Jaipur', rating: 4.4, reviewsCount: 29800, openingHours: '9:00 AM – 4:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/Jantar_Mantar_Jaipur_2018.jpg/800px-Jantar_Mantar_Jaipur_2018.jpg'),
    ],
    'agra': [
      PlaceModel(id: 'agr1', name: 'Taj Mahal', category: 'tourist_attraction', lat: 27.1751, lng: 78.0421, address: 'Dharmapuri, Agra', rating: 4.8, reviewsCount: 134500, openingHours: '6:00 AM – 7:00 PM (Fri closed)', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/Taj_Mahal_2019.jpg/800px-Taj_Mahal_2019.jpg'),
      PlaceModel(id: 'agr2', name: 'Agra Fort', category: 'tourist_attraction', lat: 27.1797, lng: 78.0213, address: 'Mughal Road, Agra', rating: 4.6, reviewsCount: 58900, openingHours: '6:00 AM – 6:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Agra_Fort_2019.jpg/800px-Agra_Fort_2019.jpg'),
      PlaceModel(id: 'agr3', name: 'Fatehpur Sikri', category: 'tourist_attraction', lat: 27.0951, lng: 77.6675, address: 'Fatehpur Sikri, Uttar Pradesh', rating: 4.4, reviewsCount: 34500, openingHours: '6:00 AM – 6:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Fatehpur_Sikri_2018.jpg/800px-Fatehpur_Sikri_2018.jpg'),
    ],
    'varanasi': [
      PlaceModel(id: 'var1', name: 'Kashi Vishwanath Temple', category: 'temple', lat: 25.3109, lng: 83.0107, address: 'Vishwanath Gali, Varanasi', rating: 4.7, reviewsCount: 51200, openingHours: '2:30 AM – 11:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/58/Kashi_Vishwanath_Temple_2018.jpg/800px-Kashi_Vishwanath_Temple_2018.jpg'),
      PlaceModel(id: 'var2', name: 'Dashashwamedh Ghat', category: 'tourist_attraction', lat: 25.3067, lng: 83.0105, address: 'Dashashwamedh Ghat, Varanasi', rating: 4.6, reviewsCount: 43500, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Dashashwamedh_Ghat_Evening_Aarti.jpg/800px-Dashashwamedh_Ghat_Evening_Aarti.jpg'),
      PlaceModel(id: 'var3', name: 'Sarnath', category: 'tourist_attraction', lat: 25.3765, lng: 83.0230, address: 'Sarnath, Varanasi', rating: 4.4, reviewsCount: 25600, openingHours: '6:00 AM – 6:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Sarnath_Stupa_2018.jpg/800px-Sarnath_Stupa_2018.jpg'),
    ],
    'goa': [
      PlaceModel(id: 'goa1', name: 'Calangute Beach', category: 'park', lat: 15.5439, lng: 73.7550, address: 'Calangute, Goa', rating: 4.4, reviewsCount: 67800, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b3/Calangute_Beach_Goa.jpg/800px-Calangute_Beach_Goa.jpg'),
      PlaceModel(id: 'goa2', name: 'Basilica of Bom Jesus', category: 'church', lat: 15.5009, lng: 73.9117, address: 'Old Goa', rating: 4.6, reviewsCount: 28900, openingHours: '9:00 AM – 6:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Basilica_of_Bom_Jesus_2018.jpg/800px-Basilica_of_Bom_Jesus_2018.jpg'),
      PlaceModel(id: 'goa3', name: 'Fort Aguada', category: 'tourist_attraction', lat: 15.4929, lng: 73.7737, address: 'Sinquerim, Goa', rating: 4.3, reviewsCount: 32400, openingHours: '9:30 AM – 5:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Aguada_Fort_Goa_2018.jpg/800px-Aguada_Fort_Goa_2018.jpg'),
    ],
    'pune': [
      PlaceModel(id: 'pun1', name: 'Shaniwar Wada', category: 'tourist_attraction', lat: 18.5195, lng: 73.8553, address: 'Shaniwar Peth, Pune', rating: 4.4, reviewsCount: 43500, openingHours: '8:00 AM – 6:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Shaniwar_Wada_2018.jpg/800px-Shaniwar_Wada_2018.jpg'),
      PlaceModel(id: 'pun2', name: 'Aga Khan Palace', category: 'tourist_attraction', lat: 18.5521, lng: 73.9013, address: 'Kalyani Nagar, Pune', rating: 4.5, reviewsCount: 23400, openingHours: '9:00 AM – 5:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Aga_Khan_Palace_Pune.jpg/800px-Aga_Khan_Palace_Pune.jpg'),
      PlaceModel(id: 'pun3', name: 'Sinhagad Fort', category: 'tourist_attraction', lat: 18.3660, lng: 73.7555, address: 'Sinhagad, Pune', rating: 4.6, reviewsCount: 31200, openingHours: '5:00 AM – 7:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Sinhagad_Fort_2018.jpg/800px-Sinhagad_Fort_2018.jpg'),
    ],
    'ahmedabad': [
      PlaceModel(id: 'ahm1', name: 'Sabarmati Ashram', category: 'tourist_attraction', lat: 23.0608, lng: 72.5818, address: 'Sabarmati, Ahmedabad', rating: 4.6, reviewsCount: 38900, openingHours: '8:00 AM – 6:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Sabarmati_Ashram_2018.jpg/800px-Sabarmati_Ashram_2018.jpg'),
      PlaceModel(id: 'ahm2', name: 'Kankaria Lake', category: 'park', lat: 23.0103, lng: 72.6000, address: 'Kankaria, Ahmedabad', rating: 4.3, reviewsCount: 29800, openingHours: '9:00 AM – 10:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Kankaria_Lake_2019.jpg/800px-Kankaria_Lake_2019.jpg'),
      PlaceModel(id: 'ahm3', name: 'Adalaj Stepwell', category: 'tourist_attraction', lat: 23.0925, lng: 72.5956, address: 'Adalaj, Ahmedabad', rating: 4.4, reviewsCount: 18700, openingHours: '7:00 AM – 6:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/Adalaj_Stepwell_2018.jpg/800px-Adalaj_Stepwell_2018.jpg'),
    ],
    'lucknow': [
      PlaceModel(id: 'lck1', name: 'Bara Imambara', category: 'tourist_attraction', lat: 26.8691, lng: 80.9137, address: 'Husainabad, Lucknow', rating: 4.5, reviewsCount: 34500, openingHours: '8:30 AM – 5:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/Bara_Imambara_Lucknow.jpg/800px-Bara_Imambara_Lucknow.jpg'),
      PlaceModel(id: 'lck2', name: 'Chota Imambara', category: 'tourist_attraction', lat: 26.8712, lng: 80.9088, address: 'Husainabad, Lucknow', rating: 4.4, reviewsCount: 19800, openingHours: '8:30 AM – 5:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Chota_Imambara_Lucknow.jpg/800px-Chota_Imambara_Lucknow.jpg'),
      PlaceModel(id: 'lck3', name: 'Rumi Darwaza', category: 'tourist_attraction', lat: 26.8718, lng: 80.9132, address: 'Husainabad, Lucknow', rating: 4.3, reviewsCount: 15600, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Rumi_Darwaza_2018.jpg/800px-Rumi_Darwaza_2018.jpg'),
    ],
    'chandigarh': [
      PlaceModel(id: 'chd1', name: 'Rock Garden', category: 'park', lat: 30.7519, lng: 76.8056, address: 'Sector 1, Chandigarh', rating: 4.6, reviewsCount: 45600, openingHours: '9:00 AM – 7:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/Rock_Garden_Chandigarh_2018.jpg/800px-Rock_Garden_Chandigarh_2018.jpg'),
      PlaceModel(id: 'chd2', name: 'Sukhna Lake', category: 'park', lat: 30.7425, lng: 76.8100, address: 'Sector 1, Chandigarh', rating: 4.5, reviewsCount: 38900, openingHours: '5:00 AM – 9:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Sukhna_Lake_Chandigarh.jpg/800px-Sukhna_Lake_Chandigarh.jpg'),
      PlaceModel(id: 'chd3', name: 'Capitol Complex', category: 'government_office', lat: 30.7589, lng: 76.8050, address: 'Sector 1, Chandigarh', rating: 4.4, reviewsCount: 16700, openingHours: 'Exterior viewable anytime', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Chandigarh_Capitol_Complex_2018.jpg/800px-Chandigarh_Capitol_Complex_2018.jpg'),
    ],
    'amritsar': [
      PlaceModel(id: 'amr1', name: 'Golden Temple', category: 'gurudwara', lat: 31.6200, lng: 74.8765, address: 'Amritsar, Punjab', rating: 4.8, reviewsCount: 98700, openingHours: '24 hours', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Golden_Temple_2018.jpg/800px-Golden_Temple_2018.jpg'),
      PlaceModel(id: 'amr2', name: 'Jallianwala Bagh', category: 'tourist_attraction', lat: 31.6207, lng: 74.8790, address: 'Amritsar, Punjab', rating: 4.5, reviewsCount: 45600, openingHours: '6:00 AM – 5:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Jallianwala_Bagh_2018.jpg/800px-Jallianwala_Bagh_2018.jpg'),
      PlaceModel(id: 'amr3', name: 'Wagah Border', category: 'tourist_attraction', lat: 31.6048, lng: 74.5730, address: 'Wagah, Amritsar', rating: 4.6, reviewsCount: 34500, openingHours: '4:00 PM – 6:00 PM (ceremony)', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ef/Wagah_Border_2018.jpg/800px-Wagah_Border_2018.jpg'),
    ],
    'udaipur': [
      PlaceModel(id: 'udp1', name: 'City Palace Udaipur', category: 'tourist_attraction', lat: 24.5760, lng: 73.6834, address: 'City Palace, Udaipur', rating: 4.6, reviewsCount: 42300, openingHours: '9:30 AM – 5:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/City_Palace_Udaipur_2018.jpg/800px-City_Palace_Udaipur_2018.jpg'),
      PlaceModel(id: 'udp2', name: 'Lake Pichola', category: 'park', lat: 24.5718, lng: 73.6796, address: 'Udaipur, Rajasthan', rating: 4.7, reviewsCount: 38900, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Lake_Pichola_Udaipur.jpg/800px-Lake_Pichola_Udaipur.jpg'),
      PlaceModel(id: 'udp3', name: 'Jag Mandir', category: 'tourist_attraction', lat: 24.5667, lng: 73.6781, address: 'Lake Pichola, Udaipur', rating: 4.4, reviewsCount: 17800, openingHours: '10:00 AM – 5:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Jag_Mandir_Udaipur.jpg/800px-Jag_Mandir_Udaipur.jpg'),
    ],
    'kochi': [
      PlaceModel(id: 'koc1', name: 'Fort Kochi', category: 'tourist_attraction', lat: 9.9620, lng: 76.2430, address: 'Fort Kochi, Kochi', rating: 4.5, reviewsCount: 41200, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Fort_Kochi_2018.jpg/800px-Fort_Kochi_2018.jpg'),
      PlaceModel(id: 'koc2', name: 'Chinese Fishing Nets', category: 'tourist_attraction', lat: 9.9674, lng: 76.2429, address: 'Fort Kochi, Kochi', rating: 4.3, reviewsCount: 32400, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Chinese_Fishing_Nets_Kochi_2018.jpg/800px-Chinese_Fishing_Nets_Kochi_2018.jpg'),
      PlaceModel(id: 'koc3', name: 'Mattancherry Palace', category: 'tourist_attraction', lat: 9.9608, lng: 76.2541, address: 'Mattancherry, Kochi', rating: 4.2, reviewsCount: 15600, openingHours: '10:00 AM – 5:00 PM (Fri closed)', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Mattancherry_Palace_2018.jpg/800px-Mattancherry_Palace_2018.jpg'),
    ],
    'shimla': [
      PlaceModel(id: 'shm1', name: 'Mall Road', category: 'shopping_mall', lat: 31.1048, lng: 77.1734, address: 'Mall Road, Shimla', rating: 4.4, reviewsCount: 34500, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Mall_Road_Shimla_2018.jpg/800px-Mall_Road_Shimla_2018.jpg'),
      PlaceModel(id: 'shm2', name: 'Jakhu Temple', category: 'temple', lat: 31.1016, lng: 77.1816, address: 'Jakhu Hill, Shimla', rating: 4.3, reviewsCount: 17800, openingHours: '6:00 AM – 8:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Jakhu_Temple_Shimla.jpg/800px-Jakhu_Temple_Shimla.jpg'),
      PlaceModel(id: 'shm3', name: 'Kufri', category: 'park', lat: 31.1162, lng: 77.2648, address: 'Kufri, Shimla', rating: 4.2, reviewsCount: 23400, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Kufri_Shimla_2018.jpg/800px-Kufri_Shimla_2018.jpg'),
    ],
    'rishikesh': [
      PlaceModel(id: 'rsh1', name: 'Laxman Jhula', category: 'tourist_attraction', lat: 30.1245, lng: 78.3195, address: 'Rishikesh, Uttarakhand', rating: 4.4, reviewsCount: 34500, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/Laxman_Jhula_Rishikesh_2018.jpg/800px-Laxman_Jhula_Rishikesh_2018.jpg'),
      PlaceModel(id: 'rsh2', name: 'Triveni Ghat', category: 'tourist_attraction', lat: 30.1189, lng: 78.3183, address: 'Rishikesh, Uttarakhand', rating: 4.3, reviewsCount: 19800, openingHours: 'Always open', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Triveni_Ghat_Rishikesh.jpg/800px-Triveni_Ghat_Rishikesh.jpg'),
      PlaceModel(id: 'rsh3', name: 'Beatles Ashram', category: 'tourist_attraction', lat: 30.1315, lng: 78.3375, address: 'Rishikesh, Uttarakhand', rating: 4.2, reviewsCount: 12300, openingHours: '9:00 AM – 5:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Beatles_Ashram_Rishikesh.jpg/800px-Beatles_Ashram_Rishikesh.jpg'),
    ],
    'mysore': [
      PlaceModel(id: 'mys1', name: 'Mysore Palace', category: 'tourist_attraction', lat: 12.3052, lng: 76.6554, address: 'Mysore, Karnataka', rating: 4.7, reviewsCount: 67800, openingHours: '10:00 AM – 5:30 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Mysore_Palace_2018.jpg/800px-Mysore_Palace_2018.jpg'),
      PlaceModel(id: 'mys2', name: 'Chamundi Hill Temple', category: 'temple', lat: 12.2719, lng: 76.6690, address: 'Chamundi Hill, Mysore', rating: 4.5, reviewsCount: 31200, openingHours: '7:30 AM – 9:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Chamundeshwari_Temple_2018.jpg/800px-Chamundeshwari_Temple_2018.jpg'),
      PlaceModel(id: 'mys3', name: 'Brindavan Gardens', category: 'park', lat: 12.4239, lng: 76.6935, address: 'Krishnarajasagara, Mysore', rating: 4.4, reviewsCount: 24500, openingHours: '6:30 AM – 8:00 PM', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Brindavan_Gardens_2018.jpg/800px-Brindavan_Gardens_2018.jpg'),
    ],
  };
}
