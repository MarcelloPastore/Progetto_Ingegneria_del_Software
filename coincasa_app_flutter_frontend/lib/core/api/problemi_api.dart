import '../models/problema.dart';
import 'api_client.dart';

class ProblemiApi {
  ProblemiApi(this._client);

  final ApiClient _client;

  Future<List<Problema>> list(String casaId) async {
    final data = await _client.getJson('/case/$casaId/problemi');
    return _parseList(data);
  }

  Future<List<Problema>> listNonRisolti(String casaId) async {
    final data = await _client.getJson('/case/$casaId/problemi/non-risolti');
    return _parseList(data);
  }

  Future<Problema> create(String casaId, Map<String, dynamic> payload) async {
    final data = await _client.postJson('/case/$casaId/problemi', body: payload);
    return Problema.fromJson(_asMap(data));
  }

  Future<void> delete(String casaId, String problemaId) async {
    await _client.deleteJson('/case/$casaId/problemi/$problemaId');
  }

  Future<void> assegna(String casaId, String problemaId) async {
    await _client.putJson('/case/$casaId/problemi/$problemaId/assegna');
  }

  Future<void> aggiornaStato(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) async {
    await _client.patchJson(
      '/case/$casaId/problemi/$problemaId/stato',
      body: payload,
    );
  }

  Future<void> aggiornaPriorita(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) async {
    await _client.patchJson(
      '/case/$casaId/problemi/$problemaId/priorita',
      body: payload,
    );
  }

  List<Problema> _parseList(dynamic data) {
    final list = _asList(data);
    return list.map(Problema.fromJson).toList();
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic>) {
      final candidate = data['items'] ?? data['results'] ?? data['problemi'];
      if (candidate is List) {
        return candidate.cast<Map<String, dynamic>>();
      }
    }
    throw const FormatException('Expected a list response.');
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const FormatException('Expected an object response.');
  }
}
