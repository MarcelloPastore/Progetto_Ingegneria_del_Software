import 'api_client.dart';

class AuthLoginResult {
  const AuthLoginResult({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.nome,
    required this.cognome,
  });

  final String id;
  final String username;
  final String nome;
  final String cognome;

  String get displayName {
    final parts = [nome, cognome].where((part) => part.trim().isNotEmpty);
    final fullName = parts.join(' ').trim();
    return fullName.isNotEmpty ? fullName : username;
  }
}

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthLoginResult> login({
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

    final user = _extractUser(data);
    if (user == null) {
      throw const FormatException('Missing user data in response.');
    }

    return AuthLoginResult(token: token, user: user);
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

  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    await _client.postJson(
      '/auth/verifica-codice-recupero',
      body: {'email': email, 'codice': code},
    );
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
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.postJson(
      '/auth/reset-password',
      body: {'email': email, 'codice': code, 'nuovaPassword': newPassword},
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

  AuthUser? _extractUser(dynamic data) {
    if (data is Map<String, dynamic>) {
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final id = user['id'];
        if (id is! String || id.trim().isEmpty) {
          return null;
        }

        return AuthUser(
          id: id,
          username: user['username']?.toString() ?? '',
          nome: user['nome']?.toString() ?? '',
          cognome: user['cognome']?.toString() ?? '',
        );
      }
    }

    return null;
  }
}
