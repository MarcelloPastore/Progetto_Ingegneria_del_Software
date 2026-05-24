import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';

class ApiException implements Exception {
  ApiException({required this.statusCode, this.body});

  final int statusCode;
  final String? body;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, body: $body)';
}

class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
    : baseUrl = baseUrl ?? Env.baseUrl,
      _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Uri buildUri(String path, [Map<String, String>? queryParameters]) {
    final merged = _mergePath(baseUrl, path);
    final uri = Uri.parse(merged);

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: queryParameters);
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    return _send('GET', path, queryParameters: queryParameters);
  }

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    return _send('POST', path, body: body, queryParameters: queryParameters);
  }

  Future<dynamic> putJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    return _send('PUT', path, body: body, queryParameters: queryParameters);
  }

  Future<dynamic> patchJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    return _send('PATCH', path, body: body, queryParameters: queryParameters);
  }

  Future<dynamic> deleteJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    return _send('DELETE', path, body: body, queryParameters: queryParameters);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = buildUri(path, queryParameters);
    final headers = <String, String>{'Accept': 'application/json'};

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_authToken!}';
    }

    final encodedBody = body == null ? null : jsonEncode(body);
    late http.Response response;

    switch (method) {
      case 'GET':
        response = await _httpClient.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _httpClient.post(
          uri,
          headers: headers,
          body: encodedBody,
        );
        break;
      case 'PUT':
        response = await _httpClient.put(
          uri,
          headers: headers,
          body: encodedBody,
        );
        break;
      case 'PATCH':
        response = await _httpClient.patch(
          uri,
          headers: headers,
          body: encodedBody,
        );
        break;
      case 'DELETE':
        response = await _httpClient.delete(
          uri,
          headers: headers,
          body: encodedBody,
        );
        break;
      default:
        throw ArgumentError('Unsupported method: $method');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(statusCode: response.statusCode, body: response.body);
    }

    if (response.body.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    return _extractData(decoded);
  }

  dynamic _extractData(dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  String _mergePath(String base, String path) {
    if (base.endsWith('/') && path.startsWith('/')) {
      return base + path.substring(1);
    }
    if (!base.endsWith('/') && !path.startsWith('/')) {
      return '$base/$path';
    }
    return base + path;
  }
}
