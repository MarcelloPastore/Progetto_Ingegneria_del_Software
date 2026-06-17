import 'package:dio/dio.dart';
import 'package:coincasa_app/app.dart';
import 'package:coincasa_app/core/widgets/common/no_connection_screen.dart';
import 'package:coincasa_app/core/widgets/common/no_internet_dialog.dart';
import 'package:coincasa_app/domain/value_objects/ruolo_casa.dart';

import '../config/env.dart';

class ApiException implements Exception {
  ApiException({required this.statusCode, this.body});

  final int statusCode;
  final String? body;

  @override
  String toString() => 'ApiException(statusCode: $statusCode, body: $body)';
}

class ApiClient {
  ApiClient({String? baseUrl, Dio? dio})
      : baseUrl = baseUrl ?? Env.baseUrl {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: this.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            headers: const {'Accept': 'application/json'},
            // Accetta tutti i codici di stato: li gestiamo manualmente
            validateStatus: (_) => true,
          ),
        );
    _dio.interceptors.add(_authInterceptor());
  }

  final String baseUrl;
  late final Dio _dio;

  String? _authToken;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserDisplayName;
  String? _currentUserFirstName;
  String? _currentUserLastName;
  String? _currentUserAvatarSeed;
  String? _currentUserUsername;
  String? _currentCasaId;
  String? _currentCasaRuolo;

  // ── Interceptor autenticazione ───────────────────────────────────────────

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null && _authToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) {
        switch (error.type) {
          case DioExceptionType.connectionError:
            NoInternetDialog.show();
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            _handleConnectionError();
          default:
            break;
        }
        handler.next(error);
      },
    );
  }

  // ── Sessione ─────────────────────────────────────────────────────────────

  void setAuthToken(String? token) => _authToken = token;

  void setCurrentUserIdentity({
    String? id,
    String? email,
    String? name,
    String? surname,
    String? displayName,
    String? username,
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
    if (username != null) {
      final normalized = username.trim();
      _currentUserUsername = normalized.isEmpty ? null : normalized;
    }

    final fullName = [_currentUserFirstName, _currentUserLastName]
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .join(' ')
        .trim();

    if (fullName.isNotEmpty) {
      _currentUserDisplayName = fullName;
      return;
    }

    final normalizedDisplay = displayName?.trim() ?? '';
    if (normalizedDisplay.isNotEmpty) {
      _currentUserDisplayName = normalizedDisplay;
      return;
    }

    final emailLocal = _currentUserEmail?.split('@').first.trim() ?? '';
    _currentUserDisplayName = emailLocal.isNotEmpty ? emailLocal : null;
  }

  void setCasaContext({required String casaId, required String ruolo}) {
    _currentCasaId = casaId.trim().isEmpty ? null : casaId.trim();
    _currentCasaRuolo = ruolo.trim().isEmpty ? null : ruolo.trim();
  }

  void clearCasaContext() {
    _currentCasaId = null;
    _currentCasaRuolo = null;
  }

  void clearSession() {
    _authToken = null;
    _currentUserId = null;
    _currentUserEmail = null;
    _currentUserDisplayName = null;
    _currentUserFirstName = null;
    _currentUserLastName = null;
    _currentUserAvatarSeed = null;
    _currentUserUsername = null;
    clearCasaContext();
  }

  String? get authToken => _authToken;
  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserDisplayName;
  String? get currentUserDisplayName => _currentUserDisplayName;
  String? get currentUserFirstName => _currentUserFirstName;
  String? get currentUserLastName => _currentUserLastName;
  String? get currentUserAvatarSeed => _currentUserAvatarSeed;
  String? get currentUserUsername => _currentUserUsername;
  String? get currentCasaId => _currentCasaId;
  String? get currentCasaRuolo => _currentCasaRuolo;
  bool get isHomeAdmin => RuoloCasa.isAdmin(_currentCasaRuolo);

  // ── Metodi HTTP pubblici ─────────────────────────────────────────────────

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) =>
      _send('GET', path, queryParameters: queryParameters);

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) =>
      _send('POST', path, body: body, queryParameters: queryParameters);

  Future<dynamic> putJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) =>
      _send('PUT', path, body: body, queryParameters: queryParameters);

  Future<dynamic> patchJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) =>
      _send('PATCH', path, body: body, queryParameters: queryParameters);

  Future<dynamic> deleteJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) =>
      _send('DELETE', path, body: body, queryParameters: queryParameters);

  // ── Internals ────────────────────────────────────────────────────────────

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          contentType:
              body != null ? 'application/json' : null,
        ),
      );
      return _processResponse(response);
    } on DioException catch (e) {
      // L'interceptor onError ha già gestito no-internet / timeout.
      // Rilanciamo come ApiException se c'è una risposta HTTP.
      if (e.response != null) {
        throw ApiException(
          statusCode: e.response!.statusCode ?? 0,
          body: e.response!.data?.toString(),
        );
      }
      rethrow;
    }
  }

  dynamic _processResponse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw ApiException(
        statusCode: status,
        body: response.data?.toString(),
      );
    }
    if (response.data == null) return null;
    return _extractData(response.data);
  }

  dynamic _extractData(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  void _handleConnectionError() {
    if (!NoConnectionScreen.isShowing) {
      navigatorKey.currentState?.pushNamed(NoConnectionScreen.routeName);
    }
  }

  /// Esposto per compatibilità con codice esistente che costruisce URI custom.
  Uri buildUri(String path, [Map<String, String>? queryParameters]) {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final p = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$base$p');
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(queryParameters: queryParameters);
  }
}
