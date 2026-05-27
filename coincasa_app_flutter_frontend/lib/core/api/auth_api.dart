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
    required String username,
    required String nome,
    required String cognome,
    required String email,
    required String password,
  }) async {
    await _client.postJson(
      '/auth/register',
      body: {
        'email': email,
        'username': username,
        'password': password,
        'nome': nome,
        'cognome': cognome,
      },
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.postJson('/auth/recupera-password', body: {'email': email});
  }

  Future<String?> verifyEmail(String email) async {
    final data = await _client.postJson(
      '/auth/verifica-email',
      body: {'email': email},
    );

    if (data is Map<String, dynamic>) {
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final nome = user['nome'] ?? user['name'];
        if (nome is String) {
          return nome;
        }
      }
    }

    return null;
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
