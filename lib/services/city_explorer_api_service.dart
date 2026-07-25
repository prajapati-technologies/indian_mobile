import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service for all City Explorer backend API calls.
///
/// Base URL should be: `{webOrigin}/api/v1/city-explorer`
/// e.g. https://indiainformations.com/api/v1/city-explorer
class CityExplorerApiService {
  CityExplorerApiService(this.baseUrl);

  final String baseUrl;

  static const Duration _timeout = Duration(seconds: 20);

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final cleanBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$cleanBase/$p');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<dynamic> _get(String path, [Map<String, String>? queryParams]) async {
    try {
      final response = await http
          .get(_uri(path, queryParams), headers: _headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(_uri(path), headers: _headers, body: json.encode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _wrapError(e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded is Map
        ? (decoded['error'] ?? decoded['message'] ?? 'Unknown error')
        : 'Request failed';
    throw CityExplorerApiException(response.statusCode, message.toString());
  }

  Exception _wrapError(dynamic e) {
    if (e is CityExplorerApiException) return e;
    final msg = e.toString();
    if (msg.contains('TimeoutException') ||
        msg.contains('SocketException') ||
        msg.contains('ClientException') ||
        msg.contains('Connection refused')) {
      return CityExplorerApiException(0, 'Could not connect to server. Check your internet connection.');
    }
    return CityExplorerApiException(0, msg);
  }

  // ─── Geography ─────────────────────────────────────────────────────────────

  /// Get all countries.
  Future<List<dynamic>> getCountries() async {
    final res = await _get('countries');
    return (res['data'] as List<dynamic>?) ?? [];
  }

  /// Get states in a country.
  Future<List<dynamic>> getStates(int countryId) async {
    final res = await _get('countries/$countryId/states');
    return (res['data'] as List<dynamic>?) ?? [];
  }

  /// Get districts in a state.
  Future<List<dynamic>> getDistricts(int stateId) async {
    final res = await _get('states/$stateId/districts');
    return (res['data'] as List<dynamic>?) ?? [];
  }

  /// Get cities in a district.
  Future<List<dynamic>> getCitiesInDistrict(int districtId) async {
    final res = await _get('districts/$districtId/cities');
    return (res['data'] as List<dynamic>?) ?? [];
  }

  /// Flatten geography to get all active cities across all districts/states.
  /// Traverses country → states → districts → cities.
  Future<List<dynamic>> getAllCities({int countryId = 1}) async {
    final allCities = <dynamic>[];
    try {
      final states = await getStates(countryId);
      for (final state in states) {
        final stateId = state['id'] as int;
        final districts = await getDistricts(stateId);
        for (final district in districts) {
          final districtId = district['id'] as int;
          final cities = await getCitiesInDistrict(districtId);
          allCities.addAll(cities);
        }
      }
    } catch (_) {
      // Return whatever we got
    }
    return allCities;
  }

  // ─── City Detail ───────────────────────────────────────────────────────────

  /// Get city detail with categories.
  /// Returns: { data: { id, name, slug, description, image, categories: [...] } }
  Future<Map<String, dynamic>> getCityDetail(String slug) async {
    final res = await _get('cities/$slug');
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  // ─── Places ────────────────────────────────────────────────────────────────

  /// Get places list for a city + category (with sponsored/featured/normal).
  /// Returns the full response including data.sponsored, data.featured, data.normal, meta.
  Future<Map<String, dynamic>> getPlaces(
    String citySlug,
    String categorySlug, {
    int page = 1,
    int perPage = 20,
  }) async {
    final res = await _get(
      'cities/$citySlug/places/$categorySlug',
      {'page': page.toString(), 'per_page': perPage.toString()},
    );
    return res as Map<String, dynamic>;
  }

  /// Get single place detail.
  /// Returns: { data: { id, name, slug, ... } }
  Future<Map<String, dynamic>> getPlaceDetail(String slug) async {
    final res = await _get('places/$slug');
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  /// Search places within a city.
  /// Returns list of place summaries.
  Future<List<dynamic>> search(String query, {String? citySlug, String? categorySlug}) async {
    final params = <String, String>{'q': query};
    if (citySlug != null && citySlug.isNotEmpty) params['city'] = citySlug;
    if (categorySlug != null && categorySlug.isNotEmpty) params['category'] = categorySlug;
    final res = await _get('search', params);
    return (res['data'] as List<dynamic>?) ?? [];
  }

  // ─── Leads ─────────────────────────────────────────────────────────────────

  /// Submit an enquiry (lead). Returns OTP reference data.
  Future<Map<String, dynamic>> submitEnquiry(Map<String, dynamic> data) async {
    final res = await _post('leads/enquiry', data);
    return res as Map<String, dynamic>;
  }

  /// Verify OTP for a lead submission.
  Future<Map<String, dynamic>> verifyOtp(String otpReference, String otp) async {
    final res = await _post('leads/verify-otp', {
      'otp_reference': otpReference,
      'otp': otp,
    });
    return res as Map<String, dynamic>;
  }

  /// Resend OTP.
  Future<Map<String, dynamic>> resendOtp(String otpReference) async {
    final res = await _post('leads/resend-otp', {
      'otp_reference': otpReference,
    });
    return res as Map<String, dynamic>;
  }

  // ─── Reviews ───────────────────────────────────────────────────────────────

  /// Submit a review for a place.
  Future<Map<String, dynamic>> submitReview(Map<String, dynamic> data) async {
    final res = await _post('reviews', data);
    return res as Map<String, dynamic>;
  }
}

/// Exception thrown by [CityExplorerApiService] on API errors.
class CityExplorerApiException implements Exception {
  CityExplorerApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  /// Whether the resource was not found (404).
  bool get isNotFound => statusCode == 404;

  /// Whether validation failed (422).
  bool get isValidation => statusCode == 422;

  /// Whether rate limited (429).
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => 'CityExplorerApiException($statusCode): $message';
}
