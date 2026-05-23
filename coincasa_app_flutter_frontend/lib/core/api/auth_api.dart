import 'api_client.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.postJson(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    final token = _extractToken(data);
    if (token == null) {
      throw const FormatException('Missing access token in response.');
    }

    return token;
  }

  Future<void> register({
    required String nome,
    required String email,
    required String password,
  }) async {
    await _client.postJson(
      '/auth/register',
      body: {'nome': nome, 'email': email, 'password': password},
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.postJson('/auth/recupera-password', body: {'email': email});
  }

  Future<void> verifyEmail(String token) async {
    await _client.getJson(
      '/auth/verifica-email',
      queryParameters: {'token': token},
    );
  }

  Future<String> refreshToken(String refreshToken) async {
    final data = await _client.postJson(
      '/auth/refresh-token',
      body: {'refreshToken': refreshToken},
    );

    final token = _extractToken(data);
    if (token == null) {
      throw const FormatException('Missing access token in response.');
    }

    return token;
  }

  Future<void> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    await _client.postJson(
      '/auth/reset-password',
      body: {'code': code, 'password': newPassword},
    );
  }

  String? _extractToken(dynamic data) {
    if (data is String) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final token =
          data['token'] ?? data['accessToken'] ?? data['access_token'];
      if (token is String) {
        return token;
      }
    }
    return null;
  }
}
