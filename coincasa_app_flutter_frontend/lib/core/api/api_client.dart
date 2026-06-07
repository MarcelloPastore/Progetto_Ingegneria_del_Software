import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:coincasa_app/app.dart';
import 'package:coincasa_app/core/widgets/common/no_connection_screen.dart';

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
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserDisplayName;
  String? _currentUserFirstName;
  String? _currentUserLastName;
  String? _currentUserAvatarSeed;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setCurrentUserIdentity({
    String? id,
    String? email,
    String? name,
    String? surname,
    String? displayName,
  }) {
    if (id != null) {
      final normalized = id.trim();
      _currentUserId = normalized.isEmpty ? null : normalized;
      _currentUserAvatarSeed = _currentUserId;
    }
    if (email != null) {
      final normalized = email.trim().toLowerCase();
      _currentUserEmail = normalized.isEmpty ? null : normalized;
    }
    if (name != null) {
      final normalized = name.trim();
      _currentUserFirstName = normalized.isEmpty ? null : normalized;
    }
    if (surname != null) {
      final normalized = surname.trim();
      _currentUserLastName = normalized.isEmpty ? null : normalized;
    }

    final fullName = [
      _currentUserFirstName,
      _currentUserLastName,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ').trim();

    if (fullName.isNotEmpty) {
      _currentUserDisplayName = fullName;
      return;
    }

    final normalizedDisplayName = displayName?.trim() ?? '';
    if (normalizedDisplayName.isNotEmpty) {
      _currentUserDisplayName = normalizedDisplayName;
      return;
    }

    final emailLocalPart = _currentUserEmail?.split('@').first.trim() ?? '';
    _currentUserDisplayName = emailLocalPart.isNotEmpty ? emailLocalPart : null;
  }

  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserDisplayName;
  String? get currentUserDisplayName => _currentUserDisplayName;
  String? get currentUserFirstName => _currentUserFirstName;
  String? get currentUserLastName => _currentUserLastName;
  String? get currentUserAvatarSeed => _currentUserAvatarSeed;

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

    try {
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
    } catch (e) {
      _handleConnectionError();
      rethrow;
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

  void _handleConnectionError() {
    if (!NoConnectionScreen.isShowing) {
      navigatorKey.currentState?.pushNamed(NoConnectionScreen.routeName);
    }
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
