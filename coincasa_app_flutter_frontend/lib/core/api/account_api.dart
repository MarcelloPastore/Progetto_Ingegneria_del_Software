import 'api_client.dart';

class AccountApi {
  AccountApi(this._client);

  final ApiClient _client;

  /// PATCH /account/username → { message, profilo: { username, ... } }
  /// Restituisce il nuovo username confermato dal server.
  Future<String> patchUsername(String username) async {
    final data = await _client.patchJson(
      '/account/username',
      body: {'username': username},
    );
    if (data is Map<String, dynamic>) {
      final profilo = data['profilo'];
      if (profilo is Map<String, dynamic>) {
        return profilo['username']?.toString() ?? username;
      }
    }
    return username;
  }

  /// PATCH /account/email → { message, newEmail }
  /// Il server aggiorna l'email (non verificata) e invia una mail di verifica.
  /// Restituisce la nuova email confermata dal server.
  Future<String> patchEmail(String email) async {
    final data = await _client.patchJson(
      '/account/email',
      body: {'email': email},
    );
    if (data is Map<String, dynamic>) {
      return data['newEmail']?.toString() ?? email;
    }
    return email;
  }

  /// PATCH /account/password → { message }
  /// Richiede la vecchia password per autorizzare il cambio.
  Future<void> patchPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _client.patchJson(
      '/account/password',
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }

  /// DELETE /account → { message }
  /// Rimuove l'utente da tutte le case, elegge admin se necessario,
  /// elimina case vuote e anonimizza i dati.
  Future<void> deleteAccount() async {
    await _client.deleteJson('/account');
  }
}
