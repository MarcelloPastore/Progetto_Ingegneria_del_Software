import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_provider.dart';
import '../utils/jwt_utils.dart';

class SessionManager {
  SessionManager._();

  static const _keyToken = 'auth_token';
  static const _keyExpiry = 'auth_token_expiry';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserUsername = 'user_username';
  static const _keyUserNome = 'user_nome';
  static const _keyUserCognome = 'user_cognome';
  static const _keyCasaId = 'active_casa_id';
  static const _keyCasaRuolo = 'active_casa_ruolo';

  static const Duration _sessionDuration = Duration(days: 14);

  /// Salva la sessione con scadenza 14 giorni.
  static Future<void> save({
    required String token,
    required String userId,
    required String email,
    required String username,
    required String nome,
    required String cognome,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now().add(_sessionDuration);
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyExpiry, expiry.toIso8601String());
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserUsername, username);
    await prefs.setString(_keyUserNome, nome);
    await prefs.setString(_keyUserCognome, cognome);
  }

  /// Ripristina la sessione nell'ApiClient se valida e non scaduta.
  /// Restituisce true se la sessione è stata ripristinata.
  static Future<bool> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final expiryStr = prefs.getString(_keyExpiry);

      if (token == null || token.isEmpty || expiryStr == null) {
        return false;
      }

      final expiry = DateTime.tryParse(expiryStr);
      if (expiry == null || DateTime.now().isAfter(expiry)) {
        await clear();
        return false;
      }

      ApiProvider.client.setAuthToken(token);
      ApiProvider.client.setCurrentUserIdentity(
        id: prefs.getString(_keyUserId),
        email: prefs.getString(_keyUserEmail),
        name: prefs.getString(_keyUserNome),
        surname: prefs.getString(_keyUserCognome),
        username: prefs.getString(_keyUserUsername),
      );
      final casaId = prefs.getString(_keyCasaId);
      final casaRuolo = prefs.getString(_keyCasaRuolo);
      if (casaId != null && casaRuolo != null) {
        ApiProvider.client.setCasaContext(casaId: casaId, ruolo: casaRuolo);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Chiama POST /case/:casaId/select, aggiorna il token e il contesto casa.
  /// Il ruoloCasa viene estratto direttamente dal JWT restituito dal server.
  static Future<String> selectCasa({required String casaId}) async {
    final token = await ApiProvider.casa.selectCasa(casaId);
    final ruolo = JwtUtils.extractRuoloCasa(token) ?? '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyCasaId, casaId);
    await prefs.setString(_keyCasaRuolo, ruolo);
    ApiProvider.client.setAuthToken(token);
    ApiProvider.client.setCasaContext(casaId: casaId, ruolo: ruolo);
    return ruolo;
  }

  /// Aggiorna lo username in sessione dopo una modifica account riuscita.
  static Future<void> updateUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserUsername, username);
    ApiProvider.client.setCurrentUserIdentity(username: username);
  }

  /// Cancella la sessione (logout).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyExpiry);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserUsername);
    await prefs.remove(_keyUserNome);
    await prefs.remove(_keyUserCognome);
    await prefs.remove(_keyCasaId);
    await prefs.remove(_keyCasaRuolo);
    ApiProvider.client.clearSession();
  }
}
