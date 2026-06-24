import 'dart:convert';

class JwtUtils {
  JwtUtils._();

  /// Decodifica il payload di un JWT (base64url) e lo ritorna come mappa.
  /// Non verifica la firma — usato solo per leggere claim già validati dal server.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Restituisce il ruolo della casa dal token JWT, o null se assente.
  static String? extractRuoloCasa(String token) {
    final payload = decodePayload(token);
    final value = payload?['ruoloCasa'];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Restituisce l'idCasa dal token JWT, o null se assente.
  static String? extractIdCasa(String token) {
    final payload = decodePayload(token);
    final value = payload?['idCasa'];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Restituisce l'ID utente dal token JWT, controllando i claim più comuni.
  static String? extractUserId(String token) {
    final payload = decodePayload(token);
    if (payload == null) return null;
    for (final key in ['idUtente', 'userId', 'sub', 'id']) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
}
