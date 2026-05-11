import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}

/// Thrown when the device cannot reach the server (timeout, DNS, refused, wrong IP).
class ApiConnectionException implements Exception {
  ApiConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService(this.baseUrl);

  final String baseUrl;

  static const Duration _timeout = Duration(seconds: 20);

  Uri _uri(String path) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$cleanBase/$p');
  }

  Map<String, String> _headers(String? token, {bool jsonBody = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (jsonBody) {
      h['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  dynamic _decode(http.Response r) {
    final body = r.body;
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (body.isEmpty) {
        return null;
      }
      return json.decode(utf8.decode(r.bodyBytes));
    }
    throw ApiException(r.statusCode, body);
  }

  Future<T> _run<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiConnectionException(
        'Request timed out after ${_timeout.inSeconds}s.\n\n'
        'On a physical device the default URL (10.0.2.2) usually does not work.\n'
        'In Account → "Server URL", save your PC\'s API address '
        '(same Wi‑Fi), or when running:\n'
        'flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP/.../public/api',
      );
    } catch (e) {
      final t = e.toString();
      if (t.contains('SocketException') ||
          t.contains('ClientException') ||
          t.contains('Failed host lookup') ||
          t.contains('Connection refused') ||
          t.contains('Network is unreachable') ||
          t.contains('HandshakeException')) {
        throw ApiConnectionException(
          'Could not reach the server.\n$t\n\n'
          'Set the correct API base (…/public/api) under Account → Server URL.',
        );
      }
      rethrow;
    }
  }

  Future<dynamic> getJson(String path, {String? token}) async {
    return _run(() async {
      final r = await http.get(_uri(path), headers: _headers(token));
      return _decode(r);
    });
  }

  Future<dynamic> postJson(
    String path,
    Map<String, dynamic>? body, {
    String? token,
  }) async {
    return _run(() async {
      final r = await http.post(
        _uri(path),
        headers: _headers(token, jsonBody: true),
        body: body == null ? null : json.encode(body),
      );
      return _decode(r);
    });
  }

  Future<dynamic> postMultipart(
    String path,
    Map<String, String> fields, {
    String? token,
    List<http.MultipartFile>? files,
  }) async {
    return _run(() async {
      final request = http.MultipartRequest('POST', _uri(path));
      
      final h = _headers(token);
      request.headers.addAll(h);
      request.fields.addAll(fields);
      
      if (files != null) {
        request.files.addAll(files);
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _decode(response);
    });
  }
}
